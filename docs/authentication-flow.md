# Hush Authentication Flow

## Overview

Hush's authentication system is designed around a core principle: **identity ownership, not account management**. Users create a private identity on their device, no email or phone number required. Each device represents a trusted endpoint.

### Philosophy

- A user owns their identity.
- A device represents a trusted endpoint.
- Security should feel simple, not technical.
- Avoid unnecessary friction — no complicated passwords, excessive forms, security jargon, or unnecessary personal information.

---

## User Journey

```
App Launch
    │
    ▼
Splash Screen ──────► Session Check ──────► Authenticated? ────► Home (/chats)
    │                                                │
    │                                                No
    │                                                │
    ▼                                                ▼
    │                                          Welcome Screen
    │                                                │
    │                                    ┌───────────┴───────────┐
    │                                    │                       │
    │                               Create Identity        I have an identity
    │                                    │                       │
    │                                    ▼                       ▼
    │                            Identity Create            Login Screen
    │                                    │                       │
    │                                    ▼                       │
    │                            Register Device                │
    │                                    │                       │
    │                                    ▼                       │
    │                            Device Registered              │
    │                                    │                       │
    │                                    ▼                       ▼
    │                                          Home (/chats)
    ▼
```

**Trust language:** After onboarding, the user should think "This device belongs to me, and my private space is ready." Not "I created another online account."

---

## State Diagram

```
                    ┌─────────────┐
                    │   Unknown   │  (App just launched)
                    └──────┬──────┘
                           │ init()
                           ▼
                 ┌─────────────────┐
                 │  Authenticating │  (Checking for stored session)
                 └────────┬────────┘
                          │
              ┌───────────┴───────────┐
              │                       │
              ▼                       ▼
     ┌────────────────┐    ┌──────────────────────┐
     │ Authenticated  │    │   Unauthenticated     │
     │ (active token) │    │ (no stored session)   │
     └───────┬────────┘    └──────────┬────────────┘
             │                        │
             │ logout()               │ register() / login()
             │                        ▼
             │                ┌─────────────────┐
             │                │  Authenticating │
             │                └────────┬────────┘
             │                         │
             │             ┌───────────┴───────────┐
             │             │                       │
             │             ▼                       ▼
             │    ┌──────────────┐       ┌──────────────────┐
             │    │ Authenticated│       │  Unauthenticated  │
             │    │ (new session)│       │ (failed attempt)  │
             │    └──────┬───────┘       └──────────────────┘
             │           │
             │           │ token refresh fails
             │           ▼
             │    ┌──────────────┐
             │    │   Expired    │
             │    └──────┬───────┘
             │           │ re-authenticate
             │           ▼
             │    ┌──────────────┐
             └───►  Authenticating
                          │
                          ▼
                  ┌──────────────┐
                  │ Authenticated │
                  └──────────────┘
```

---

## Authentication State Model

The `AuthState` is a sealed class with 6 concrete states:

| State | Description | UI Behavior |
|-------|-------------|-------------|
| `AuthUnknown` | App just launched | Splash screen shown |
| `AuthUnauthenticated` | No active session | Redirect to welcome |
| `AuthAuthenticating` | Auth operation in progress | Loading indicators |
| `AuthAuthenticated` | Valid session | Full app access |
| `AuthExpired` | Session expired, needs refresh | Session expired screen |
| `AuthLocked` | Security lockout | Locked screen |

---

## Session Model

`UserSession` represents a validated, time-bound authentication bound to a specific device.

| Field | Type | Description |
|-------|------|-------------|
| `sessionId` | `String` | Unique session identifier |
| `userId` | `String` | User's unique ID |
| `username` | `String` | Display name |
| `createdAt` | `DateTime` | Session creation time |
| `expiresAt` | `DateTime` | Session expiry time |
| `deviceId` | `String` | Bound device ID |
| `status` | `SessionStatus` | Active, Expired, Revoked, or Pending |

**Security note:** Sensitive values (token, refresh token) are stored only in secure storage and never exposed to the UI layer.

---

## Device Identity Model

`DeviceIdentity` represents a device bound to a user's identity.

| Field | Type | Description |
|-------|------|-------------|
| `deviceId` | `String` | Unique device identifier |
| `deviceName` | `String` | Human-readable device name |
| `platform` | `String` | Platform (mobile, web, etc.) |
| `createdAt` | `DateTime` | Registration timestamp |
| `trustedStatus` | `DeviceTrustStatus` | Trusted, Pending, Revoked, or Unknown |

**Trust language:** Use "trusted" rather than "authenticated". Users understand trust intuitively.

