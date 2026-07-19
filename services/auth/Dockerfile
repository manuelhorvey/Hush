FROM rust:1.80-alpine AS builder

WORKDIR /app

COPY Cargo.toml ./
COPY services/auth/Cargo.toml services/auth/Cargo.toml
COPY services/auth/migrations services/auth/migrations
COPY services/auth/src services/auth/src

RUN cargo build --release -p hush-auth

FROM alpine:3.20 AS runtime

RUN adduser -D -u 10001 hush

WORKDIR /app
COPY --from=builder /app/target/release/hush-auth /usr/local/bin/hush-auth

USER hush
EXPOSE 8081

CMD ["hush-auth"]
