use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, sqlx::FromRow)]
#[allow(dead_code)]
pub struct User {
    pub id: Uuid,
    pub username: String,
    pub public_key: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, sqlx::FromRow)]
#[allow(dead_code)]
pub struct Session {
    pub id: Uuid,
    pub user_id: Uuid,
    pub token: String,
    pub created_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub username: String,
    pub public_key: String,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub username: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub user_id: Uuid,
    pub token: String,
}

#[derive(Debug, Serialize)]
pub struct SessionResponse {
    pub user_id: Uuid,
    pub username: String,
}

#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub error: String,
}
