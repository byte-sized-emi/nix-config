use askama::Template;
use axum::extract::{Path, State};
use axum::http::{header, StatusCode};
use axum::response::{Html, IntoResponse};

use crate::db::{Build, DashboardHost, Host, HostDeployment};
use crate::AppState;

struct HostRow {
  name: String,
  status: String,
  status_class: String,
  last_seen: String,
  actual_derivation: String,
  actual_commit: String,
  desired_derivation: String,
  desired_commit: String,
  desired_forgejo_status: String,
  desired_forgejo_status_class: String,
}

struct BuildRow {
  commit: String,
  message: String,
  observed: String,
}

struct DeployRow {
  id: i64,
  commit: String,
  status: String,
  status_class: String,
  started: String,
  finished: String,
  error: String,
  derivation: String,
}

struct LogRow {
  ts: String,
  line: String,
}

#[derive(Template)]
#[template(path = "dashboard.html")]
struct DashboardTemplate {
  hosts: Vec<HostRow>,
  builds: Vec<BuildRow>,
}

#[derive(Template)]
#[template(path = "hosts_rows.html")]
struct HostsRowsTemplate {
  hosts: Vec<HostRow>,
}

#[derive(Template)]
#[template(path = "host.html")]
struct HostTemplate {
  name: String,
  host: HostRow,
  deployments: Vec<DeployRow>,
}

#[derive(Template)]
#[template(path = "deployment.html")]
struct DeploymentTemplate {
  deployment_id: i64,
  host_name: String,
  commit: String,
  commit_short: String,
  message: String,
  status: String,
  status_class: String,
  started: String,
  finished: String,
  error: String,
  derivation: String,
  logs: Vec<LogRow>,
  last_id: i64,
  sse_active: bool,
}

fn short(s: &str, len: usize) -> String {
  if s.len() <= len {
    s.to_string()
  } else {
    s[..len].to_string()
  }
}

fn short_commit(c: &str) -> String {
  short(c, 8)
}

fn short_derivation(d: &str) -> String {
  short(d, 48)
}

fn status_class(s: &str) -> String {
  match s {
    "idle" | "success" | "succeeded" => "badge-green".to_string(),
    "deploying" => "badge-blue".to_string(),
    "pending" => "badge-yellow".to_string(),
    "failed" => "badge-red".to_string(),
    _ => "badge-gray".to_string(),
  }
}

fn status_label(s: &str) -> String {
  s.to_string()
}

fn opt(v: &Option<String>) -> String {
  v.as_deref().unwrap_or("-").to_string()
}

fn to_host_row(h: &DashboardHost) -> HostRow {
  HostRow {
    name: h.name.clone(),
    status: status_label(&h.status),
    status_class: status_class(&h.status),
    last_seen: opt(&h.last_seen_at),
    actual_derivation: short_derivation(&opt(&h.actual_derivation)),
    actual_commit: short_commit(&opt(&h.actual_commit)),
    desired_derivation: short_derivation(&opt(&h.desired_derivation)),
    desired_commit: short_commit(&opt(&h.desired_commit)),
    desired_forgejo_status: opt(&h.desired_forgejo_status),
    desired_forgejo_status_class: match &h.desired_forgejo_status {
      Some(s) => status_class(s),
      None => "-".to_string(),
    },
  }
}

fn to_host_row_from_host(h: &Host) -> HostRow {
  HostRow {
    name: h.name.clone(),
    status: status_label(&h.status),
    status_class: status_class(&h.status),
    last_seen: opt(&h.last_seen_at),
    actual_derivation: opt(&h.actual_derivation),
    actual_commit: opt(&h.actual_commit),
    desired_derivation: "-".to_string(),
    desired_commit: "-".to_string(),
    desired_forgejo_status: "-".to_string(),
    desired_forgejo_status_class: "-".to_string(),
  }
}

