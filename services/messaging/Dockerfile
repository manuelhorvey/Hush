FROM rust:1.80-alpine AS builder

WORKDIR /app

COPY Cargo.toml ./
COPY services/messaging/Cargo.toml services/messaging/Cargo.toml
COPY services/auth/Cargo.toml services/auth/Cargo.toml
COPY services/gateway/Cargo.toml services/gateway/Cargo.toml
COPY services/identity/Cargo.toml services/identity/Cargo.toml
COPY services/messaging/migrations services/messaging/migrations
COPY services/messaging/src services/messaging/src

RUN cargo build --release -p hush-messaging

FROM alpine:3.20 AS runtime

RUN adduser -D -u 10001 hush

WORKDIR /app
COPY --from=builder /app/target/release/hush-messaging /usr/local/bin/hush-messaging

USER hush
EXPOSE 8083

CMD ["hush-messaging"]
