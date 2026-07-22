use axum::{
    extract::{Path, Query, State},
    http::{HeaderMap, StatusCode},
    Json,
};
use serde::Deserialize;
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::*;

fn gateway_push_url() -> String {
    std::env::var("GATEWAY_INTERNAL_URL").unwrap_or_else(|_| "http://gateway:8080".to_owned())
}

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

async fn is_participant(pool: &PgPool, conversation_id: Uuid, user_id: Uuid) -> bool {
    sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2",
    )
    .bind(conversation_id)
    .bind(user_id)
    .fetch_one(pool)
    .await
    .unwrap_or(0)
        > 0
}

async fn get_participant_ids(
    pool: &PgPool,
    conversation_id: Uuid,
) -> Result<Vec<Uuid>, sqlx::Error> {
    sqlx::query_scalar::<_, Uuid>(
        "SELECT user_id FROM conversation_participants WHERE conversation_id = $1",
    )
    .bind(conversation_id)
    .fetch_all(pool)
    .await
}

async fn build_conv_response(
    pool: &PgPool,
    conv: &Conversation,
    _user_id: Uuid,
) -> ConversationResponse {
    let participants = sqlx::query_as::<_, UserSearchResult>(
        "SELECT u.id, u.username FROM users u JOIN conversation_participants cp ON cp.user_id = u.id WHERE cp.conversation_id = $1",
    )
    .bind(conv.id)
    .fetch_all(pool)
    .await
    .unwrap_or_default()
    .into_iter()
    .map(|u| ParticipantInfo { user_id: u.id, username: u.username })
    .collect();

    ConversationResponse {
        id: conv.id,
        participants,
        status: conv.status.clone(),
        expires_at: conv.expires_at,
        created_at: conv.created_at,
    }
}

pub async fn create_conversation(
    State(pool): State<PgPool>,
    headers: HeaderMap,
    Json(body): Json<CreateConversationRequest>,
) -> Result<Json<ConversationResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    if body.participant_ids.is_empty() {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: "at least one participant required".into(),
            }),
        ));
    }

    let all_ids: Vec<Uuid> = {
        let mut ids = body.participant_ids.clone();
        ids.push(user_id);
        ids.sort();
        ids.dedup();
        ids
    };

    let conversation_id = Uuid::new_v4();
    let now = chrono::Utc::now();
    let expires_at = body
        .expires_in_minutes
        .map(|m| now + chrono::Duration::minutes(m));

    sqlx::query(
        "INSERT INTO conversations (id, creator_id, created_at, status, expires_at) VALUES ($1, $2, $3, 'active', $4)",
    )
    .bind(conversation_id)
    .bind(user_id)
    .bind(now)
    .bind(expires_at)
    .execute(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "conversation creation failed".into() }),
        )
    })?;

    for pid in &all_ids {
        sqlx::query(
            "INSERT INTO conversation_participants (conversation_id, user_id) VALUES ($1, $2)",
        )
        .bind(conversation_id)
        .bind(pid)
        .execute(&pool)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "participant insert failed".into(),
                }),
            )
        })?;
    }

    if let Some(keys) = &body.encrypted_keys {
        for (uid, encrypted_key) in keys {
            sqlx::query(
                "INSERT INTO conversation_keys (conversation_id, user_id, encrypted_key) VALUES ($1, $2, $3) ON CONFLICT (conversation_id, user_id) DO UPDATE SET encrypted_key = $3",
            )
            .bind(conversation_id)
            .bind(uid)
            .bind(encrypted_key)
            .execute(&pool)
            .await
            .ok();
        }
    }

    let conv = Conversation {
        id: conversation_id,
        creator_id: user_id,
        created_at: now,
        status: "active".into(),
        expires_at,
    };

    Ok(Json(build_conv_response(&pool, &conv, user_id).await))
}

