use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    Json,
};
use rand::Rng;
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::*;

pub async fn register(
    State(pool): State<PgPool>,
    Json(body): Json<RegisterRequest>,
) -> Result<Json<AuthResponse>, (StatusCode, Json<ErrorResponse>)> {
    if body.username.trim().is_empty() {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: "username is required".into(),
            }),
        ));
    }

    let user_id = Uuid::new_v4();
    let now = chrono::Utc::now();

    let result = sqlx::query(
        "INSERT INTO users (id, username, public_key, created_at) VALUES ($1, $2, $3, $4)",
    )
    .bind(user_id)
    .bind(&body.username)
    .bind(&body.public_key)
    .bind(now)
    .execute(&pool)
    .await;

    match result {
        Ok(_) => {
            let token = create_session(&pool, user_id, now).await?;
            Ok(Json(AuthResponse { user_id, token }))
        }
        Err(e) => {
            if let Some(db_err) = e.as_database_error() {
                if db_err.code().as_deref() == Some("23505") {
                    return Err((
                        StatusCode::CONFLICT,
                        Json(ErrorResponse {
                            error: "username already exists".into(),
                        }),
                    ));
                }
            }
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "registration failed".into(),
                }),
            ))
        }
    }
}

pub async fn login(
    State(pool): State<PgPool>,
    Json(body): Json<LoginRequest>,
) -> Result<Json<AuthResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE username = $1")
        .bind(&body.username)
        .fetch_optional(&pool)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "login failed".into(),
                }),
            )
        })?;

    let user = user.ok_or_else(|| {
        (
            StatusCode::UNAUTHORIZED,
            Json(ErrorResponse {
                error: "invalid username".into(),
            }),
        )
    })?;

    let token = create_session(&pool, user.id, chrono::Utc::now()).await?;

    Ok(Json(AuthResponse {
        user_id: user.id,
        token,
    }))
}

pub async fn session(
    State(pool): State<PgPool>,
    headers: HeaderMap,
) -> Result<Json<SessionResponse>, (StatusCode, Json<ErrorResponse>)> {
    let token = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(ErrorResponse {
                    error: "missing or invalid authorization header".into(),
                }),
            )
        })?;

    let session = sqlx::query_as::<_, Session>(
        "SELECT * FROM sessions WHERE token = $1 AND expires_at > NOW()",
    )
    .bind(token)
    .fetch_optional(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                error: "session check failed".into(),
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

    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
        .bind(session.user_id)
        .fetch_optional(&pool)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "user lookup failed".into(),
                }),
            )
        })?
        .ok_or_else(|| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ErrorResponse {
                    error: "user not found".into(),
                }),
            )
        })?;

    Ok(Json(SessionResponse {
        user_id: user.id,
        username: user.username,
    }))
}

async fn create_session(
    pool: &PgPool,
    user_id: Uuid,
    now: chrono::DateTime<chrono::Utc>,
) -> Result<String, (StatusCode, Json<ErrorResponse>)> {
    let token: String = rand::thread_rng()
        .sample_iter(&rand::distributions::Alphanumeric)
        .take(64)
        .map(char::from)
        .collect();

    let expires_at = now + chrono::Duration::days(30);

    sqlx::query(
        "INSERT INTO sessions (id, user_id, token, created_at, expires_at) VALUES ($1, $2, $3, $4, $5)",
    )
    .bind(Uuid::new_v4())
    .bind(user_id)
    .bind(&token)
    .bind(now)
    .bind(expires_at)
    .execute(pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "session creation failed".into() }),
        )
    })?;

    Ok(token)
}
