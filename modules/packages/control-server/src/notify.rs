use crate::AppState;

/// Push a per-host commit status to Forgejo and record it in the DB.
pub async fn push_host_status(
    state: &AppState,
    build_id: i64,
    host: &str,
    build_state: &str,
    deployment_id: Option<i64>,
    description: &str,
) -> Result<(), String> {
    let build = state
        .db
        .build_by_id(build_id)
        .await?
        .ok_or_else(|| format!("build {build_id} not found"))?;
    state
        .db
        .set_desire_forgejo_status(build_id, host, build_state)
        .await?;
    let context = format!("nix/deploy/{host}");
    let target_url = deployment_id.and_then(|id| {
        state
            .cfg
            .public_url
            .as_ref()
            .map(|url| format!("{}/deployments/{id}", url.trim_end_matches('/')))
    });
    state
        .forgejo
        .set_commit_status(&build.commit, &context, build_state, description, target_url.as_deref())
        .await
}
