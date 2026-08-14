use url::Url;

pub struct Forgejo {
    api: String,
    owner: String,
    repo: String,
    token: String,
    client: reqwest::Client,
}

impl Forgejo {
    pub fn new(api: &str, owner: &str, repo: &str, token: &str) -> Result<Forgejo, String> {
        let client = reqwest::Client::builder()
            .user_agent("nix-control-server")
            .build()
            .map_err(|e| format!("building http client: {e}"))?;
        Ok(Forgejo {
            api: api.trim_end_matches('/').to_string(),
            owner: owner.to_string(),
            repo: repo.to_string(),
            token: token.to_string(),
            client,
        })
    }

    fn url(&self, path: &[&str]) -> Result<Url, String> {
        let base = format!("{}/repos/{}/{}", self.api, self.owner, self.repo);
        let mut url = Url::parse(&base).map_err(|e| format!("parsing forgejo base url: {e}"))?;
        for segment in path {
            let mut segments = url
                .path_segments_mut()
                .map_err(|_| "building forgejo url".to_string())?;
            segments.push(segment);
        }
        Ok(url)
    }

    fn auth(&self) -> String {
        // Forgejo accepts `token <token>` in the Authorization header.
        format!("token {}", self.token)
    }

    /// SHA and subject message of the branch head.
    pub async fn branch_head(&self, branch: &str) -> Result<(String, Option<String>), String> {
        let mut url = self.url(&["commits"]).map_err(|e| format!("branch head: {e}"))?;
        url.query_pairs_mut().append_pair("sha", branch).append_pair("limit", "1");
        let response = self
            .client
            .get(url)
            .header(reqwest::header::AUTHORIZATION, self.auth())
            .send()
            .await
            .map_err(|e| format!("fetching branch head: {e}"))?;
        if !response.status().is_success() {
            return Err(format!(
                "fetching branch head: {} {}",
                response.status(),
                response.text().await.unwrap_or_default()
            ));
        }
        let value: serde_json::Value = response
            .json()
            .await
            .map_err(|e| format!("parsing branch head response: {e}"))?;
        let commit = value
            .as_array()
            .and_then(|arr| arr.first())
            .ok_or_else(|| "branch head returned no commits".to_string())?;
        let sha = commit
            .get("sha")
            .and_then(|s| s.as_str())
            .ok_or_else(|| "branch head missing sha".to_string())?
            .to_string();
        let message = commit
            .pointer("/commit/message")
            .and_then(|m| m.as_str())
            .map(|m| m.lines().next().unwrap_or("").to_string());
        Ok((sha, message))
    }

    /// Raw file contents at a given ref (branch or SHA).
    pub async fn raw_file(&self, path: &str, sha: &str) -> Result<Vec<u8>, String> {
        let segments: Vec<&str> = path.split('/').filter(|s| !s.is_empty()).collect();
        let mut url = self.url(&segments).map_err(|e| format!("raw file: {e}"))?;
        url.query_pairs_mut().append_pair("ref", sha);
        let response = self
            .client
            .get(url)
            .header(reqwest::header::AUTHORIZATION, self.auth())
            .send()
            .await
            .map_err(|e| format!("fetching raw file {path}: {e}"))?;
        if !response.status().is_success() {
            return Err(format!("fetching raw file {path}: {}", response.status()));
        }
        let bytes = response.bytes().await.map_err(|e| format!("reading raw file {path}: {e}"))?;
        Ok(bytes.to_vec())
    }

    /// Set a commit status under a given context.
    pub async fn set_commit_status(
        &self,
        sha: &str,
        context: &str,
        state: &str,
        description: &str,
        target_url: Option<&str>,
    ) -> Result<(), String> {
        let url = self.url(&["statuses", sha]).map_err(|e| format!("commit status: {e}"))?;
        let body = serde_json::json!({
            "state": state,
            "context": context,
            "description": description,
            "target_url": target_url,
        });
        let response = self
            .client
            .post(url)
            .header(reqwest::header::AUTHORIZATION, self.auth())
            .json(&body)
            .send()
            .await
            .map_err(|e| format!("setting commit status: {e}"))?;
        if !response.status().is_success() {
            return Err(format!(
                "setting commit status for {context}: {} {}",
                response.status(),
                response.text().await.unwrap_or_default()
            ));
        }
        Ok(())
    }
}
