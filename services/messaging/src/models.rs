use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, sqlx::FromRow)]
#[allow(dead_code)]
pub struct Conversation {
    pub id: Uuid,
    pub creator_id: Uuid,
    pub created_at: DateTime<Utc>,
    pub status: String,
    pub expires_at: Option<DateTime<Utc>>,
}

#[derive(Debug, sqlx::FromRow)]
#[allow(dead_code)]
pub struct ConversationParticipant {
    pub conversation_id: Uuid,
    pub user_id: Uuid,
}

#[derive(Debug, sqlx::FromRow)]
#[allow(dead_code)]
pub struct Message {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub sender_id: Uuid,
    pub ciphertext: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateConversationRequest {
    pub participant_ids: Vec<Uuid>,
    pub encrypted_keys: Option<std::collections::HashMap<Uuid, String>>,
    pub expires_in_minutes: Option<i64>,
}

#[derive(Debug, Serialize)]
pub struct ParticipantInfo {
    pub user_id: Uuid,
    pub username: String,
}

#[derive(Debug, Serialize)]
pub struct ConversationResponse {
    pub id: Uuid,
    pub participants: Vec<ParticipantInfo>,
    pub status: String,
    pub expires_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct ConversationListResponse {
    pub conversations: Vec<ConversationResponse>,
}

#[derive(Debug, Deserialize)]
pub struct SendMessageRequest {
    pub ciphertext: String,
}

#[derive(Debug, Serialize)]
pub struct MessageResponse {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub sender_id: Uuid,
    pub ciphertext: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct MessageListResponse {
    pub messages: Vec<MessageResponse>,
}

#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub error: String,
}

#[derive(Debug, sqlx::FromRow, Serialize)]
pub struct UserSearchResult {
    pub id: Uuid,
    pub username: String,
}

#[derive(Debug, Serialize)]
pub struct UserSearchResponse {
    pub users: Vec<UserSearchResult>,
}

#[derive(Debug, Serialize)]
pub struct EncryptedKeyResponse {
    pub encrypted_key: String,
}

#[derive(Debug, Serialize)]
pub struct ParticipantsListResponse {
    pub participants: Vec<ParticipantInfo>,
}
