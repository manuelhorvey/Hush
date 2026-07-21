# API Integration Architecture

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                           │
│  Widgets ──> Screens ──> Notifiers (Riverpod)                       │
└──────────────────────────────────┬──────────────────────────────────┘
                                   │ calls
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         DOMAIN LAYER                                │
│  Repository Interfaces (abstract)                                   │
│  Domain Models (UserIdentity, Conversation, Message, DeviceIdentity)│
│  Domain Failures (IdentityFailure)                                  │
└──────────────────────────────────┬──────────────────────────────────┘
                                   │ implements
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          DATA LAYER                                 │
│  Repository Implementations                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │AuthRepository│  │IdentityRepo  │  │Conversation  │              │
│  │              │  │_impl         │  │Repo_impl     │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                 │                 │                       │
│  ┌──────┴───────┐  ┌──────┴───────┐  ┌──────┴───────┐              │
│  │AuthRemote    │  │IdentityRemote│  │Conversation  │              │
│  │DataSource    │  │DataSource    │  │RemoteDataSource             │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                 │                 │                       │
│  ┌──────┴──────────────────┴──────────────────┴───────┐             │
│  │                   ApiClient (Dio)                   │             │
│  │  ┌─────────────┐ ┌──────────┐ ┌────────────────┐  │             │
│  │  │ Auth        │ │ Logging  │ │ Error          │  │             │
│  │  │ Interceptor │ │ Intercept│ │ Interceptor    │  │             │
│  │  └─────────────┘ └──────────┘ └────────────────┘  │             │
│  └──────────────────────┬────────────────────────────┘             │
│                         │                                          │
│  ┌──────────────────────┴────────────────────────────┐             │
│  │           HTTP / WebSocket Transport               │             │
│  │  Development: http://10.0.2.2:8080                 │             │
│  │  Staging:     https://staging.api.hush.app         │             │
│  │  Production:  https://api.hush.app                 │             │
│  └────────────────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        CORE LAYER                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐      │
│  │Environment   │  │SecureStorage │  │WebSocketClient       │      │
│  │Config        │  │Service       │  │(eventStream / states) │      │
│  └──────────────┘  └──────────────┘  └──────────────────────┘      │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
Request Flow:
  Widget/Screen
    → Notifier (Riverpod NotifierProvider)
      → Repository (domain interface)
        → Remote Data Source (abstract interface)
          → ApiClient (Dio with interceptors)
            → Auth Interceptor (injects Bearer token)
              → Logging Interceptor (debug only)
                → Error Interceptor (maps HTTP → typed exception)
                  → HTTP Transport

Response Flow:
  HTTP Transport
    → Error Interceptor (catches & maps to NetworkException hierarchy)
      → Logging Interceptor
        → Remote Data Source (parses JSON → DTO)
          → Repository (maps DTO → domain model, wraps errors)
            → Notifier (updates state)
              → Widget (rebuilds)
