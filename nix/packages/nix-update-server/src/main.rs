use axum::body::Body;
use axum::extract::State;
use axum::{Router, extract::Query, response::IntoResponse};
use serde::Deserialize;

use futures::stream;
use std::convert::Infallible;
use tokio::io::AsyncBufReadExt as _;
use tokio::net::unix::pipe::{Sender, pipe};
use tokio::signal;
use tokio::sync::{mpsc, watch};
use tokio::{io::BufReader, process::Command};
use tokio_listener::{Listener, ListenerAddress};

#[tokio::main]
async fn main() {
    let systemd_socket_addr: ListenerAddress = "sd-listen".parse().unwrap();
    let localhost_socket_addr: ListenerAddress = "127.0.0.1:2999".parse().unwrap();

    let listener = match Listener::bind(
        &systemd_socket_addr,
        &Default::default(),
        &Default::default(),
    )
    .await
    {
        Ok(l) => {
            println!("Using systemd socket");
            l
        }
        Err(_) => {
            println!("Falling back to localhost:2999");
            Listener::bind(
                &localhost_socket_addr,
                &Default::default(),
                &Default::default(),
            )
            .await
            .unwrap()
        }
    };

    let (shutdown_tx, mut shutdown_rx) = watch::channel::<bool>(false);

    let shutdown_signal = async move {
        let internal_shutdown_loop = async {
            // wait for shutdown command
            let _ = shutdown_rx.wait_for(|s| *s).await;
        };

        let ctrl_c = async {
            signal::ctrl_c()
                .await
                .expect("failed to install Ctrl+C handler");
        };

        #[cfg(unix)]
        let terminate = async {
            signal::unix::signal(signal::unix::SignalKind::terminate())
                .expect("failed to install signal handler")
                .recv()
                .await;
        };

        #[cfg(not(unix))]
        let terminate = std::future::pending::<()>();

        tokio::select! {
            _ = ctrl_c => {},
            _ = terminate => {},
            _ = internal_shutdown_loop => {},
        }
    };

    let app = Router::new()
        .route("/update", axum::routing::post(update_server_request))
        .with_state(shutdown_tx);

    axum::serve(listener, app.into_make_service())
        .with_graceful_shutdown(shutdown_signal)
        .await
        .unwrap();
}

#[derive(Deserialize)]
struct DeployParams {
    branch: Option<String>,
}

async fn update_server_request(
    Query(params): Query<DeployParams>,
    State(shutdown_tx): State<watch::Sender<bool>>,
) -> impl IntoResponse {
    let branch = params.branch.unwrap_or("main".to_string());
    println!("Starting update");
    let (tx, rx) = pipe().unwrap();

    let (channel_tx, channel_rx) = mpsc::channel::<String>(100);

    let _commands_task = tokio::spawn(async move {
        let _ = update_commands(tx, channel_tx, &branch, shutdown_tx).await;
    });

    // Create a stream of lines from the BufReader
    let buf_reader = BufReader::new(rx);
    let lines = buf_reader.lines();
    let stream = stream::unfold(
        (lines, channel_rx),
        async move |(mut reader, mut channel_rx)| {
            let line = tokio::select! {
                line = reader.next_line() => {
                    match line {
                        Ok(Some(line)) => {
                            Some(line)
                        }
                        _ => None,
                    }
                }
                Some(msg) = channel_rx.recv() => {
                    Some(msg)
                }
            };

            if let Some(line) = &line {
                println!("command output: {line}");
                let line = format!("{line}\n");
                Some((Ok::<_, Infallible>(line), (reader, channel_rx)))
            } else {
                None
            }
        },
    );

    Body::from_stream(stream)
}

async fn update_commands(
    stdout_sender: Sender,
    tx: mpsc::Sender<String>,
    branch: &str,
    shutdown_tx: watch::Sender<bool>,
) -> Result<(), ()> {
    let stdout = stdout_sender.into_blocking_fd().unwrap();

    let run_command = async |command: &str, args: &[&str]| {
        let full_command = if args.is_empty() {
            command.to_string()
        } else {
            format!("{command} {}", args.join(" "))
        };
        let msg = format!("Executing `{full_command}`");
        let _ = tx.send(msg).await;
        let status = Command::new(command)
            .args(args)
            .current_dir("/home/emilia/nix-config")
            .stdout(stdout.try_clone().unwrap())
            .stderr(stdout.try_clone().unwrap())
            .status()
            .await
            .unwrap();

        if !status.success() {
            let msg = format!("Command `{full_command}` failed with status: {status}");
            let _ = tx.send(msg).await;
            Err(())
        } else {
            let msg = format!(
                "Command `{full_command}` succeeded with status {}",
                status
                    .code()
                    .map(|s| s.to_string())
                    .unwrap_or("(no status)".to_string())
            );
            let _ = tx.send(msg).await;
            Ok(())
        }
    };

    run_command("git", &["checkout", branch]).await?;

    run_command("git", &["pull", "origin", branch]).await?;

    let msg = format!("Successfully pulled the '{branch}' branch\n");
    let _ = tx.send(msg).await;

    run_command("nixos-rebuild", &["switch", "-L"]).await?;

    let _ = tx.send("Done with all commands!".to_string()).await;
    println!("Done with all commands!");
    let _ = shutdown_tx.send(true);

    Ok(())
}
