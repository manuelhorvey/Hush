mod config;
mod db;
mod models;
mod routes;

use std::time::Duration;

use axum::{routing::delete, routing::get, routing::patch, routing::post, Router};
use config::Config;
use sqlx::PgPool;
use tower_http::trace::TraceLayer;
use tracing::info;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    init_tracing();

    let config = Config::from_env()?;
    let addr = config.socket_addr()?;
    let pool = db::connect(&config.database_url).await?;

    spawn_expiration_task(pool.clone());

    let app = Router::new()
        .route("/api/v1/users/search", get(routes::search_users))
        .route("/api/v1/conversations", post(routes::create_conversation))
        .route("/api/v1/conversations", get(routes::list_conversations))
        .route(
            "/api/v1/conversations/:id/complete",
            patch(routes::complete_conversation),
        )
        .route(
            "/api/v1/conversations/:id",
            delete(routes::destroy_conversation),
        )
        .route(
            "/api/v1/conversations/:id/messages",
            post(routes::send_message),
        )
        .route(
            "/api/v1/conversations/:id/messages",
            get(routes::list_messages),
        )
        .route(
            "/api/v1/conversations/:id/key",
            get(routes::get_conversation_key),
        )
        .route(
            "/api/v1/conversations/:id/participants",
            get(routes::list_participants),
        )
        .layer(TraceLayer::new_for_http())
        .with_state(pool);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    info!(%addr, "hush messaging service listening");

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    Ok(())
}

fn spawn_expiration_task(pool: PgPool) {
    tokio::spawn(async move {
        let mut interval = tokio::time::interval(Duration::from_secs(30));
        loop {
            interval.tick().await;
            routes::expire_conversations(&pool).await;
        }
    });
}

fn init_tracing() {
    let env_filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));
    tracing_subscriber::registry()
        .with(env_filter)
        .with(tracing_subscriber::fmt::layer())
        .init();
}

async fn shutdown_signal() {
    let ctrl_c = async {
        tokio::signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("failed to install signal handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }
}
