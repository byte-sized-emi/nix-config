use axum::body::Body;
use axum::{Router, extract::Query, response::IntoResponse};
use serde::Deserialize;

use futures::stream;
use std::convert::Infallible;
use tokio::io::{AsyncBufReadExt as _, AsyncWriteExt};
use tokio::net::unix::pipe::{Sender, pipe};
use tokio::sync::mpsc;
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

    let (channel_tx, channel_rx) = mpsc::channel::<String>(100);

    let _commands_task = tokio::spawn(async move {
        let _ = update_commands(tx, channel_tx, &branch).await;
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
                println!("{line}");
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
) -> Result<(), ()> {
    let stdout = stdout_sender.into_blocking_fd().unwrap();

    let run_command = async |command: &str, args: &[&str]| {
        let msg = format!("Executing `{command}` with args {args:?}");
        tx.send(msg).await.unwrap();
        let status = Command::new(command)
            .args(args)
            .current_dir("/home/emilia/nix-config")
            .stdout(stdout.try_clone().unwrap())
            .stderr(stdout.try_clone().unwrap())
            .status()
            .await
            .unwrap();

        if !status.success() {
            let msg =
                format!("Command `{command}` with args {args:?} failed with status: {status}");
            let _ = tx.send(msg).await;
            Err(())
        } else {
            let msg = format!(
                "Command `{command}` with args {args:?} succeeded with status {:?}",
                status.code()
            );
            tx.send(msg).await.unwrap();
            Ok(())
        }
    };

    // match update_repository(branch) {
    //     Err(err) => {
    //         let msg =
    //             format!("Something went wrong while switching to branch '{branch}':\n{err}\n");
    //         tx.send(msg).await.unwrap();
    //         return;
    //     }
    //     Ok(head_name) => {
    //         let msg = format!("HEAD now pointing to '{head_name}'\n");
    //         tx.send(msg).await.unwrap();
    //     }
    // }

    run_command("git", &["checkout", branch]).await?;

    run_command("git", &["pull", "origin", branch]).await?;

    let msg = format!("Successfully pulled the '{branch}' branch\n");
    tx.send(msg).await.unwrap();

    run_command("nixos-rebuild", &["switch", "--sudo", "-L"]).await?;

    println!("Done with all commands!");
    Ok(())
}

// fn update_repository(branch_name: &str) -> Result<String, git2::Error> {
//     let repo = git2::Repository::open("/home/emilia/nix-config")?;

//     let mut remote = repo.find_remote("origin")?;
//     remote.fetch(&[branch_name], None, None)?;

//     let branch = repo
//         .find_branch(branch_name, git2::BranchType::Remote)
//         .unwrap();

//     // branch.

//     let (object, reference) = repo.revparse_ext(branch_name)?;

//     repo.set_head(reference.unwrap().name().unwrap())?;
//     repo.checkout_tree(&object, None).unwrap();
//     let head = repo.head().unwrap();
//     let head_name = head.name().unwrap();

//     Ok(head_name.to_string())
// }
