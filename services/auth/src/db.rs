use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

pub async fn connect(database_url: &str) -> anyhow::Result<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(database_url)
        .await?;

    let migration = include_str!("../migrations/001_create_users_and_sessions.sql");
    sqlx::raw_sql(migration).execute(&pool).await?;

    Ok(pool)
}
