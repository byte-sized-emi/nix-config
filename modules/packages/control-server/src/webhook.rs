use axum::body::Bytes;
use axum::extract::State;
use axum::http::{HeaderMap, StatusCode};
use hmac::{Hmac, KeyInit, Mac};
use sha2::Sha256;

use crate::AppState;
use crate::ingest;

/// Compare two byte slices in constant time, avoiding a timing oracle on the
/// webhook signature.
fn ct_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut diff = 0u8;
    for (x, y) in a.iter().zip(b.iter()) {
        diff |= x ^ y;
    }
    diff == 0
}

pub async fn handle(
    State(state): State<AppState>,
    headers: HeaderMap,
    body: Bytes,
) -> Result<StatusCode, StatusCode> {
    let signature = headers
        .get("X-Forgejo-Signature")
        .or_else(|| headers.get("X-Hub-Signature-256"))
        .and_then(|value| value.to_str().ok())
        .map(|s| s.strip_prefix("sha256=").unwrap_or(s))
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let mut mac = Hmac::<Sha256>::new_from_slice(state.cfg.webhook_secret.as_bytes())
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    mac.update(&body);
    let computed = mac.finalize().into_bytes();

    let provided = hex::decode(signature).map_err(|_| StatusCode::UNAUTHORIZED)?;
    if !ct_eq(&computed, &provided) {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let value: serde_json::Value =
        serde_json::from_slice(&body).map_err(|_| StatusCode::BAD_REQUEST)?;

    let expected_ref = format!("refs/heads/{}", state.cfg.branch);
    if value.get("ref").and_then(|r| r.as_str()) != Some(expected_ref.as_str()) {
        return Ok(StatusCode::OK);
    }

    let sha = value
        .get("after")
        .and_then(|a| a.as_str())
        .unwrap_or_default()
        .to_string();
    if sha.is_empty() || sha.chars().all(|c| c == '0') {
        return Ok(StatusCode::OK);
    }

    if !state.sha_guard.try_acquire(&sha).await {
        return Ok(StatusCode::OK);
    }

    let state = state.clone();
    let sha2 = sha.clone();
    tokio::spawn(async move {
        let result = ingest::ingest_sha(&state, &sha2, None).await;
        state.sha_guard.release(&sha2).await;
        if let Err(e) = result {
            eprintln!("webhook ingest failed for {sha2}: {e}");
        }
    });
    Ok(StatusCode::ACCEPTED)
}