---

## Architecture

### File Structure

```
features/auth/
├── domain/
│   ├── entities/
│   │   ├── auth_state.dart            # Sealed AuthState class
│   │   ├── user_session.dart          # UserSession entity
│   │   └── device_identity.dart       # DeviceIdentity entity
│   ├── repositories/
│   │   ├── auth_repository.dart       # Abstract auth repository
│   │   └── device_repository.dart     # Abstract device repository
│   └── services/
│       └── session_manager.dart       # Session lifecycle management
├── data/
│   ├── datasources/
│   │   ├── auth_local_datasource.dart  # Secure storage persistence
│   │   └── auth_remote_datasource.dart # Remote API calls
│   ├── models/
│   │   ├── auth_dto.dart              # Auth request/response DTOs
│   │   └── session_dto.dart           # Session/device DTOs
│   └── repositories/
│       ├── auth_repository_impl.dart   # Legacy auth repository (unchanged)
│       ├── domain_auth_repository_impl.dart  # Domain auth repository
│       └── device_repository_impl.dart # Device repository implementation
└── presentation/
    ├── providers/
    │   ├── auth_state_provider.dart   # Domain auth state provider
    │   ├── session_provider.dart      # Session state providers
    │   └── device_provider.dart       # Device identity provider
    ├── screens/
    │   ├── welcome_screen.dart        # Welcome/onboarding screen
    │   ├── identity_create_screen.dart # Identity creation screen
    │   ├── device_registration_screen.dart # Device registration screen
    │   └── session_expired_screen.dart # Session expiration screen
    └── widgets/
        ├── session_status_card.dart   # Session state display card
        ├── device_trust_card.dart     # Device trust display card
        ├── security_notice.dart       # Security information notice
        └── logout_confirmation_dialog.dart # Logout dialog
```

---

## Key Components

### AuthStateProvider

The `domainAuthStateProvider` is the new Riverpod provider that manages the sealed `AuthState`. It replaces the legacy `authStateProvider` for new screens.

```dart
final authState = ref.watch(domainAuthStateProvider);

// Pattern match on the sealed class
authState.when(
  unknown: () => ...,
  unauthenticated: () => ...,
  authenticating: () => ...,
  authenticated: (token, userId, username, deviceId) => ...,
  expired: () => ...,
  locked: () => ...,
);
```

### SessionManager

Manages the lifecycle of a user session, including:
- Starting and ending sessions
- Monitoring session expiry
- Providing current session state

### AuthRepository

Abstract interface for authentication operations. The `DomainAuthRepositoryImpl` orchestrates remote API calls, local secure storage, and session lifecycle management.

---

## Security Decisions

| Decision | Rationale |
|----------|-----------|
| **No passwords** | Device ownership is the authentication mechanism. Reduces attack surface. |
| **No email/phone** | Minimizes personal data collection. No PII to leak. |
| **Secure storage** | Tokens and session data stored via `flutter_secure_storage` (iOS Keychain / Android EncryptedSharedPreferences). |
| **Session expiry** | Sessions have a 30-day expiry. Refresh tokens enable seamless renewal. |
| **Token refresh** | Short-lived access tokens with refresh token rotation. |
| **Offline support** | Stored credentials enable offline access until expiry. Session validated on reconnect. |

---

## Trust Language Map

| Avoid | Prefer |
|-------|--------|
| "Device authentication complete" | "Device trusted" |
| "Session token generated" | "You're securely signed in" |
| "Invalid credentials" | "Unable to verify your device" |
| "Delete account" | "Sign out of this device" |
| "Login" | "I have an identity" |

---

## Future Backend Requirements

1. **Session revocation API** — Allow users to end sessions on remote devices.
2. **Multi-device key sync** — Exchange keys between trusted devices for unified access. (Synchronization is out of scope for Phase 1.)
3. **Device trust acknowledgment** — Server-side confirmation that a device is trusted.
4. **Remote device management** — API to list, rename, and remove remote devices.
5. **Audit logging** — Non-sensitive session activity log for user review.

---

## Testing

### Auth State Tests

- `test/features/auth/auth_state_test.dart` — Verifies all 6 AuthState subtypes, their `is*` properties, equality, and exhaustiveness.
- `test/features/auth/user_session_test.dart` — Verifies session lifecycle, expiry, revocation, and `copyWith`.
- `test/features/auth/device_identity_test.dart` — Verifies trust status labels, display dates, and copy semantics.

### Coverage Areas

- Auth state transitions
- Session validity and expiry
- Device trust states
- Token refresh flow
- Logout and session clearing
- Offline session restore
