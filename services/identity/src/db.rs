use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

pub async fn connect(database_url: &str) -> anyhow::Result<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(database_url)
        .await?;

    sqlx::query(include_str!("../migrations/001_create_devices.sql"))
        .execute(&pool)
        .await?;
    sqlx::query(include_str!("../migrations/002_create_challenges.sql"))
        .execute(&pool)
        .await?;

    Ok(pool)
}
