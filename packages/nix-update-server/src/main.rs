use axum::body::Body;
use axum::{Router, extract::Query, response::IntoResponse};
use serde::Deserialize;

use tokio::io::AsyncBufReadExt as _;
use tokio::{io::BufReader, process::Command};
use tokio::net::unix::pipe::pipe;
use tokio_listener::{Listener, ListenerAddress};
use futures::stream;
use std::convert::Infallible;

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

    let app = Router::new().route("/update", axum::routing::post(update_server_request));

    axum::serve(listener, app.into_make_service())
        .await
        .unwrap();
}

#[derive(Deserialize)]
struct DeployParams {
    branch: Option<String>,
}

async fn update_server_request(Query(params): Query<DeployParams>) -> impl IntoResponse {
    let branch = params.branch.unwrap_or("main".to_string());
    println!("Starting update");
    let (tx, rx) = pipe().unwrap();
    println!("Got pipe");

    let _commands_task = tokio::spawn(async move {
        let stdout = tx.into_blocking_fd().unwrap();

        let run_command = async |command: &str, args: &[&str]| {
            println!("Executing {command} with args {args:?}");
            Command::new(command)
                .args(args)
                .current_dir("/home/emilia/nix-config")
                .stdout(stdout.try_clone().unwrap())
                .stderr(stdout.try_clone().unwrap())
                .status()
                .await
                .unwrap();
        };

        run_command("git", &["switch", &branch]).await;

        run_command("git", &["pull", "origin", &branch]).await;

        run_command("sudo", &["nixos-rebuild", "switch"]).await;

        println!("Done with all commands!");
    });

    // Create a stream of lines from the BufReader
    let buf_reader = BufReader::new(rx);
    let lines = buf_reader.lines();
    let stream = stream::unfold(lines, |mut reader| async {
        match reader.next_line().await {
            Ok(Some(line)) => {
                let line = format!("{line}\n");
                Some((Ok::<_, Infallible>(line), reader))
            },
            _ => None,
        }
    });

    Body::from_stream(stream)
}
