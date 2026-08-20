use std::convert::Infallible;
use std::pin::Pin;
use std::time::Duration;

use axum::extract::{Path, Query, State};
use axum::response::sse::{Event, Sse};
use futures::{Stream, StreamExt, stream};
use tokio::sync::broadcast;

use crate::AppState;

#[derive(serde::Deserialize)]
pub struct StreamParams {
    pub after: Option<i64>,
}

fn html_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}

fn make_event(ts: &str, line: &str) -> Event {
    Event::default().event("log").data(format!(
        "<div class=\"log-line\"><span class=\"log-ts\">[{}]</span> {}</div>",
        ts,
        html_escape(line)
    ))
}

pub async fn log_stream(
    State(state): State<AppState>,
    Path(id): Path<i64>,
    Query(params): Query<StreamParams>,
) -> Sse<Pin<Box<dyn Stream<Item = Result<Event, Infallible>> + Send>>> {
    let after = params.after.unwrap_or(0);

    let exists = matches!(state.db.deployment_by_id(id).await, Ok(Some(_)));

    if !exists {
        let stream = stream::once(async move {
            Ok::<_, Infallible>(Event::default().event("log").data("deployment not found"))
        });
        return Sse::new(Box::pin(stream));
    }

    let existing = state
        .db
        .logs_after(id, after, 10_000)
        .await
        .unwrap_or_default();
    let start_id = existing.last().map(|e| e.id).unwrap_or(after);
    let existing_events: Vec<Event> = existing
        .into_iter()
        .map(|entry| make_event(&entry.ts, &entry.line))
        .collect();

    let rx = state.channel(id).await.subscribe();

    // Live log stream with lag recovery: if the broadcast buffer overflows, catch
    // up from the DB instead of terminating the stream. `last_id` dedupes entries
    // that appear both in the DB catch-up and the broadcast buffer.
    let rx_stream = stream::unfold(
        (rx, state, Vec::new(), start_id),
        move |(mut rx, state, mut catchup, mut last_id)| async move {
            loop {
                if let Some((entry_id, ts, line)) = catchup.pop() {
                    if entry_id > last_id {
                        last_id = entry_id;
                        return Some(((entry_id, ts, line), (rx, state, catchup, last_id)));
                    }
                    continue;
                }
                match rx.recv().await {
                    Ok((entry_id, ts, line)) if entry_id > last_id => {
                        return Some(((entry_id, ts, line), (rx, state, catchup, last_id)));
                    }
                    Ok(_) => continue,
                    Err(broadcast::error::RecvError::Lagged(_)) => {
                        if let Ok(missed) = state.db.logs_after(id, last_id, 10_000).await {
                            catchup = missed
                                .into_iter()
                                .map(|e| (e.id, e.ts, e.line))
                                .rev()
                                .collect();
                        }
                    }
                    Err(broadcast::error::RecvError::Closed) => return None,
                }
            }
        },
    )
    .map(|(_entry_id, ts, line)| make_event(&ts, &line));

    let heartbeat = stream::unfold(
        tokio::time::interval(Duration::from_secs(15)),
        |mut ticker| async move {
            ticker.tick().await;
            Some((Event::default().comment("ping"), ticker))
        },
    );

    let initial = stream::iter(existing_events);
    let live = rx_stream;
    let combined = stream::select(stream::select(initial, live), heartbeat);
    Sse::new(Box::pin(combined.map(Ok)))
}
