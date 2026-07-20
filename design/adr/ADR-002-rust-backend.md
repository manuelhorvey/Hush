# ADR-002 — Why Rust for the Backend

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Platform team  

## Context

The Hush backend needs to handle WebSocket connections for real-time messaging, REST endpoints for conversation management, and cryptographic operations. The backend must be performant, memory-safe, and capable of handling concurrent connections efficiently.

## Options Considered

| Option | Pros | Cons |
|---|---|---|
| **Rust (Axum)** | Memory safety without GC, excellent concurrency (tokio), strong type system, small binary | Steeper learning curve, longer initial development, smaller ecosystem than Go/Node |
| **Go** | Fast compilation, simple concurrency model, large ecosystem, easy to learn | GC latency under high load, less expressive type system, runtime overhead |
| **Node.js** | Fastest initial development, vast ecosystem, easy hiring | Single-threaded, callback-heavy for async operations, GC pauses, weak typing |
| **Python (FastAPI)** | Fastest prototyping, excellent for async | GIL limits concurrency, poor performance for message relay at scale, runtime overhead |

## Decision

Use Rust with Axum framework.

## Rationale

- **Memory safety**: Rust's ownership model prevents use-after-free, buffer overflows, and data races at compile time. For a security-focused product handling encrypted messages, this is non-negotiable.
- **Concurrency**: Tokio's async runtime handles tens of thousands of concurrent WebSocket connections without the overhead of goroutines or the complexity of Node streams.
- **Performance**: Rust's zero-cost abstractions mean the backend can handle message relay without noticeable latency, even under load.
- **Binary size**: A Rust binary is a single executable with no runtime dependencies — trivial to deploy in Docker.
- **Security posture**: The Rust compiler catches entire classes of security bugs that would be runtime issues in Go, Python, or Node.

## Consequences

- Positive: Compile-time memory safety eliminates entire categories of security vulnerabilities
- Positive: Excellent performance for WebSocket-based message relay
- Positive: Small Docker images, fast cold starts
- Negative: Longer initial development time (borrow checker learning curve)
- Negative: Fewer Rust developers available for hire compared to Go/Node
- Negative: Compile times are longer than Go or Node

## Related

- ADR-001 (Why Flutter for the client)
