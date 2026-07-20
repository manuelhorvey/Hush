FROM rust:1.88-alpine AS builder

RUN apk add --no-cache musl-dev

WORKDIR /app

COPY Cargo.toml ./
COPY services/ ./services/

RUN cargo build --release

FROM alpine:3.20 AS runtime

RUN adduser -D -u 10001 hush

WORKDIR /app
COPY --from=builder /app/target/release/hush-auth /usr/local/bin/hush-auth

USER hush
EXPOSE 8081

CMD ["hush-auth"]
