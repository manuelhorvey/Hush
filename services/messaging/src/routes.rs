use axum::{
    extract::{Path, Query, State},
    http::{HeaderMap, StatusCode},
    Json,
};
use serde::Deserialize;
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::*;

#[derive(Deserialize)]
pub struct SearchQuery {
    pub q: String,
}

async fn authenticate(
    pool: &PgPool,
    headers: &HeaderMap,
) -> Result<Uuid, (StatusCode, Json<ErrorResponse>)> {
    let token = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(ErrorResponse {
                    error: "missing authorization header".into(),
                }),
            )
        })?;

    sqlx::query_scalar::<_, Uuid>(
        "SELECT user_id FROM sessions WHERE token = $1 AND expires_at > NOW()",
    )
    .bind(token)
    .fetch_optional(pool)
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
    })
}

pub async fn create_conversation(
    State(pool): State<PgPool>,
    headers: HeaderMap,
    Json(body): Json<CreateConversationRequest>,
) -> Result<Json<ConversationResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    if body.participant_id == user_id {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: "cannot create conversation with yourself".into(),
            }),
        ));
    }

    let existing = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM conversations WHERE (creator_id = $1 AND participant_id = $2) OR (creator_id = $2 AND participant_id = $1)",
    )
    .bind(user_id)
    .bind(body.participant_id)
    .fetch_one(&pool)
    .await
    .unwrap_or(0);

    if existing > 0 {
        return Err((
            StatusCode::CONFLICT,
            Json(ErrorResponse {
                error: "conversation already exists".into(),
            }),
        ));
    }

    let conversation_id = Uuid::new_v4();
    let now = chrono::Utc::now();

    sqlx::query(
        "INSERT INTO conversations (id, creator_id, participant_id, created_at) VALUES ($1, $2, $3, $4)",
    )
    .bind(conversation_id)
    .bind(user_id)
    .bind(body.participant_id)
    .bind(now)
    .execute(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "conversation creation failed".into() }),
        )
    })?;

    Ok(Json(ConversationResponse {
        id: conversation_id,
        participant_id: body.participant_id,
        created_at: now,
    }))
}

pub async fn list_conversations(
    State(pool): State<PgPool>,
    headers: HeaderMap,
) -> Result<Json<ConversationListResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    let conversations = sqlx::query_as::<_, Conversation>(
        "SELECT id, creator_id, participant_id, created_at FROM conversations WHERE creator_id = $1 OR participant_id = $1 ORDER BY created_at DESC",
    )
    .bind(user_id)
    .fetch_all(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "conversation list failed".into() }),
        )
    })?;

    let list = conversations
        .into_iter()
        .map(|c| {
            let other_id = if c.creator_id == user_id {
                c.participant_id
            } else {
                c.creator_id
            };
            ConversationResponse {
                id: c.id,
                participant_id: other_id,
                created_at: c.created_at,
            }
        })
        .collect();

    Ok(Json(ConversationListResponse {
        conversations: list,
    }))
}

pub async fn send_message(
    State(pool): State<PgPool>,
    Path(conversation_id): Path<Uuid>,
    headers: HeaderMap,
    Json(body): Json<SendMessageRequest>,
) -> Result<Json<MessageResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    let is_participant = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM conversations WHERE id = $1 AND (creator_id = $2 OR participant_id = $2)",
    )
    .bind(conversation_id)
    .bind(user_id)
    .fetch_one(&pool)
    .await
    .unwrap_or(0)
        > 0;

    if !is_participant {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ErrorResponse {
                error: "not a participant in this conversation".into(),
            }),
        ));
    }

    let message_id = Uuid::new_v4();
    let now = chrono::Utc::now();

    sqlx::query(
        "INSERT INTO messages (id, conversation_id, sender_id, ciphertext, created_at) VALUES ($1, $2, $3, $4, $5)",
    )
    .bind(message_id)
    .bind(conversation_id)
    .bind(user_id)
    .bind(&body.ciphertext)
    .bind(now)
    .execute(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "message send failed".into() }),
        )
    })?;

    Ok(Json(MessageResponse {
        id: message_id,
        sender_id: user_id,
        ciphertext: body.ciphertext,
        created_at: now,
    }))
}

pub async fn search_users(
    State(pool): State<PgPool>,
    headers: HeaderMap,
    Query(query): Query<SearchQuery>,
) -> Result<Json<UserSearchResponse>, (StatusCode, Json<ErrorResponse>)> {
    let _ = authenticate(&pool, &headers).await?;

    let users = sqlx::query_as::<_, UserSearchResult>(
        "SELECT id, username FROM users WHERE username ILIKE $1 LIMIT 20",
    )
    .bind(format!("%{}%", query.q))
    .fetch_all(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "search failed".into(),
            }),
        )
    })?;

    Ok(Json(UserSearchResponse { users }))
}

pub async fn list_messages(
    State(pool): State<PgPool>,
    Path(conversation_id): Path<Uuid>,
    headers: HeaderMap,
) -> Result<Json<MessageListResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    let is_participant = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM conversations WHERE id = $1 AND (creator_id = $2 OR participant_id = $2)",
    )
    .bind(conversation_id)
    .bind(user_id)
    .fetch_one(&pool)
    .await
    .unwrap_or(0)
        > 0;

    if !is_participant {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ErrorResponse {
                error: "not a participant".into(),
            }),
        ));
    }

    let messages = sqlx::query_as::<_, Message>(
        "SELECT id, conversation_id, sender_id, ciphertext, created_at FROM messages WHERE conversation_id = $1 ORDER BY created_at ASC",
    )
    .bind(conversation_id)
    .fetch_all(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "message list failed".into() }),
        )
    })?;

    let list = messages
        .into_iter()
        .map(|m| MessageResponse {
            id: m.id,
            sender_id: m.sender_id,
            ciphertext: m.ciphertext,
            created_at: m.created_at,
        })
        .collect();

    Ok(Json(MessageListResponse { messages: list }))
}