pub async fn list_conversations(
    State(pool): State<PgPool>,
    headers: HeaderMap,
) -> Result<Json<ConversationListResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    let conversations = sqlx::query_as::<_, Conversation>(
        "SELECT c.id, c.creator_id, c.created_at, c.status, c.expires_at FROM conversations c JOIN conversation_participants cp ON cp.conversation_id = c.id WHERE cp.user_id = $1 AND c.status != 'destroyed' ORDER BY c.created_at DESC",
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

    let mut list = Vec::new();
    for conv in conversations {
        list.push(build_conv_response(&pool, &conv, user_id).await);
    }

    Ok(Json(ConversationListResponse {
        conversations: list,
    }))
}

pub async fn complete_conversation(
    State(pool): State<PgPool>,
    Path(conversation_id): Path<Uuid>,
    headers: HeaderMap,
) -> Result<Json<ConversationResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    let _ = sqlx::query_as::<_, Conversation>(
        "SELECT id, creator_id, created_at, status, expires_at FROM conversations WHERE id = $1 AND status = 'active'",
    )
    .bind(conversation_id)
    .fetch_optional(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "conversation lookup failed".into() }),
        )
    })?
    .ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(ErrorResponse { error: "active conversation not found".into() }),
        )
    })?;

    if !is_participant(&pool, conversation_id, user_id).await {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ErrorResponse {
                error: "not a participant".into(),
            }),
        ));
    }

    sqlx::query("UPDATE conversations SET status = 'completed' WHERE id = $1")
        .bind(conversation_id)
        .execute(&pool)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "complete failed".into(),
                }),
            )
        })?;

    let updated = sqlx::query_as::<_, Conversation>(
        "SELECT id, creator_id, created_at, status, expires_at FROM conversations WHERE id = $1",
    )
    .bind(conversation_id)
    .fetch_one(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "post-complete fetch failed".into(),
            }),
        )
    })?;

    Ok(Json(build_conv_response(&pool, &updated, user_id).await))
}

pub async fn destroy_conversation(
    State(pool): State<PgPool>,
    Path(conversation_id): Path<Uuid>,
    headers: HeaderMap,
) -> Result<StatusCode, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    if !is_participant(&pool, conversation_id, user_id).await {
        return Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "conversation not found".into(),
            }),
        ));
    }

    sqlx::query("DELETE FROM messages WHERE conversation_id = $1")
        .bind(conversation_id)
        .execute(&pool)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "message deletion failed".into(),
                }),
            )
        })?;

    sqlx::query("DELETE FROM conversation_keys WHERE conversation_id = $1")
        .bind(conversation_id)
        .execute(&pool)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "key deletion failed".into(),
                }),
            )
        })?;

    sqlx::query("DELETE FROM conversation_participants WHERE conversation_id = $1")
        .bind(conversation_id)
        .execute(&pool)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "participant deletion failed".into(),
                }),
            )
        })?;

    sqlx::query("UPDATE conversations SET status = 'destroyed' WHERE id = $1")
        .bind(conversation_id)
        .execute(&pool)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "destroy failed".into(),
                }),
            )
        })?;

    Ok(StatusCode::NO_CONTENT)
}

pub async fn send_message(
    State(pool): State<PgPool>,
    Path(conversation_id): Path<Uuid>,
    headers: HeaderMap,
    Json(body): Json<SendMessageRequest>,
) -> Result<Json<MessageResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    if !is_participant(&pool, conversation_id, user_id).await {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ErrorResponse {
                error: "not a participant".into(),
            }),
        ));
    }

    let status = sqlx::query_scalar::<_, String>("SELECT status FROM conversations WHERE id = $1")
        .bind(conversation_id)
        .fetch_optional(&pool)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "conversation lookup failed".into(),
                }),
            )
        })?
        .ok_or_else(|| {
            (
                StatusCode::NOT_FOUND,
                Json(ErrorResponse {
                    error: "conversation not found".into(),
                }),
            )
        })?;

    if status != "active" {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ErrorResponse {
                error: "conversation is not active".into(),
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

    let response = MessageResponse {
        id: message_id,
        conversation_id,
        sender_id: user_id,
        ciphertext: body.ciphertext.clone(),
        created_at: now,
    };

    let recipient_ids = match get_participant_ids(&pool, conversation_id).await {
        Ok(ids) => ids
            .into_iter()
            .filter(|id| *id != user_id)
            .collect::<Vec<_>>(),
        _ => vec![],
    };

    let payload = serde_json::to_string(&response).unwrap_or_default();
    let gateway_url = gateway_push_url();

    tokio::spawn(async move {
        let client = reqwest::Client::new();
        for rid in recipient_ids {
            let push_payload = serde_json::json!({
                "user_id": rid,
                "payload": payload,
            });
            let _ = client
                .post(format!("{}/_internal/push", gateway_url))
                .json(&push_payload)
                .send()
                .await;
        }
    });

    Ok(Json(response))
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

    if !is_participant(&pool, conversation_id, user_id).await {
        return Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "conversation not found".into(),
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
            conversation_id: m.conversation_id,
            sender_id: m.sender_id,
            ciphertext: m.ciphertext,
            created_at: m.created_at,
        })
        .collect();

    Ok(Json(MessageListResponse { messages: list }))
}

