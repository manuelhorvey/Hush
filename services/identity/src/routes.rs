use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    Json,
};
use ed25519_dalek::VerifyingKey;
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::*;

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

    let row = sqlx::query_scalar::<_, Uuid>(
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
    })?;

    Ok(row)
}

pub async fn register_device(
    State(pool): State<PgPool>,
    headers: HeaderMap,
    Json(body): Json<RegisterDeviceRequest>,
) -> Result<Json<DeviceResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    let device_id = Uuid::new_v4();
    let now = chrono::Utc::now();

    sqlx::query(
        "INSERT INTO devices (id, user_id, device_name, public_key, created_at) VALUES ($1, $2, $3, $4, $5)",
    )
    .bind(device_id)
    .bind(user_id)
    .bind(&body.device_name)
    .bind(&body.public_key)
    .bind(now)
    .execute(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "device registration failed".into() }),
        )
    })?;

    Ok(Json(DeviceResponse {
        id: device_id,
        device_name: body.device_name,
        public_key: body.public_key,
        created_at: now,
    }))
}

pub async fn list_devices(
    State(pool): State<PgPool>,
    headers: HeaderMap,
) -> Result<Json<DeviceListResponse>, (StatusCode, Json<ErrorResponse>)> {
    let user_id = authenticate(&pool, &headers).await?;

    let devices = sqlx::query_as::<_, Device>(
        "SELECT id, user_id, device_name, public_key, created_at FROM devices WHERE user_id = $1 ORDER BY created_at DESC",
    )
    .bind(user_id)
    .fetch_all(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "device list failed".into() }),
        )
    })?;

    Ok(Json(DeviceListResponse {
        devices: devices
            .into_iter()
            .map(|d| DeviceResponse {
                id: d.id,
                device_name: d.device_name,
                public_key: d.public_key,
                created_at: d.created_at,
            })
            .collect(),
    }))
}

pub async fn create_challenge(
    State(pool): State<PgPool>,
    headers: HeaderMap,
    Json(body): Json<ChallengeRequest>,
) -> Result<Json<ChallengeResponse>, (StatusCode, Json<ErrorResponse>)> {
    authenticate(&pool, &headers).await?;

    let challenge_id = Uuid::new_v4();
    let challenge: String = (0..32)
        .map(|_| {
            let idx: usize = rand::random::<usize>() % 16;
            format!("{:x}", idx)
        })
        .collect();
    let now = chrono::Utc::now();
    let expires_at = now + chrono::Duration::minutes(5);

    sqlx::query(
        "INSERT INTO challenges (id, user_id, challenge, created_at, expires_at, used) VALUES ($1, $2, $3, $4, $5, false)",
    )
    .bind(challenge_id)
    .bind(body.target_user_id)
    .bind(&challenge)
    .bind(now)
    .bind(expires_at)
    .execute(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "challenge creation failed".into() }),
        )
    })?;

    Ok(Json(ChallengeResponse {
        challenge_id,
        challenge,
    }))
}

pub async fn verify_challenge(
    State(pool): State<PgPool>,
    headers: HeaderMap,
    Json(body): Json<VerifyRequest>,
) -> Result<Json<VerifyResponse>, (StatusCode, Json<ErrorResponse>)> {
    let _user_id = authenticate(&pool, &headers).await?;

    let challenge = sqlx::query_as::<_, Challenge>(
        "SELECT id, user_id, challenge, created_at, expires_at, used FROM challenges WHERE id = $1 AND expires_at > NOW() AND used = false",
    )
    .bind(body.challenge_id)
    .fetch_optional(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "challenge lookup failed".into() }),
        )
    })?
    .ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(ErrorResponse { error: "challenge not found or expired".into() }),
        )
    })?;

    let device = sqlx::query_as::<_, Device>(
        "SELECT id, user_id, device_name, public_key, created_at FROM devices WHERE user_id = $1 LIMIT 1",
    )
    .bind(challenge.user_id)
    .fetch_optional(&pool)
    .await
    .map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse { error: "device lookup failed".into() }),
        )
    })?
    .ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(ErrorResponse { error: "no device found for user".into() }),
        )
    })?;

    let public_key_bytes = hex::decode(&device.public_key).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: "invalid public key format".into(),
            }),
        )
    })?;

    let verifying_key = VerifyingKey::from_bytes(&public_key_bytes.try_into().map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: "invalid public key".into(),
            }),
        )
    })?)
    .map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: "invalid ed25519 public key".into(),
            }),
        )
    })?;

    let signature_bytes = hex::decode(&body.signature).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: "invalid signature format".into(),
            }),
        )
    })?;

    let signature = ed25519_dalek::Signature::from_slice(&signature_bytes).map_err(|_| {
        (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
                error: "invalid ed25519 signature".into(),
            }),
        )
    })?;

    let verified = verifying_key
        .verify_strict(challenge.challenge.as_bytes(), &signature)
        .is_ok();

    if verified {
        sqlx::query("UPDATE challenges SET used = true WHERE id = $1")
            .bind(body.challenge_id)
            .execute(&pool)
            .await
            .ok();
    }

    Ok(Json(VerifyResponse { verified }))
}
