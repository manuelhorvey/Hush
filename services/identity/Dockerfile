FROM rust:1.80-alpine AS builder

WORKDIR /app

COPY Cargo.toml ./
COPY services/identity/Cargo.toml services/identity/Cargo.toml
COPY services/auth/Cargo.toml services/auth/Cargo.toml
COPY services/gateway/Cargo.toml services/gateway/Cargo.toml
COPY services/messaging/Cargo.toml services/messaging/Cargo.toml
COPY services/identity/migrations services/identity/migrations
COPY services/identity/src services/identity/src

RUN cargo build --release -p hush-identity

FROM alpine:3.20 AS runtime

RUN adduser -D -u 10001 hush

WORKDIR /app
COPY --from=builder /app/target/release/hush-identity /usr/local/bin/hush-identity

USER hush
EXPOSE 8082

CMD ["hush-identity"]
