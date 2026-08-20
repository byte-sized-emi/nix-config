use axum::Json;
use axum::extract::{Path, Request, State};
use axum::http::StatusCode;
use futures::StreamExt;

use crate::notify;
use crate::{ApiError, AppState};

#[derive(serde::Deserialize)]
pub struct PollRequest {
    pub actual_derivation: Option<String>,
    pub actual_commit: Option<String>,
}

#[derive(serde::Serialize)]
pub struct PollResponse {
    pub desired: Option<DesiredState>,
}

#[derive(serde::Serialize)]
pub struct DesiredState {
    pub commit: String,
    pub derivation: String,
}

#[derive(serde::Deserialize)]
pub struct ClaimRequest {
    pub commit: String,
}

#[derive(serde::Deserialize)]
pub struct DesiredRequest {
    pub commit: String,
}

#[derive(serde::Deserialize)]
pub struct LogRequest {
    pub lines: Vec<String>,
}

#[derive(serde::Deserialize)]
pub struct FinishRequest {
    pub status: String,
    #[serde(default)]
    pub error: Option<String>,
}

pub async fn poll(
    State(state): State<AppState>,
    Path(name): Path<String>,
    Json(req): Json<PollRequest>,
) -> Result<Json<PollResponse>, ApiError> {
    state
        .db
        .update_host_seen(
            &name,
            req.actual_derivation.as_deref(),
            req.actual_commit.as_deref(),
        )
        .await
        .map_err(ApiError::internal)?;

    let desired = state
        .db
        .current_desired(&name)
        .await
        .map_err(ApiError::internal)?
        .map(|(commit, derivation)| DesiredState { commit, derivation });

    Ok(Json(PollResponse { desired }))
}

pub async fn claim(
    State(state): State<AppState>,
    Path(name): Path<String>,
    Json(req): Json<ClaimRequest>,
) -> Result<Json<crate::db::ClaimedDeployment>, ApiError> {
    let build = state
        .db
        .build_by_commit(&req.commit)
        .await
        .map_err(ApiError::internal)?
        .ok_or_else(|| ApiError::bad_request(format!("unknown commit {}", req.commit)))?;
    state
        .db
        .desire_derivation(build.id, &name)
        .await
        .map_err(ApiError::internal)?
        .ok_or_else(|| {
            ApiError::bad_request(format!("no known build of {name} at commit {}", req.commit))
        })?;

    let deployment = state
        .db
        .claim_deployment(&name, build.id)
        .await
        .map_err(ApiError::internal)?
        .ok_or_else(|| ApiError::bad_request(format!("host {name} unknown")))?
        .claimed()
        .ok_or_else(|| {
            ApiError::conflict(format!(
                "host {name} already has an active deployment for another build"
            ))
        })?;

    if let Err(e) = notify::push_host_status(
        &state,
        deployment.build_id,
        &name,
        "pending",
        Some(deployment.id),
        "deployment started",
    )
    .await
    {
        eprintln!("forgejo status push failed: {e}");
    }
    Ok(Json(deployment))
}

pub async fn set_desired(
    State(state): State<AppState>,
    Path(name): Path<String>,
    Json(req): Json<DesiredRequest>,
) -> Result<Json<DesiredState>, ApiError> {
    let applied = state
        .db
        .set_desired_override(&name, &req.commit)
        .await
        .map_err(ApiError::internal)?;
    if !applied {
        return Err(ApiError::bad_request(format!(
            "no known build of {name} at commit {}",
            req.commit
        )));
    }
    let (commit, derivation) = state
        .db
        .current_desired(&name)
        .await
        .map_err(ApiError::internal)?
        .ok_or_else(|| ApiError::not_found("desired state"))?;
    Ok(Json(DesiredState { commit, derivation }))
}

pub async fn clear_desired(
    State(state): State<AppState>,
    Path(name): Path<String>,
) -> Result<StatusCode, ApiError> {
    state
        .db
        .clear_desired_override(&name)
        .await
        .map_err(ApiError::internal)?;
    Ok(StatusCode::OK)
}