pub async fn dashboard(State(state): State<AppState>) -> Result<Html<String>, StatusCode> {
  let hosts = state.db.dashboard_hosts().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  let builds = state.db.latest_builds(10).await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  let hosts = hosts.iter().map(to_host_row).collect::<Vec<_>>();
  let builds = builds
    .iter()
    .map(|b: &Build| BuildRow {
      commit: short_commit(&b.commit),
      message: opt(&b.message),
      observed: b.observed_at.clone(),
    })
    .collect::<Vec<_>>();
  let tmpl = DashboardTemplate { hosts, builds };
  let html = tmpl.render().map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  Ok(Html(html))
}

pub async fn hosts_partial(State(state): State<AppState>) -> Result<Html<String>, StatusCode> {
  let hosts = state.db.dashboard_hosts().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  let hosts = hosts.iter().map(to_host_row).collect::<Vec<_>>();
  let tmpl = HostsRowsTemplate { hosts };
  let html = tmpl.render().map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  Ok(Html(html))
}

pub async fn host_page(
  State(state): State<AppState>,
  Path(name): Path<String>,
) -> Result<Html<String>, StatusCode> {
  let host = state
    .db
    .host_by_name(&name)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;
  let deployments = state.db.host_deployments(&name).await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  let deployments = deployments
    .iter()
    .map(|d: &HostDeployment| DeployRow {
      id: d.id,
      commit: short_commit(&d.commit),
      status: status_label(&d.status),
      status_class: status_class(&d.status),
      started: opt(&d.started_at),
      finished: opt(&d.finished_at),
      error: opt(&d.error),
      derivation: d.derivation.clone(),
    })
    .collect::<Vec<_>>();
  let tmpl = HostTemplate {
    name: name.clone(),
    host: to_host_row_from_host(&host),
    deployments,
  };
  let html = tmpl.render().map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  Ok(Html(html))
}

pub async fn deployment_page(
  State(state): State<AppState>,
  Path(id): Path<i64>,
) -> Result<Html<String>, StatusCode> {
  let dep = state
    .db
    .deployment_by_id(id)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;
  let build = state
    .db
    .build_by_id(dep.build_id)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;
  let logs = state.db.recent_logs(id, 500).await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  let sse_active = dep.status == "pending" || dep.status == "deploying";
  let last_id = logs.last().map(|l| l.id).unwrap_or(0);
  let message = build.message.as_deref().unwrap_or("-").to_string();
  let status = status_label(&dep.status);
  let status_class = status_class(&dep.status);
  let started = opt(&dep.started_at);
  let finished = opt(&dep.finished_at);
  let error = opt(&dep.error);
  let derivation = state
    .db
    .desire_derivation(dep.build_id, &dep.host)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .unwrap_or_else(|| "-".to_string());
  let logs = logs
    .into_iter()
    .map(|l| LogRow { ts: l.ts, line: l.line })
    .collect::<Vec<_>>();
  let tmpl = DeploymentTemplate {
    deployment_id: id,
    host_name: dep.host,
    commit: build.commit.clone(),
    commit_short: short_commit(&build.commit),
    message,
    status,
    status_class,
    started,
    finished,
    error,
    derivation,
    logs,
    last_id,
    sse_active,
  };
  let html = tmpl.render().map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  Ok(Html(html))
}

pub async fn deployment_log(
  State(state): State<AppState>,
  Path(id): Path<i64>,
) -> Result<impl IntoResponse, StatusCode> {
  let logs = state.db.recent_logs(id, 100_000).await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  let body = logs
    .into_iter()
    .map(|l| l.line)
    .collect::<Vec<_>>()
    .join("\n");
  Ok(([(header::CONTENT_TYPE, "text/plain; charset=utf-8")], body))
}

pub async fn style_css() -> impl IntoResponse {
  (
    [(header::CONTENT_TYPE, "text/css; charset=utf-8")],
    include_str!("static/style.css"),
  )
}

pub async fn htmx_js() -> impl IntoResponse {
  (
    [(header::CONTENT_TYPE, "text/javascript; charset=utf-8")],
    include_str!("static/htmx.min.js"),
  )
}

pub async fn sse_js() -> impl IntoResponse {
  (
    [(header::CONTENT_TYPE, "text/javascript; charset=utf-8")],
    include_str!("static/sse.js"),
  )
}