use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

pub async fn connect(database_url: &str) -> anyhow::Result<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(database_url)
        .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS conversations (
            id UUID PRIMARY KEY,
            creator_id UUID NOT NULL,
            participant_id UUID NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )",
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        "CREATE INDEX IF NOT EXISTS idx_conversations_creator ON conversations(creator_id)",
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS messages (
            id UUID PRIMARY KEY,
            conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
            sender_id UUID NOT NULL,
            ciphertext TEXT NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )",
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        "CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id)",
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        "ALTER TABLE conversations ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active'",
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        "ALTER TABLE conversations ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ",
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        "CREATE INDEX IF NOT EXISTS idx_conversations_status ON conversations(status)",
    )
    .execute(&pool)
    .await?;

    sqlx::query("ALTER TABLE conversations DROP COLUMN IF EXISTS participant_id")
        .execute(&pool)
        .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS conversation_participants (
            conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
            user_id UUID NOT NULL,
            PRIMARY KEY (conversation_id, user_id)
        )",
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        "CREATE INDEX IF NOT EXISTS idx_cp_user ON conversation_participants(user_id)",
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        "CREATE TABLE IF NOT EXISTS conversation_keys (
            conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
            user_id UUID NOT NULL,
            encrypted_key TEXT NOT NULL,
            PRIMARY KEY (conversation_id, user_id)
        )",
    )
    .execute(&pool)
    .await?;

    Ok(pool)
}
