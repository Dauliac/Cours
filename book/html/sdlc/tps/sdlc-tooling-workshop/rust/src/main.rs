use axum::{Json, Router, routing::get};
use serde::Serialize;
use std::net::SocketAddr;
use tokio::signal;

#[derive(Serialize)]
struct Health {
    status: &'static str,
}

#[derive(Serialize)]
struct Info {
    name: &'static str,
    version: &'static str,
}

async fn health() -> Json<Health> {
    Json(Health { status: "ok" })
}

async fn info() -> Json<Info> {
    Json(Info {
        name: env!("CARGO_PKG_NAME"),
        version: env!("CARGO_PKG_VERSION"),
    })
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().json().init();

    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".into())
        .parse()
        .expect("PORT must be a valid number");

    let app = Router::new()
        .route("/health", get(health))
        .route("/info", get(info));

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    tracing::info!(%addr, "server starting");

    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("failed to bind");

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .expect("server error");
}

async fn shutdown_signal() {
    signal::ctrl_c()
        .await
        .expect("failed to listen for ctrl+c");
    tracing::info!("shutting down");
}