pub async fn log(
    State(state): State<AppState>,
    Path(id): Path<i64>,
    Json(req): Json<LogRequest>,
) -> Result<StatusCode, ApiError> {
    let _dep = state
        .db
        .deployment_by_id(id)
        .await
        .map_err(ApiError::internal)?
        .ok_or_else(|| ApiError::not_found("deployment"))?;
    let lines: Vec<String> = req
        .lines
        .into_iter()
        .filter(|line| !line.trim().is_empty())
        .collect();
    if lines.is_empty() {
        return Ok(StatusCode::OK);
    }
    let entries = state
        .db
        .append_logs(id, &lines)
        .await
        .map_err(ApiError::internal)?;
    let channel = state.channel(id).await;
    for entry in entries {
        let _ = channel.send((entry.id, entry.ts, entry.line));
    }
    Ok(StatusCode::OK)
}

pub async fn stream_log(
    State(state): State<AppState>,
    Path(id): Path<i64>,
    req: Request,
) -> Result<StatusCode, ApiError> {
    state
        .db
        .deployment_by_id(id)
        .await
        .map_err(ApiError::internal)?
        .ok_or_else(|| ApiError::not_found("deployment"))?;

    let mut stream = req.into_body().into_data_stream();
    let mut buffer: Vec<u8> = Vec::new();
    while let Some(chunk) = stream.next().await {
        let bytes = chunk.map_err(|_| ApiError::internal("error reading log stream"))?;
        buffer.extend_from_slice(&bytes);
        let mut lines = Vec::new();
        let mut start = 0;
        while let Some(offset) = buffer[start..].iter().position(|&b| b == b'\n') {
            let end = start + offset;
            lines.push(
                String::from_utf8_lossy(&buffer[start..end])
                    .trim_end_matches('\r')
                    .to_string(),
            );
            start = end + 1;
        }
        buffer.drain(..start);
        let lines: Vec<String> = lines
            .into_iter()
            .filter(|line| !line.trim().is_empty())
            .collect();
        if !lines.is_empty() {
            let entries = state
                .db
                .append_logs(id, &lines)
                .await
                .map_err(ApiError::internal)?;
            let channel = state.channel(id).await;
            for entry in entries {
                let _ = channel.send((entry.id, entry.ts, entry.line));
            }
        }
    }

    let tail = String::from_utf8_lossy(&buffer)
        .trim_end_matches('\r')
        .trim()
        .to_string();
    if !tail.is_empty() {
        let entries = state
            .db
            .append_logs(id, &[tail])
            .await
            .map_err(ApiError::internal)?;
        let channel = state.channel(id).await;
        for entry in entries {
            let _ = channel.send((entry.id, entry.ts, entry.line));
        }
    }

    Ok(StatusCode::OK)
}

pub async fn finish(
    State(state): State<AppState>,
    Path(id): Path<i64>,
    Json(req): Json<FinishRequest>,
) -> Result<StatusCode, ApiError> {
    let dep = state
        .db
        .deployment_by_id(id)
        .await
        .map_err(ApiError::internal)?
        .ok_or_else(|| ApiError::not_found("deployment"))?;
    if dep.status != "deploying" {
        return Err(ApiError::bad_request("deployment is not in progress"));
    }
    let status = match req.status.as_str() {
        "succeeded" => "succeeded",
        "failed" => "failed",
        _ => {
            return Err(ApiError::bad_request(
                "status must be 'succeeded' or 'failed'",
            ));
        }
    };
    state
        .db
        .finish_deployment(id, status, req.error.as_deref())
        .await
        .map_err(ApiError::internal)?;
    state
        .db
        .set_host_status(&dep.host, "idle")
        .await
        .map_err(ApiError::internal)?;
    let build = state
        .db
        .build_by_id(dep.build_id)
        .await
        .map_err(ApiError::internal)?;
    if status == "succeeded"
        && let Some(deriv) = state
            .db
            .desire_derivation(dep.build_id, &dep.host)
            .await
            .map_err(ApiError::internal)?
    {
        state
            .db
            .set_host_actual(
                &dep.host,
                &deriv,
                build.as_ref().map(|b| b.commit.as_str()).unwrap_or(""),
            )
            .await
            .map_err(ApiError::internal)?;
    }
    let (state_str, description) = if status == "succeeded" {
        ("success", format!("deployed to {}", dep.host))
    } else {
        (
            "failure",
            req.error
                .as_deref()
                .unwrap_or("deployment failed")
                .to_string(),
        )
    };
    if let Err(e) = notify::push_host_status(
        &state,
        dep.build_id,
        &dep.host,
        state_str,
        Some(id),
        &description,
    )
    .await
    {
        eprintln!("forgejo status push failed for deployment {id}: {e}");
    }
    state.remove_channel(id).await;
    Ok(StatusCode::OK)
}
