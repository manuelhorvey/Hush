ALTER TABLE conversations DROP COLUMN IF EXISTS participant_id;

CREATE TABLE IF NOT EXISTS conversation_participants (
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    PRIMARY KEY (conversation_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_cp_user ON conversation_participants(user_id);

CREATE TABLE IF NOT EXISTS conversation_keys (
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    encrypted_key TEXT NOT NULL,
    PRIMARY KEY (conversation_id, user_id)
);
