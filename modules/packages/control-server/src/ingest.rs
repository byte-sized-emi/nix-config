use std::collections::BTreeMap;

use serde::Deserialize;

use crate::AppState;
use crate::notify;

#[derive(Debug, Deserialize, PartialEq, Eq)]
struct BuildPaths {
    #[serde(rename = "nixosConfigurations")]
    configurations: BTreeMap<String, String>,
}

/// Parse the contents of .build-paths.json into a host -> derivation map.
pub fn parse_build_paths(json: &[u8]) -> Result<BTreeMap<String, String>, String> {
    let build_paths: BuildPaths =
        serde_json::from_slice(json).map_err(|e| format!("parsing build-paths json: {e}"))?;
    Ok(build_paths.configurations)
}

/// Poll the configured branch head and ingest the build if it changed.
pub async fn poll(state: &AppState) -> Result<Option<i64>, String> {
    let (sha, message) = state.forgejo.branch_head(&state.cfg.branch).await?;
    let last = state.db.last_observed_commit().await?;
    if last.as_deref() == Some(sha.as_str()) {
        return Ok(None);
    }
    if !state.sha_guard.try_acquire(&sha).await {
        return Ok(None);
    }
    let result = ingest_sha(state, &sha, message.as_deref()).await;
    state.sha_guard.release(&sha).await;
    result
}

/// Ingest a specific commit: fetch .build-paths.json at that SHA, store the
/// build and desires, and push per-host Forgejo statuses. Deployments are
/// created on demand by agents / manual override, not here.
pub async fn ingest_sha(
    state: &AppState,
    sha: &str,
    message: Option<&str>,
) -> Result<Option<i64>, String> {
    let raw = match state.forgejo.raw_file(&state.cfg.build_path, sha).await {
        Ok(bytes) => bytes,
        Err(e) => {
            // Commit does not carry .build-paths.json; remember it so we don't
            // refetch it on every poll.
            state.db.set_last_observed_commit(sha).await?;
            eprintln!("no build-paths at {sha}: {e}");
            return Ok(None);
        }
    };

    let desires = parse_build_paths(&raw)?;
    let ingested = state.db.ingest_build(sha, message, &desires).await?;
    if ingested.desires.is_empty() {
        return Ok(Some(ingested.build_id));
    }

    for plan in &ingested.desires {
        let (build_state, description) = if plan.needs_deploy {
            (
                "pending",
                format!("deploying {} to {}", plan.host, plan.derivation),
            )
        } else {
            (
                "success",
                format!("{} already at {}", plan.host, plan.derivation),
            )
        };
        if let Err(e) = notify::push_host_status(
            state,
            ingested.build_id,
            &plan.host,
            build_state,
            None,
            &description,
        )
        .await
        {
            eprintln!("forgejo status push failed: {e}");
        }
    }

    Ok(Some(ingested.build_id))
}

#[cfg(test)]
mod tests {
    use super::parse_build_paths;

    #[test]
    fn parses_build_paths() {
        let json = br#"{"nixosConfigurations": {"nixlaptop": "/nix/store/abc", "nixserver": "/nix/store/def"}}"#;
        let map = parse_build_paths(json).expect("should parse");
        assert_eq!(
            map.get("nixlaptop").map(String::as_str),
            Some("/nix/store/abc")
        );
        assert_eq!(
            map.get("nixserver").map(String::as_str),
            Some("/nix/store/def")
        );
    }

    #[test]
    fn rejects_missing_configurations() {
        let json = br#"{"other": 1}"#;
        assert!(parse_build_paths(json).is_err());
    }

    #[test]
    fn ignores_extra_top_level_fields() {
        let json = br#"{"meta": {"source": "ci"}, "nixosConfigurations": {"nixlaptop": "/nix/store/abc", "nixserver": "/nix/store/def"}, "extra": [1, 2, 3]}"#;
        let map = parse_build_paths(json).expect("should parse");
        assert_eq!(
            map.get("nixlaptop").map(String::as_str),
            Some("/nix/store/abc")
        );
        assert_eq!(
            map.get("nixserver").map(String::as_str),
            Some("/nix/store/def")
        );
    }
}