pub async fn get_conversation_key(
    State(pool): State<PgPool>,
    Path(conversation_id): Path<Uuid>,
    headers: HeaderMap,
) -> Result<Json<EncryptedKeyResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    let status = sqlx::query_scalar::<_, String>("SELECT status FROM conversations WHERE id = $1")
        .bind(conversation_id)
        .fetch_optional(&pool)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "conversation lookup failed".into(),
                }),
            )
        })?
        .ok_or_else(|| {
            (
                StatusCode::NOT_FOUND,
                Json(ErrorResponse {
                    error: "conversation not found".into(),
                }),
            )
        })?;

    if status != "active" {
        return Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "conversation not active".into(),
            }),
        ));
    }

    let key = sqlx::query_scalar::<_, String>(
        "SELECT encrypted_key FROM conversation_keys WHERE conversation_id = $1 AND user_id = $2",
    )
    .bind(conversation_id)
    .bind(user_id)
    .fetch_optional(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "key lookup failed".into(),
            }),
        )
    })?
    .ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "encrypted key not found".into(),
            }),
        )
    })?;

    Ok(Json(EncryptedKeyResponse { encrypted_key: key }))
}

pub async fn list_participants(
    State(pool): State<PgPool>,
    Path(conversation_id): Path<Uuid>,
    headers: HeaderMap,
) -> Result<Json<ParticipantsListResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    if !is_participant(&pool, conversation_id, user_id).await {
        return Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "conversation not found".into(),
            }),
        ));
    }

    let participants = sqlx::query_as::<_, UserSearchResult>(
        "SELECT u.id, u.username FROM users u JOIN conversation_participants cp ON cp.user_id = u.id WHERE cp.conversation_id = $1",
    )
    .bind(conversation_id)
    .fetch_all(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "participant list failed".into() }),
        )
    })?
    .into_iter()
    .map(|u| ParticipantInfo {
        user_id: u.id,
        username: u.username,
    })
    .collect();

    Ok(Json(ParticipantsListResponse { participants }))
}

pub async fn expire_conversations(pool: &PgPool) {
    let result = sqlx::query_as::<_, Conversation>(
        "UPDATE conversations SET status = 'destroyed' WHERE status = 'active' AND expires_at IS NOT NULL AND expires_at < NOW() RETURNING id, creator_id, created_at, status, expires_at",
    )
    .fetch_all(pool)
    .await;

    if let Ok(expired) = result {
        for conv in expired {
            let _ = sqlx::query("DELETE FROM messages WHERE conversation_id = $1")
                .bind(conv.id)
                .execute(pool)
                .await;
            let _ = sqlx::query("DELETE FROM conversation_keys WHERE conversation_id = $1")
                .bind(conv.id)
                .execute(pool)
                .await;
            let _ = sqlx::query("DELETE FROM conversation_participants WHERE conversation_id = $1")
                .bind(conv.id)
                .execute(pool)
                .await;
            tracing::info!(id = %conv.id, "auto-expired conversation");
        }
    }
}
