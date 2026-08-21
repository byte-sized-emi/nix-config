mod agent;
mod config;
mod db;
mod forgejo;
mod ingest;
mod notify;
mod sse;
mod ui;
mod webhook;

use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};

use axum::Router;
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::routing::{delete, get, post};
use clap::Parser;
use tokio::sync::{Mutex, broadcast};

use crate::config::Config;
use crate::db::Db;
use crate::forgejo::Forgejo;

type LogEvent = (i64, String, String);
type LogSender = broadcast::Sender<LogEvent>;

/// In-flight ingestion guard: ensures the same commit SHA isn't processed
/// concurrently (poll + webhook race). Entries older than `STALE` are dropped,
/// so a crashed task can't block a SHA forever.
#[derive(Clone, Default)]
pub struct ShaGuard {
    inner: Arc<Mutex<HashMap<String, Instant>>>,
}

impl ShaGuard {
    const STALE: Duration = Duration::from_secs(120);

    pub async fn try_acquire(&self, sha: &str) -> bool {
        let mut map = self.inner.lock().await;
        let now = Instant::now();
        map.retain(|_, seen| now.duration_since(*seen) < Self::STALE);
        if map.contains_key(sha) {
            false
        } else {
            map.insert(sha.to_string(), now);
            true
        }
    }

    pub async fn release(&self, sha: &str) {
        self.inner.lock().await.remove(sha);
    }
}

/// Shared application state, cloned into every handler.
#[derive(Clone)]
pub struct AppState {
    pub cfg: Arc<Config>,
    pub db: Arc<Db>,
    pub forgejo: Arc<Forgejo>,
    pub sha_guard: ShaGuard,
    log_channels: Arc<Mutex<HashMap<i64, LogSender>>>,
}

impl AppState {
    /// Get (or create) the live log channel for a deployment.
    /// Payloads are `(log_id, timestamp, line)`.
    pub async fn channel(&self, deployment_id: i64) -> LogSender {
        let mut map = self.log_channels.lock().await;
        map.entry(deployment_id)
            .or_insert_with(|| broadcast::channel(1024).0)
            .clone()
    }

    /// Drop the live log channel for a finished deployment.
    pub async fn remove_channel(&self, deployment_id: i64) {
        self.log_channels.lock().await.remove(&deployment_id);
    }
}

/// Error type for the agent API endpoints.
pub enum ApiError {
    Status(StatusCode, String),
}

impl ApiError {
    pub fn internal(e: impl Into<String>) -> Self {
        ApiError::Status(StatusCode::INTERNAL_SERVER_ERROR, e.into())
    }

    pub fn not_found(what: impl AsRef<str>) -> Self {
        ApiError::Status(
            StatusCode::NOT_FOUND,
            format!("{} not found", what.as_ref()),
        )
    }

    pub fn bad_request(msg: impl Into<String>) -> Self {
        ApiError::Status(StatusCode::BAD_REQUEST, msg.into())
    }

    pub fn conflict(msg: impl Into<String>) -> Self {
        ApiError::Status(StatusCode::CONFLICT, msg.into())
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let ApiError::Status(code, msg) = self;
        (code, msg).into_response()
    }
}

fn api_routes() -> Router<AppState> {
    Router::new()
        .route("/hosts/{name}/poll", post(agent::poll))
        .route("/hosts/{name}/deployments", post(agent::claim))
        .route("/hosts/{name}/desired", post(agent::set_desired))
        .route("/hosts/{name}/desired", delete(agent::clear_desired))
        .route("/deployments/{id}/log", post(agent::log))
        .route("/deployments/{id}/log/stream", post(agent::stream_log))
        .route("/deployments/{id}/finish", post(agent::finish))
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cfg = Arc::new(Config::parse());

    let db = Db::open(&cfg.db)
        .await
        .map_err(|e| format!("opening database: {e}"))?;
    let forgejo = Arc::new(Forgejo::new(
        &cfg.forgejo_api,
        &cfg.forgejo_owner,
        &cfg.forgejo_repo,
        &cfg.forgejo_token,
    )?);

    let state = AppState {
        cfg: cfg.clone(),
        db,
        forgejo,
        sha_guard: ShaGuard::default(),
        log_channels: Arc::new(Mutex::new(HashMap::new())),
    };

    // Periodic branch polling: pick up new .build-paths.json commits even
    // without a webhook.
    {
        let state = state.clone();
        let interval = std::time::Duration::from_secs(cfg.poll_interval);
        tokio::spawn(async move {
            let mut ticker = tokio::time::interval(interval);
            loop {
                ticker.tick().await;
                if let Err(e) = ingest::poll(&state).await {
                    eprintln!("git poll error: {e}");
                }
            }
        });
    }

    let webhook_path = cfg.webhook_path.clone();

    let app = Router::new()
        .route("/", get(ui::dashboard))
        .route("/partials/hosts", get(ui::hosts_partial))
        .route("/hosts/{name}", get(ui::host_page))
        .route("/deployments/{id}", get(ui::deployment_page))
        .route("/deployments/{id}/log", get(ui::deployment_log))
        .route("/deployments/{id}/log/stream", get(sse::log_stream))
        .route("/static/style.css", get(ui::style_css))
        .route("/static/htmx.min.js", get(ui::htmx_js))
        .route("/static/sse.js", get(ui::sse_js))
        .nest("/api/v1", api_routes())
        .route(&webhook_path, post(webhook::handle))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind(&cfg.listen).await?;
    println!("control-server listening on http://{}", cfg.listen);
    axum::serve(listener, app).await?;
    Ok(())
}