```

## Repository Pattern

Each feature follows a strict layered architecture:

```
Feature/
├── data/
│   ├── datasources/        # Remote data source interfaces + Dio impls
│   │   └── *_remote_datasource.dart
│   ├── models/             # DTOs (serialization only, no logic)
│   │   └── *_dto.dart
│   └── repositories/       # Repository implementations
│       └── *_repository_impl.dart
├── domain/
│   ├── *_repository.dart   # Abstract interface
│   └── *_failure.dart      # Domain error types
└── models/                 # Domain models (used by UI)
```

### Rules

1. **DTOs never leave the data layer** — repositories map DTOs to domain models before returning.
2. **Repositories catch `NetworkException` only** — domain failures wrap network errors.
3. **Data sources never throw `NetworkException`** — only `DioException` which is caught by `ErrorInterceptor`.
4. **Domain models have no serialization logic** — that's the DTO's responsibility.

## Files Created

### Core Layer (22 files)

| File | Purpose |
|---|---|
| `lib/core/config/environment.dart` | Dev/Staging/Prod environment configuration |
| `lib/core/config/endpoints.dart` | All API endpoint path constants |
| `lib/core/network/api_client.dart` | Dio-based HTTP client with GET/POST/PUT/PATCH/DELETE |
| `lib/core/network/network_errors.dart` | Sealed exception hierarchy (8 types) |
| `lib/core/network/websocket_client.dart` | WebSocket client with auto-reconnect |
| `lib/core/network/interceptors/auth_interceptor.dart` | Bearer token injection + 401 refresh |
| `lib/core/network/interceptors/logging_interceptor.dart` | Request/response logging (dev only) |
| `lib/core/network/interceptors/error_interceptor.dart` | DioException → NetworkException mapping |
| `lib/core/storage/secure_storage.dart` | FlutterSecureStorage wrapper for session data |
| `lib/core/providers/network_providers.dart` | Riverpod providers for ApiClient, WebSocket, Storage |

### Auth Feature Data Layer (3 files)

| File | Purpose |
|---|---|
| `lib/features/auth/data/models/auth_dto.dart` | RegisterRequest, LoginRequest, AuthResponseDto, RefreshResponseDto |
| `lib/features/auth/data/datasources/auth_remote_datasource.dart` | Auth API interface + Dio implementation |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | AuthRepository: login, register, logout, token management |
| `lib/features/auth/data/auth_providers.dart` | Riverpod providers for auth datasource + repository |

### Identity Feature Data Layer (4 files)

| File | Purpose |
|---|---|
| `lib/features/identity/data/models/identity_dto.dart` | IdentityDto serialization |
| `lib/features/identity/data/models/device_dto.dart` | DeviceDto serialization |
| `lib/features/identity/data/datasources/identity_remote_datasource.dart` | Identity API interface + Dio implementation |
| `lib/features/identity/data/repositories/identity_repository_impl.dart` | IdentityRepositoryImpl matching existing domain interface |
| `lib/features/identity/data/identity_providers.dart` | Riverpod providers for identity datasource + repository |

### Conversations Feature Data Layer (4 files)

| File | Purpose |
|---|---|
| `lib/features/conversations/data/models/conversation_dto.dart` | ConversationDto, ParticipantDto serialization |
| `lib/features/conversations/data/models/message_dto.dart` | MessageDto, SendMessageRequest serialization |
| `lib/features/conversations/data/datasources/conversation_remote_datasource.dart` | Conversation API interface + Dio implementation |
| `lib/features/conversations/data/repositories/conversation_repository_impl.dart` | ConversationRepositoryImpl matching existing domain interface |
| `lib/features/conversations/data/conversation_providers.dart` | Riverpod providers for conversation datasource + repository |

### Tests (6 files)

| File | Tests |
|---|---|
| `test/core/config/environment_test.dart` | EnvironmentConfig values, labels, timeouts |
| `test/core/config/endpoints_test.dart` | All API endpoint paths |
| `test/core/network/network_errors_test.dart` | Exception hierarchy, userFacingMessage, statusCodes |
| `test/features/conversations/data/conversation_dto_test.dart` | ConversationDto, MessageDto, SendMessageRequest serialization |
| `test/features/identity/data/identity_dto_test.dart` | IdentityDto, DeviceDto serialization |
| `test/features/auth/data/auth_dto_test.dart` | AuthResponseDto, RegisterRequest, LoginRequest serialization |

### Documentation (1 file)

| File | Purpose |
|---|---|
| `docs/api-integration.md` | This file |

## Security Considerations

### Never Log
- Authentication tokens (JWT, refresh tokens)
- Message content (plaintext or ciphertext)
- Private keys or identity secrets
- Security material (challenge signatures, verification phrases)

### Transport Security
- Development: HTTP (local network only, no sensitive data)
- Staging/Production: HTTPS/WSS only
- Certificate pinning preparation: `ApiClient` accepts an optional `Dio` instance, allowing custom `HttpClientAdapter` for pinning

### Token Storage
- Auth tokens stored in `FlutterSecureStorage` (Keychain on iOS, EncryptedSharedPreferences on Android)
- Session cleared on 401 after failed refresh
- Token never persisted in shared preferences, logs, or state

### Error Safety
- Network stack never exposes raw `DioException` to UI
- All HTTP errors map to typed `NetworkException` subclasses
- Repository layer wraps `NetworkException` into domain failures before reaching notifiers

## Backend Integration Checklist

### Prerequisites
- [ ] Backend services running on configured ports/URLs
- [ ] API endpoints matching `ApiEndpoints` constants
- [ ] Response JSON shapes matching DTO `fromJson` constructors

### Integration Steps

1. **Environment Configuration**
   - Update `EnvironmentConfig.development` API/WS URLs to match local backend
   - Or configure staging/production URLs when deploying

2. **Provider Wiring**
   - In `HushApp.build()`, override `apiClientProvider` and `webSocketClientProvider` with configured instances
   - Or let the default providers auto-configure from `EnvironmentConfig.current`

3. **Repository Migration (per feature)**
   - Replace `MessagingService` + existing `ConversationRepositoryImpl` with new `ConversationDataSource`-backed implementation
   - Replace `IdentityService` + existing `IdentityRepositoryImpl` with new `IdentityDataSource`-backed implementation
   - Replace `AuthService` + existing `AuthProvider` with new `AuthRepository`

4. **WebSocket Migration**
   - Replace `WebSocketService` with `WebSocketClient`
   - Update event listeners to use `WebSocketClient.eventStream`

5. **Testing**
   - Run full test suite: `flutter test`
   - Verify 401 refresh flow by expiring a token
   - Verify offline behavior by disconnecting network
   - Verify WebSocket reconnection by restarting the backend

### Migration Order (recommended)

```
Phase 1: Core layer (completed)
  → ApiClient, WebSocketClient, SecureStorageService, errors

Phase 2: Auth (next)
  → AuthRemoteDataSource, AuthRepository
  → Replace AuthService usage

Phase 3: Identity (next)
  → IdentityRemoteDataSource, IdentityRepositoryImpl (new)
  → Replace IdentityService usage

Phase 4: Conversations (next)
  → ConversationRemoteDataSource, ConversationRepositoryImpl (new)
  → Replace MessagingService usage

Phase 5: WebSocket (final)
  → Replace WebSocketService with WebSocketClient
  → Update event stream listeners across notifiers
```
