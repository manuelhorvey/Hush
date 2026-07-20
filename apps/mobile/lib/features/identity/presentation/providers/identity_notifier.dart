import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_state_provider.dart';
import '../../models/device_identity.dart';
import '../../models/user_identity.dart';
import '../../models/verification_state.dart';
import 'identity_repository_provider.dart';

enum IdentityStatus { idle, creating, loading, success, error }

class IdentityState {
  final UserIdentity? user;
  final List<DeviceIdentity> devices;
  final IdentityStatus status;
  final String? error;

  const IdentityState({
    this.user,
    this.devices = const [],
    this.status = IdentityStatus.idle,
    this.error,
  });

  IdentityState copyWith({
    UserIdentity? user,
    List<DeviceIdentity>? devices,
    IdentityStatus? status,
    String? error,
    bool clearError = false,
  }) =>
      IdentityState(
        user: user ?? this.user,
        devices: devices ?? this.devices,
        status: status ?? this.status,
        error: clearError ? null : (error ?? this.error),
      );

  bool get hasIdentity => user != null;
}

class IdentityNotifier extends Notifier<IdentityState> {
  @override
  IdentityState build() => const IdentityState();

  Future<bool> create({required String displayName}) async {
    final auth = ref.read(authStateProvider);
    final token = auth.token;
    if (token == null) {
      state = state.copyWith(
        status: IdentityStatus.error,
        error: 'You must be signed in to create an identity.',
      );
      return false;
    }

    state = state.copyWith(
      status: IdentityStatus.creating,
      clearError: true,
    );

    try {
      final repo = ref.read(identityRepositoryProvider);
      final user = await repo.createIdentity(
        token: token,
        displayName: displayName.trim(),
      );
      final devices = await repo.listDevices(token);

      state = state.copyWith(
        user: user,
        devices: devices,
        status: IdentityStatus.success,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: IdentityStatus.error,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> loadDevices() async {
    final auth = ref.read(authStateProvider);
    final token = auth.token;
    if (token == null) return;

    state = state.copyWith(status: IdentityStatus.loading);
    try {
      final repo = ref.read(identityRepositoryProvider);
      final devices = await repo.listDevices(token);
      state = state.copyWith(
        devices: devices,
        status: IdentityStatus.success,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: IdentityStatus.error,
        error: e.toString(),
      );
    }
  }

  void requestVerification() {
    final user = state.user;
    if (user == null) return;
    state = state.copyWith(
      user: user.copyWith(
        verificationState: VerificationState.pending,
      ),
    );
  }

  void confirmVerification() {
    final user = state.user;
    if (user == null) return;
    state = state.copyWith(
      user: user.copyWith(
        verificationState: VerificationState.verified,
      ),
    );
  }

  void setWarning() {
    final user = state.user;
    if (user == null) return;
    state = state.copyWith(
      user: user.copyWith(
        verificationState: VerificationState.warning,
      ),
    );
  }

  void setSessionIdentity({
    required String userId,
    required String username,
  }) {
    state = state.copyWith(
      user: UserIdentity(
        id: userId,
        displayName: username,
        createdAt: DateTime.now(),
        verificationState: VerificationState.unknown,
        verificationPhrase: ref
            .read(identityRepositoryProvider)
            .generateVerificationPhrase(),
      ),
      status: IdentityStatus.success,
      clearError: true,
    );
  }

  void clear() {
    state = const IdentityState();
  }
}

final identityNotifierProvider =
    NotifierProvider<IdentityNotifier, IdentityState>(IdentityNotifier.new);

final identityUserProvider = Provider<UserIdentity?>(
  (ref) => ref.watch(identityNotifierProvider).user,
);

final identityHasIdentityProvider = Provider<bool>(
  (ref) => ref.watch(identityUserProvider) != null,
);

final identityStatusProvider = Provider<IdentityStatus>(
  (ref) => ref.watch(identityNotifierProvider).status,
);

final identityDevicesProvider = Provider<List<DeviceIdentity>>(
  (ref) => ref.watch(identityNotifierProvider).devices,
);

final identityErrorMessageProvider = Provider<String?>(
  (ref) => ref.watch(identityNotifierProvider).error,
);

final verificationPhraseProvider = Provider<String>((ref) {
  final user = ref.watch(identityUserProvider);
  if (user?.verificationPhrase != null) {
    return user!.verificationPhrase!;
  }
  final repo = ref.read(identityRepositoryProvider);
  return repo.generateVerificationPhrase();
});

final verificationStateProvider = Provider<VerificationState>((ref) {
  final user = ref.watch(identityUserProvider);
  return user?.verificationState ?? VerificationState.unknown;
});
