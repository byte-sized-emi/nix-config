use std::path::PathBuf;

use clap::Parser;

#[derive(Parser, Debug, Clone)]
#[command(name = "nix-control-server", about = "NixOS deployment control plane")]
pub struct Config {
    /// Address to listen on for the web UI and agent API.
    #[arg(long, default_value = "127.0.0.1:8080")]
    pub listen: String,

    /// Path to the SQLite database file.
    #[arg(long, default_value = "/var/lib/nix-control-server/state.db")]
    pub db: PathBuf,

    /// Forgejo API base URL, e.g. https://git.example.org/api/v1
    #[arg(long)]
    pub forgejo_api: String,

    /// Forgejo repository owner (user or org).
    #[arg(long)]
    pub forgejo_owner: String,

    /// Forgejo repository name.
    #[arg(long)]
    pub forgejo_repo: String,

    /// Branch that CI pushes .build-paths.json to.
    #[arg(long, default_value = "main")]
    pub branch: String,

    /// Path of the build-paths JSON file inside the repository.
    #[arg(long, default_value = ".build-paths.json")]
    pub build_path: String,

    /// How often (seconds) to poll the branch head for new commits.
    #[arg(long, default_value_t = 30)]
    pub poll_interval: u64,

    /// HTTP path the Forgejo webhook is registered under.
    #[arg(long, default_value = "/webhook/forgejo")]
    pub webhook_path: String,

    /// Public base URL of this server, used as the commit-status target URL.
    #[arg(long)]
    pub public_url: Option<String>,

    /// Forgejo API token (read + write:statuses scopes).
    #[arg(long, env = "FORGEJO_TOKEN")]
    pub forgejo_token: String,

    /// Secret used to verify Forgejo webhook signatures (HMAC-SHA256).
    #[arg(long, env = "WEBHOOK_SECRET")]
    pub webhook_secret: String,
}
