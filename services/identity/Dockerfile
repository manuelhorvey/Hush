FROM rust:1.86-alpine AS builder

WORKDIR /app

COPY Cargo.toml ./
COPY services/ ./services/

RUN cargo build --release

FROM alpine:3.20 AS runtime

RUN adduser -D -u 10001 hush

WORKDIR /app
COPY --from=builder /app/target/release/hush-identity /usr/local/bin/hush-identity

USER hush
EXPOSE 8082

CMD ["hush-identity"]
