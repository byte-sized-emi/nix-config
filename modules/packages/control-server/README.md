# control-server

`control-server` is the control plane of a GitOps deployment pipeline: it watches a Forgejo
repository for commits that add a fresh `.build-paths.json` (via polling and a webhook), records
which derivation each NixOS host should be on, and serves agents on the hosts so they can decide
to upgrade and claim deployments, streaming back logs. It reports per-host progress as Forgejo
commit statuses and exposes a web UI showing each host's actual vs. desired state with live
deployment logs.

## Typical usage

### Running the server

The server runs on a VPS or nixnest that can reach the Forgejo instance:

```sh
nix run .#control-server -- \
  --forgejo-api https://git.example.org/api/v1 \
  --forgejo-owner myorg \
  --forgejo-repo mynix \
  --public-url https://deploy.example.org
```

Required env secrets:

- `FORGEJO_TOKEN` — Forgejo API token with at least `read` and `write:statuses` scopes.
- `WEBHOOK_SECRET` — shared secret used to verify the Forgejo webhook signature.

Optional flags: `--listen` (default `127.0.0.1:8080`), `--db` (default
`/var/lib/control-server/state.db`), `--branch` (default `main`),
`--build-path` (default `.build-paths.json`), `--poll-interval` (seconds,
default 30), `--webhook-path` (default `/webhook/forgejo`). Point the Forgejo
webhook at `https://<server><webhook-path>` with content type `application/json`.

### Agent protocol

Agents run on each host, talk to `POST /api/v1/*`, and drive deployments
themselves — the control plane never tells a host to do anything:

1. **Poll** — `POST /api/v1/hosts/{name}/poll` with the agent's current state:
   `{"actual_derivation": "...", "actual_commit": "..."}` (both optional).
   Returns `{"desired": {"commit", "derivation"} | null}`.
2. **Decide** — the agent compares `desired.derivation` with the derivation it
   is actually on and chooses a target. It may decline entirely (e.g. auto
   updates off while working directly on the host) or pick a different known
   commit (e.g. roll back to the previous good generation).
3. **Claim** — `POST /api/v1/hosts/{name}/deployments` with
   `{"commit": "<target>"}`. The commit must be one the server has ingested
   (400 otherwise). Returns `{"id", "build_id", "commit", "derivation"}`.
   Idempotent: a re-claim while a deployment is active returns the _same_
   deployment, so a crashed agent resumes where it left off.
4. **Stream logs** — `POST /api/v1/deployments/{id}/log/stream` with a raw,
   newline-delimited body. Lines are persisted and broadcast to the web UI as
   they arrive; partial lines are buffered until the newline (or EOF). Agents
   that don't want a long-lived connection can instead send batched
   `POST /api/v1/deployments/{id}/log` with `{"lines": ["..."]}`.
5. **Finish** — `POST /api/v1/deployments/{id}/finish` with
   `{"status": "succeeded" | "failed", "error": "..."?}`.

### Manual override

A manual deploy is a pin on the host's desired state; the agent then picks it
up on its next poll like any other target:

- Pin: `POST /api/v1/hosts/{name}/desired` with `{"commit": "<target>"}`.
- Unpin (back to latest build): `DELETE /api/v1/hosts/{name}/desired`.

## Development

Work from the crate's devShell (brings `cargo`, `clippy`, `rustfmt`, `bacon`,
`rust-analyzer`, `pkg-config`, `openssl`):

```sh
nix develop .#control-server
```

Checks:

| Command                      | Description             |
| ---------------------------- | ----------------------- |
| `cargo check`                | Fast compile check      |
| `cargo clippy --all-targets` | Lint all targets        |
| `cargo test`                 | Run all tests           |
| `bacon` / `bacon test`       | Watch-mode check / test |

For a quick local run against a scratch database (no Forgejo needed to render
the UI — ingestion just won't pick anything up):

```sh
cargo run -- \
  --db ./tmp/control-server-state.db \
  --forgejo-api https://git.byte-sized.fyi/api/v1 \
  --forgejo-owner emilia --forgejo-repo nix-config \
  --public-url http://localhost:8080
```

with `FORGEJO_TOKEN` and `WEBHOOK_SECRET` exported. The UI is then at
`http://localhost:8080`. To exercise the agent flow against a local instance,
replay the sequence above with `curl` while a deployment page is open in the
browser, e.g.:

```sh
curl -sX POST localhost:8080/api/v1/hosts/nixlaptop/poll \
  -H 'content-type: application/json' \
  -d '{"actual_derivation": "/nix/store/old"}'
curl -sX POST localhost:8080/api/v1/hosts/nixlaptop/deployments \
  -H 'content-type: application/json' \
  -d '{"commit": "<desired commit>"}'
curl -sX POST localhost:8080/api/v1/deployments/1/log/stream \
  --data-binary $'building...\ndone\n'
curl -sX POST localhost:8080/api/v1/deployments/1/finish \
  -H 'content-type: application/json' -d '{"status": "succeeded"}'
```

## Requirements

- Detect new builds via both a periodic poll of the branch head and a Forgejo webhook.
- Agents poll every ~5 minutes rather than holding persistent SSE/WebSocket connections; browser
  log streaming is the only long-lived connection.
- Agents decide for themselves when (and to which commit) to upgrade — they can decline entirely
  (e.g. auto-updates off while working directly on a host). A manual deploy is a server-side
  override of the host's desired state that agents then pick up.
- Run on a VPS or nixnest with a token giving it access to the Forgejo repository.
- Configured via CLI arguments; secrets (`FORGEJO_TOKEN`, `WEBHOOK_SECRET`) come from the
  environment.
- Track each host's actual and desired state (derivation + git commit).
- Keep deployment logs forever.
- No agent authentication for now — private subnet only; mTLS planned for later.
- One Forgejo commit status per host (`nix/deploy/{host}`).
- No local git clone — talk to Forgejo exclusively through its API.
- Web UI showing every host's state and ongoing deployments with live logs.
