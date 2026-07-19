use std::collections::HashMap;
use std::sync::Arc;

use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Query, State};
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::Json;
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use tokio::sync::{mpsc, RwLock};
use uuid::Uuid;

use crate::models::*;

pub type ConnectionMap = Arc<RwLock<HashMap<Uuid, Vec<mpsc::UnboundedSender<String>>>>>;

#[derive(Deserialize)]
pub struct WsQuery {
    pub token: String,
}

#[derive(Serialize, Deserialize)]
pub struct PushMessage {
    pub user_id: Uuid,
    pub payload: String,
}

pub async fn ws_handler(
    ws: WebSocketUpgrade,
    Query(query): Query<WsQuery>,
    State(state): State<Arc<AppState>>,
) -> Result<Response, (StatusCode, Json<ErrorResponse>)> {
    let token = &query.token;

    let user_id = sqlx::query_scalar::<_, Uuid>(
        "SELECT user_id FROM sessions WHERE token = $1 AND expires_at > NOW()",
    )
    .bind(token)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "session validation failed".into(),
            }),
        )
    })?
    .ok_or_else(|| {
        (
            StatusCode::UNAUTHORIZED,
            Json(ErrorResponse {
                error: "invalid or expired session".into(),
            }),
        )
    })?;

    Ok(ws.on_upgrade(move |socket| handle_socket(socket, user_id, state.conns.clone())))
}

async fn handle_socket(socket: WebSocket, user_id: Uuid, conns: ConnectionMap) {
    let (mut sender, mut receiver) = socket.split();
    let (tx, mut rx) = mpsc::unbounded_channel::<String>();

    conns.write().await.entry(user_id).or_default().push(tx);

    let send_task = tokio::spawn(async move {
        while let Some(msg) = rx.recv().await {
            if sender.send(Message::Text(msg.into())).await.is_err() {
                break;
            }
        }
    });

    let recv_task = tokio::spawn(async move {
        while let Some(Ok(_)) = receiver.next().await {
            // We don't process incoming messages from clients for now
        }
    });

    tokio::select! {
        _ = send_task => {},
        _ = recv_task => {},
    }

    conns.write().await.entry(user_id).and_modify(|senders| {
        senders.retain(|s| !s.is_closed());
    });
}

pub async fn push_handler(
    State(state): State<Arc<AppState>>,
    Json(body): Json<PushMessage>,
) -> impl IntoResponse {
    let conns = state.conns.read().await;
    if let Some(senders) = conns.get(&body.user_id) {
        for sender in senders {
            let _ = sender.send(body.payload.clone());
        }
    }
    StatusCode::OK
}

pub struct AppState {
    pub pool: PgPool,
    pub conns: ConnectionMap,
}
