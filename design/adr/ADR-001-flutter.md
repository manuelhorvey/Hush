# ADR-001 — Why Flutter?

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Platform team  

## Context

Hush targets iOS, Android, and (in the future) Desktop and Web. We needed a cross-platform framework that allows a single codebase to ship on all platforms without sacrificing performance, particularly for cryptographic operations.

## Options Considered

| Option | Pros | Cons |
|---|---|---|
| **Flutter** | Single codebase, high performance, Dart compiles to native, strong crypto library support, growing ecosystem | Larger binary size, platform-specific plugins needed for some features, Dart talent pool smaller than Swift/Kotlin |
| **React Native** | Larger talent pool, JavaScript ecosystem | JavaScript bridge performance overhead, more complex native module integration for crypto, less consistent platform look-and-feel |
| **SwiftUI + Jetpack Compose** | Best platform fidelity, full native API access | Two codebases, 2x maintenance, slower feature delivery |
| **Kotlin Multiplatform** | Shared logic, native UI | Less mature tooling, smaller ecosystem, complex build setup |

## Decision

Use Flutter.

## Rationale

- **Performance**: Dart compiles to native ARM code. No JavaScript bridge. This matters for cryptographic operations where every millisecond counts.
- **Single codebase**: Hush is a small team. Maintaining two native codebases is not viable.
- **Ecosystem**: `flutter_secure_storage`, `pointycastle` (crypto), and `provider` give us everything we need without writing native code.
- **Future-proof**: Flutter web and desktop are mature enough that Hush can expand to those platforms without rewriting.

## Consequences

- Positive: Faster development velocity, single feature set across platforms
- Positive: Hot reload for rapid UI iteration
- Positive: Same codebase for mobile → desktop → web
- Negative: Larger APK/IPA size (~15-20MB baseline)
- Negative: Some platform-specific behaviors (safe areas, keyboard handling) require explicit handling
- Negative: Flutter's rendering pipeline means custom accessibility work (no native accessibility for free)

## Related

- ADR-002 (Why Rust for the backend)
