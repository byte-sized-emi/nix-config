use std::collections::BTreeMap;
use std::path::Path;
use std::sync::Arc;

use chrono::Utc;
use rusqlite::{Connection, OptionalExtension, params};
use tokio::sync::Mutex;

const SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS meta (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS hosts (
  id                 INTEGER PRIMARY KEY,
  name               TEXT UNIQUE NOT NULL,
  last_seen_at       TEXT,
  actual_derivation  TEXT,
  actual_commit      TEXT,
  status             TEXT NOT NULL DEFAULT 'idle',
  desired_override   TEXT,
  created_at         TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS builds (
  id          INTEGER PRIMARY KEY,
  sha         TEXT UNIQUE NOT NULL,
  message     TEXT,
  observed_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS build_desires (
  build_id      INTEGER NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  host          TEXT NOT NULL REFERENCES hosts(name) ON DELETE CASCADE,
  derivation    TEXT NOT NULL,
  forgejo_status TEXT NOT NULL DEFAULT 'pending',
  PRIMARY KEY (build_id, host)
);

CREATE TABLE IF NOT EXISTS deployments (
  id          INTEGER PRIMARY KEY,
  build_id    INTEGER NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  host        TEXT NOT NULL REFERENCES hosts(name) ON DELETE CASCADE,
  status      TEXT NOT NULL DEFAULT 'pending',
  started_at  TEXT,
  finished_at TEXT,
  error       TEXT,
  created_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS deployment_logs (
  id            INTEGER PRIMARY KEY,
  deployment_id INTEGER NOT NULL REFERENCES deployments(id) ON DELETE CASCADE,
  ts            TEXT NOT NULL,
  line          TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_deployments_host ON deployments (host, status);
CREATE INDEX IF NOT EXISTS idx_deployments_build ON deployments (build_id);
CREATE INDEX IF NOT EXISTS idx_logs_deployment ON deployment_logs (deployment_id, id);
"#;

fn now() -> String {
    Utc::now().to_rfc3339()
}

#[derive(Debug, Clone)]
pub struct Host {
    pub id: i64,
    pub name: String,
    pub last_seen_at: Option<String>,
    pub actual_derivation: Option<String>,
    pub actual_commit: Option<String>,
    pub status: String,
    pub desired_override: Option<String>,
}

#[derive(Debug, Clone)]
pub struct Build {
    pub id: i64,
    pub commit: String,
    pub message: Option<String>,
    pub observed_at: String,
}

#[derive(Debug, Clone)]
pub struct Deployment {
    pub id: i64,
    pub build_id: i64,
    pub host: String,
    pub status: String,
    pub started_at: Option<String>,
    pub finished_at: Option<String>,
    pub error: Option<String>,
}

#[derive(Debug, Clone)]
pub struct LogEntry {
    pub id: i64,
    pub ts: String,
    pub line: String,
}

#[derive(Debug, Clone)]
pub struct BuildDesire {
    pub host: String,
    pub derivation: String,
    pub forgejo_status: String,
}

#[derive(Debug, Clone)]
pub struct IngestedBuild {
    pub build_id: i64,
    /// One entry per host in the build, with whether a deployment was queued.
    pub desires: Vec<DesirePlan>,
}

#[derive(Debug, Clone)]
pub struct DesirePlan {
    pub host: String,
    pub derivation: String,
    pub needs_deploy: bool,
}

#[derive(Debug, Clone)]
pub struct DashboardHost {
    pub name: String,
    pub status: String,
    pub last_seen_at: Option<String>,
    pub actual_derivation: Option<String>,
    pub actual_commit: Option<String>,
    pub desired_derivation: Option<String>,
    pub desired_commit: Option<String>,
    pub desired_forgejo_status: Option<String>,
}

#[derive(Debug, Clone)]
pub struct HostDeployment {
    pub id: i64,
    pub commit: String,
    pub status: String,
    pub started_at: Option<String>,
    pub finished_at: Option<String>,
    pub error: Option<String>,
    pub derivation: String,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct ClaimedDeployment {
    pub id: i64,
    pub build_id: i64,
    pub commit: String,
    pub derivation: String,
}

/// Outcome of a deployment claim.
pub enum ClaimResult {
    Claimed(ClaimedDeployment),
    /// The host already has an active deployment for a different build.
    OtherBuildActive {
        active_build_id: i64,
    },
}

impl ClaimResult {
    pub fn claimed(self) -> Option<ClaimedDeployment> {
        match self {
            ClaimResult::Claimed(d) => Some(d),
            ClaimResult::OtherBuildActive { .. } => None,
        }
    }
}

pub struct Db {
    conn: Mutex<Connection>,
}

impl Db {
    pub async fn open(path: &Path) -> Result<Arc<Db>, String> {
        let parent = path.parent().filter(|p| !p.as_os_str().is_empty());
        if let Some(dir) = parent {
            std::fs::create_dir_all(dir)
                .map_err(|e| format!("creating db dir {}: {e}", dir.display()))?;
        }
        let conn =
            Connection::open(path).map_err(|e| format!("opening db {}: {e}", path.display()))?;
        conn.pragma_update(None, "journal_mode", "WAL")
            .map_err(|e| format!("setting WAL journal mode: {e}"))?;
        conn.pragma_update(None, "foreign_keys", "ON")
            .map_err(|e| format!("enabling foreign keys: {e}"))?;
        let db = Arc::new(Db {
            conn: Mutex::new(conn),
        });
        db.migrate().await?;
        Ok(db)
    }

    async fn migrate(&self) -> Result<(), String> {
        let conn = self.conn.lock().await;
        conn.execute_batch(SCHEMA)
            .map_err(|e| format!("running migrations: {e}"))?;
        // Add columns introduced after the initial schema. Existing databases
        // already have the column, so the "duplicate column name" error is fine.
        let _ = conn.execute("ALTER TABLE hosts ADD COLUMN desired_override TEXT", []);
        Ok(())
    }

    fn row_to_host(row: &rusqlite::Row) -> rusqlite::Result<Host> {
        Ok(Host {
            id: row.get(0)?,
            name: row.get(1)?,
            last_seen_at: row.get(2)?,
            actual_derivation: row.get(3)?,
            actual_commit: row.get(4)?,
            status: row.get(5)?,
            desired_override: row.get(6)?,
        })
    }

    fn row_to_deployment(row: &rusqlite::Row) -> rusqlite::Result<Deployment> {
        Ok(Deployment {
            id: row.get(0)?,
            build_id: row.get(1)?,
            host: row.get(2)?,
            status: row.get(3)?,
            started_at: row.get(4)?,
            finished_at: row.get(5)?,
            error: row.get(6)?,
        })
    }

    fn row_to_log(row: &rusqlite::Row) -> rusqlite::Result<LogEntry> {
        Ok(LogEntry {
            id: row.get(0)?,
            ts: row.get(1)?,
            line: row.get(2)?,
        })
    }

    // --- meta ---

    pub async fn last_observed_commit(&self) -> Result<Option<String>, String> {
        let conn = self.conn.lock().await;
        conn.query_row(
            "SELECT value FROM meta WHERE key = 'last_observed_commit'",
            [],
            |row| row.get(0),
        )
        .optional()
        .map_err(|e| format!("reading last observed commit: {e}"))
    }

    pub async fn set_last_observed_commit(&self, commit: &str) -> Result<(), String> {
        let conn = self.conn.lock().await;
        conn.execute(
            "INSERT INTO meta (key, value) VALUES ('last_observed_commit', ?1)
             ON CONFLICT (key) DO UPDATE SET value = excluded.value",
            [commit],
        )
        .map_err(|e| format!("storing last observed commit: {e}"))?;
        Ok(())
    }

    // --- builds ---

    pub async fn build_by_id(&self, id: i64) -> Result<Option<Build>, String> {
        let conn = self.conn.lock().await;
        conn.query_row(
            "SELECT id, sha, message, observed_at FROM builds WHERE id = ?1",
            [id],
            |row| {
                Ok(Build {
                    id: row.get(0)?,
                    commit: row.get(1)?,
                    message: row.get(2)?,
                    observed_at: row.get(3)?,
                })
            },
        )
        .optional()
        .map_err(|e| format!("loading build {id}: {e}"))
    }

    pub async fn build_by_commit(&self, commit: &str) -> Result<Option<Build>, String> {
        let conn = self.conn.lock().await;
        conn.query_row(
            "SELECT id, sha, message, observed_at FROM builds WHERE sha = ?1",
            [commit],
            |row| {
                Ok(Build {
                    id: row.get(0)?,
                    commit: row.get(1)?,
                    message: row.get(2)?,
                    observed_at: row.get(3)?,
                })
            },
        )
        .optional()
        .map_err(|e| format!("loading build for commit {commit}: {e}"))
    }

    pub async fn latest_builds(&self, limit: i64) -> Result<Vec<Build>, String> {
        let conn = self.conn.lock().await;
        let mut stmt = conn
            .prepare("SELECT id, sha, message, observed_at FROM builds ORDER BY observed_at DESC, id DESC LIMIT ?1")
            .map_err(|e| format!("preparing build query: {e}"))?;
        let rows = stmt
            .query_map([limit], |row| {
                Ok(Build {
                    id: row.get(0)?,
                    commit: row.get(1)?,
                    message: row.get(2)?,
                    observed_at: row.get(3)?,
                })
            })
            .map_err(|e| format!("querying builds: {e}"))?;
        let mut out = Vec::new();
        for row in rows {
            out.push(row.map_err(|e| format!("reading build row: {e}"))?);
        }
        Ok(out)
    }

    pub async fn desires_for_build(&self, build_id: i64) -> Result<Vec<BuildDesire>, String> {
        let conn = self.conn.lock().await;
        let mut stmt = conn
            .prepare("SELECT host, derivation, forgejo_status FROM build_desires WHERE build_id = ?1 ORDER BY host")
            .map_err(|e| format!("preparing desires query: {e}"))?;
        let rows = stmt
            .query_map([build_id], |row| {
                Ok(BuildDesire {
                    host: row.get(0)?,
                    derivation: row.get(1)?,
                    forgejo_status: row.get(2)?,
                })
            })
            .map_err(|e| format!("querying desires: {e}"))?;
        let mut out = Vec::new();
        for row in rows {
            out.push(row.map_err(|e| format!("reading desire row: {e}"))?);
        }
        Ok(out)
    }

    pub async fn desire_derivation(
        &self,
        build_id: i64,
        host: &str,
    ) -> Result<Option<String>, String> {
        let conn = self.conn.lock().await;
        conn.query_row(
            "SELECT derivation FROM build_desires WHERE build_id = ?1 AND host = ?2",
            params![build_id, host],
            |row| row.get(0),
        )
        .optional()
        .map_err(|e| format!("loading desire derivation: {e}"))
    }

    /// The current desired state `(commit, derivation)` for a host: the manual
    /// override if one is set, otherwise the most recent build desire.
    pub async fn current_desired(&self, host: &str) -> Result<Option<(String, String)>, String> {
        let conn = self.conn.lock().await;
        let override_commit: Option<String> = conn
            .query_row(
                "SELECT desired_override FROM hosts WHERE name = ?1",
                [host],
                |row| row.get(0),
            )
            .optional()
            .map_err(|e| format!("loading desired override for {host}: {e}"))?;
        if let Some(commit) = override_commit {
            let overridden: Option<(String, String)> = conn
                .query_row(
                    "SELECT b.sha, bd.derivation
                     FROM build_desires bd
                     JOIN builds b ON b.id = bd.build_id
                     WHERE bd.host = ?1 AND b.sha = ?2
                     LIMIT 1",
                    [host, &commit],
                    |row| Ok((row.get(0)?, row.get(1)?)),
                )
                .optional()
                .map_err(|e| format!("loading overridden desire for {host}: {e}"))?;
            if let Some(d) = overridden {
                return Ok(Some(d));
            }
        }
        conn.query_row(
            "SELECT b.sha, bd.derivation
             FROM build_desires bd
             JOIN builds b ON b.id = bd.build_id
             WHERE bd.host = ?1
             ORDER BY b.observed_at DESC, b.id DESC
             LIMIT 1",
            [host],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .optional()
        .map_err(|e| format!("loading latest desire for {host}: {e}"))
    }

    /// Pin the host's desired state to the given commit. The commit must be a
    /// build that has a desire for the host, otherwise `Ok(false)`.
    pub async fn set_desired_override(&self, host: &str, commit: &str) -> Result<bool, String> {
        let conn = self.conn.lock().await;
        let known: Option<i64> = conn
            .query_row(
                "SELECT bd.build_id
                 FROM build_desires bd
                 JOIN builds b ON b.id = bd.build_id
                 WHERE bd.host = ?1 AND b.sha = ?2",
                [host, commit],
                |row| row.get(0),
            )
            .optional()
            .map_err(|e| format!("validating desired override for {host}: {e}"))?;
        let Some(_build_id) = known else {
            return Ok(false);
        };
        conn.execute(
            "UPDATE hosts SET desired_override = ?2 WHERE name = ?1",
            params![host, commit],
        )
        .map_err(|e| format!("setting desired override for {host}: {e}"))?;
        Ok(true)
    }

    /// Clear the manual desired override, falling back to the latest build.
    pub async fn clear_desired_override(&self, host: &str) -> Result<(), String> {
        let conn = self.conn.lock().await;
        conn.execute(
            "UPDATE hosts SET desired_override = NULL WHERE name = ?1",
            [host],
        )
        .map_err(|e| format!("clearing desired override for {host}: {e}"))?;
        Ok(())
    }

    pub async fn set_desire_forgejo_status(
        &self,
        build_id: i64,
        host: &str,
        status: &str,
    ) -> Result<(), String> {
        let conn = self.conn.lock().await;
        conn.execute(
            "UPDATE build_desires SET forgejo_status = ?3 WHERE build_id = ?1 AND host = ?2",
            params![build_id, host, status],
        )
        .map_err(|e| format!("updating desire forgejo status: {e}"))?;
        Ok(())
    }

    /// Insert a new build and its desires, seeding hosts.
    /// Idempotent: returns early if the commit is already known.
    pub async fn ingest_build(
        &self,
        commit: &str,
        message: Option<&str>,
        desires: &BTreeMap<String, String>,
    ) -> Result<IngestedBuild, String> {
        let mut conn = self.conn.lock().await;

        let existing: Option<i64> = conn
            .query_row("SELECT id FROM builds WHERE sha = ?1", [commit], |row| {
                row.get(0)
            })
            .optional()
            .map_err(|e| format!("checking existing build: {e}"))?;
        if let Some(id) = existing {
            return Ok(IngestedBuild {
                build_id: id,
                desires: Vec::new(),
            });
        }

        let tx = conn
            .transaction()
            .map_err(|e| format!("starting transaction: {e}"))?;
        tx.execute(
            "INSERT INTO builds (sha, message, observed_at) VALUES (?1, ?2, ?3)",
            params![commit, message, now()],
        )
        .map_err(|e| format!("inserting build: {e}"))?;
        let build_id = tx.last_insert_rowid();

        let mut plan = Vec::new();
        for (host, derivation) in desires {
            tx.execute(
                "INSERT INTO hosts (name, created_at) VALUES (?1, ?2) ON CONFLICT (name) DO NOTHING",
                params![host, now()],
            )
            .map_err(|e| format!("seeding host {host}: {e}"))?;

            let actual: Option<String> = tx
                .query_row(
                    "SELECT actual_derivation FROM hosts WHERE name = ?1",
                    [host],
                    |row| row.get(0),
                )
                .optional()
                .map_err(|e| format!("reading host actual: {e}"))?;

            let needs_deploy = actual.as_deref() != Some(derivation.as_str());
            let desire_status = if needs_deploy { "pending" } else { "success" };
            tx.execute(
                "INSERT INTO build_desires (build_id, host, derivation, forgejo_status) VALUES (?1, ?2, ?3, ?4)",
                params![build_id, host, derivation, desire_status],
            )
            .map_err(|e| format!("inserting desire for {host}: {e}"))?;

            plan.push(DesirePlan {
                host: host.clone(),
                derivation: derivation.clone(),
                needs_deploy,
            });
        }

        tx.execute(
            "INSERT INTO meta (key, value) VALUES ('last_observed_commit', ?1)
             ON CONFLICT (key) DO UPDATE SET value = excluded.value",
            [commit],
        )
        .map_err(|e| format!("storing last observed commit: {e}"))?;

        tx.commit()
            .map_err(|e| format!("committing build ingest: {e}"))?;

        Ok(IngestedBuild {
            build_id,
            desires: plan,
        })
    }

    // --- hosts ---

    pub async fn host_by_name(&self, name: &str) -> Result<Option<Host>, String> {
        let conn = self.conn.lock().await;
        conn.query_row(
            "SELECT id, name, last_seen_at, actual_derivation, actual_commit, status, desired_override
             FROM hosts WHERE name = ?1",
            [name],
            Self::row_to_host,
        )
        .optional()
        .map_err(|e| format!("loading host {name}: {e}"))
    }

    pub async fn update_host_seen(
        &self,
        name: &str,
        actual_derivation: Option<&str>,
        actual_commit: Option<&str>,
    ) -> Result<(), String> {
        let conn = self.conn.lock().await;
        conn.execute(
            "UPDATE hosts
             SET last_seen_at = ?2,
                 actual_derivation = COALESCE(?3, actual_derivation),
                 actual_commit = COALESCE(?4, actual_commit)
             WHERE name = ?1",
            params![name, now(), actual_derivation, actual_commit],
        )
        .map_err(|e| format!("updating host {name} last seen: {e}"))?;
        Ok(())
    }

    pub async fn set_host_status(&self, name: &str, status: &str) -> Result<(), String> {
        let conn = self.conn.lock().await;
        conn.execute(
            "UPDATE hosts SET status = ?2 WHERE name = ?1",
            params![name, status],
        )
        .map_err(|e| format!("setting host {name} status: {e}"))?;
        Ok(())
    }

    pub async fn set_host_actual(
        &self,
        name: &str,
        derivation: &str,
        commit: &str,
    ) -> Result<(), String> {
        let conn = self.conn.lock().await;
        conn.execute(
            "UPDATE hosts SET actual_derivation = ?2, actual_commit = ?3 WHERE name = ?1",
            params![name, derivation, commit],
        )
        .map_err(|e| format!("setting host {name} actual: {e}"))?;
        Ok(())
    }

    // --- deployments ---

    pub async fn deployment_by_id(&self, id: i64) -> Result<Option<Deployment>, String> {
        let conn = self.conn.lock().await;
        conn.query_row(
            "SELECT id, build_id, host, status, started_at, finished_at, error FROM deployments WHERE id = ?1",
            [id],
            Self::row_to_deployment,
        )
        .optional()
        .map_err(|e| format!("loading deployment {id}: {e}"))
    }

    /// Create a deployment for `host` targeting `build_id`, or return the host's
    /// existing active (pending/deploying) deployment if it already has one
    /// (idempotent claim, so a re-claim after a crash resumes the same attempt).
    /// The claimed deployment is marked 'deploying' and the host status updated.
    pub async fn claim_deployment(
        &self,
        host: &str,
        build_id: i64,
    ) -> Result<Option<ClaimResult>, String> {
        let mut conn = self.conn.lock().await;
        let tx = conn
            .transaction()
            .map_err(|e| format!("starting transaction: {e}"))?;

        let active: Option<(i64, i64)> = tx
            .query_row(
                "SELECT id, build_id FROM deployments
                 WHERE host = ?1 AND status IN ('pending', 'deploying')
                 ORDER BY id
                 LIMIT 1",
                [host],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .optional()
            .map_err(|e| format!("loading active deployment for {host}: {e}"))?;

        let deployment_id = if let Some((id, active_build_id)) = active {
            // A host can only have one active deployment; if the agent is
            // claiming a different build than the one already in flight, that's
            // a conflict, not a resume. Roll back by returning without commit.
            if active_build_id != build_id {
                return Ok(Some(ClaimResult::OtherBuildActive { active_build_id }));
            }
            id
        } else {
            tx.execute(
                "INSERT INTO hosts (name, created_at) VALUES (?1, ?2) ON CONFLICT (name) DO NOTHING",
                params![host, now()],
            )
            .map_err(|e| format!("seeding host {host}: {e}"))?;
            tx.execute(
                "INSERT INTO deployments (build_id, host, status, started_at, created_at)
                 VALUES (?1, ?2, 'deploying', ?3, ?3)",
                params![build_id, host, now()],
            )
            .map_err(|e| format!("creating deployment for {host}: {e}"))?;
            tx.execute(
                "UPDATE hosts SET status = 'deploying' WHERE name = ?1",
                [host],
            )
            .map_err(|e| format!("marking host {host} deploying: {e}"))?;
            tx.last_insert_rowid()
        };

        let claimed = tx
            .query_row(
                "SELECT d.id, d.build_id, b.sha, bd.derivation
                 FROM deployments d
                 JOIN builds b ON b.id = d.build_id
                 JOIN build_desires bd ON bd.build_id = d.build_id AND bd.host = d.host
                 WHERE d.id = ?1",
                [deployment_id],
                |row| {
                    Ok(ClaimedDeployment {
                        id: row.get(0)?,
                        build_id: row.get(1)?,
                        commit: row.get(2)?,
                        derivation: row.get(3)?,
                    })
                },
            )
            .optional()
            .map_err(|e| format!("loading claimed deployment {deployment_id}: {e}"))?;

        tx.commit().map_err(|e| format!("committing claim: {e}"))?;
        Ok(claimed.map(ClaimResult::Claimed))
    }

    pub async fn finish_deployment(
        &self,
        id: i64,
        status: &str,
        error: Option<&str>,
    ) -> Result<(), String> {
        let conn = self.conn.lock().await;
        conn.execute(
            "UPDATE deployments SET status = ?2, finished_at = ?3, error = ?4 WHERE id = ?1",
            params![id, status, now(), error],
        )
        .map_err(|e| format!("finishing deployment {id}: {e}"))?;
        Ok(())
    }

    pub async fn host_deployments(&self, host: &str) -> Result<Vec<HostDeployment>, String> {
        let conn = self.conn.lock().await;
        let mut stmt = conn
            .prepare(
                "SELECT d.id, b.sha, d.status, d.started_at, d.finished_at, d.error, bd.derivation
                 FROM deployments d
                 JOIN builds b ON b.id = d.build_id
                 JOIN build_desires bd ON bd.build_id = d.build_id AND bd.host = d.host
                 WHERE d.host = ?1
                 ORDER BY d.id DESC
                 LIMIT 50",
            )
            .map_err(|e| format!("preparing host deployment query: {e}"))?;
        let rows = stmt
            .query_map([host], |row| {
                Ok(HostDeployment {
                    id: row.get(0)?,
                    commit: row.get(1)?,
                    status: row.get(2)?,
                    started_at: row.get(3)?,
                    finished_at: row.get(4)?,
                    error: row.get(5)?,
                    derivation: row.get(6)?,
                })
            })
            .map_err(|e| format!("querying host deployments: {e}"))?;
        let mut out = Vec::new();
        for row in rows {
            out.push(row.map_err(|e| format!("reading host deployment row: {e}"))?);
        }
        Ok(out)
    }

    // --- dashboard ---

    /// Every host plus its current desired state (manual override if set,
    /// otherwise most recent desire), for the dashboard table.
    pub async fn dashboard_hosts(&self) -> Result<Vec<DashboardHost>, String> {
        let conn = self.conn.lock().await;
        let mut stmt = conn
            .prepare(
                "SELECT h.name, h.status, h.last_seen_at, h.actual_derivation, h.actual_commit,
                        bd.derivation, b.sha, bd.forgejo_status
                 FROM hosts h
                 LEFT JOIN build_desires bd ON bd.host = h.name
                     AND bd.build_id = (
                         SELECT COALESCE(
                             (SELECT bd2.build_id FROM build_desires bd2
                              JOIN builds b2 ON b2.id = bd2.build_id
                              WHERE bd2.host = h.name AND b2.sha = h.desired_override),
                             (SELECT MAX(bd3.build_id) FROM build_desires bd3 WHERE bd3.host = h.name)
                         )
                     )
                 LEFT JOIN builds b ON b.id = bd.build_id
                 ORDER BY h.name",
            )
            .map_err(|e| format!("preparing dashboard query: {e}"))?;
        let rows = stmt
            .query_map([], |row| {
                Ok(DashboardHost {
                    name: row.get(0)?,
                    status: row.get(1)?,
                    last_seen_at: row.get(2)?,
                    actual_derivation: row.get(3)?,
                    actual_commit: row.get(4)?,
                    desired_derivation: row.get(5)?,
                    desired_commit: row.get(6)?,
                    desired_forgejo_status: row.get(7)?,
                })
            })
            .map_err(|e| format!("querying dashboard hosts: {e}"))?;
        let mut out = Vec::new();
        for row in rows {
            out.push(row.map_err(|e| format!("reading dashboard host row: {e}"))?);
        }
        Ok(out)
    }

    // --- logs ---

    pub async fn append_logs(
        &self,
        deployment_id: i64,
        lines: &[String],
    ) -> Result<Vec<LogEntry>, String> {
        let conn = self.conn.lock().await;
        let mut out = Vec::new();
        for line in lines {
            // Store and broadcast the same timestamp for this entry.
            let ts = now();
            conn.execute(
                "INSERT INTO deployment_logs (deployment_id, ts, line) VALUES (?1, ?2, ?3)",
                params![deployment_id, ts, line],
            )
            .map_err(|e| format!("appending log line: {e}"))?;
            out.push(LogEntry {
                id: conn.last_insert_rowid(),
                ts,
                line: line.clone(),
            });
        }
        Ok(out)
    }

    pub async fn logs_after(
        &self,
        deployment_id: i64,
        after_id: i64,
        limit: i64,
    ) -> Result<Vec<LogEntry>, String> {
        let conn = self.conn.lock().await;
        let mut stmt = conn
            .prepare(
                "SELECT id, ts, line FROM deployment_logs WHERE deployment_id = ?1 AND id > ?2 ORDER BY id ASC LIMIT ?3",
            )
            .map_err(|e| format!("preparing log query: {e}"))?;
        let rows = stmt
            .query_map(params![deployment_id, after_id, limit], Self::row_to_log)
            .map_err(|e| format!("querying logs: {e}"))?;
        let mut out = Vec::new();
        for row in rows {
            out.push(row.map_err(|e| format!("reading log row: {e}"))?);
        }
        Ok(out)
    }

    /// Most recent log lines, newest-last (for the initial page render).
    pub async fn recent_logs(
        &self,
        deployment_id: i64,
        limit: i64,
    ) -> Result<Vec<LogEntry>, String> {
        let conn = self.conn.lock().await;
        let mut stmt = conn
            .prepare(
                "SELECT id, ts, line FROM deployment_logs WHERE deployment_id = ?1 ORDER BY id DESC LIMIT ?2",
            )
            .map_err(|e| format!("preparing recent log query: {e}"))?;
        let rows = stmt
            .query_map(params![deployment_id, limit], Self::row_to_log)
            .map_err(|e| format!("querying recent logs: {e}"))?;
        let mut out = Vec::new();
        for row in rows {
            out.push(row.map_err(|e| format!("reading recent log row: {e}"))?);
        }
        out.reverse();
        Ok(out)
    }
}
