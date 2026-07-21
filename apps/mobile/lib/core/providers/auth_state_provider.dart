import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';

class AuthState {
  final String? token;
  final String? userId;
  final String? username;
  final bool loading;

  const AuthState({this.token, this.userId, this.username, this.loading = true});

  bool get isLoggedIn => token != null;
}

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> init() async {
    final repo = ref.read(authRepositoryProvider);
    final session = await repo.tryRestoreSession();
    if (session != null) {
      state = AuthState(
        token: session.token,
        userId: session.userId,
        username: session.username,
        loading: false,
      );
    } else {
      state = const AuthState(loading: false);
    }
  }

  Future<SessionInfo> register(String username, String publicKey) async {
    final repo = ref.read(authRepositoryProvider);
    final session = await repo.register(username: username, publicKey: publicKey);
    state = AuthState(
      token: session.token,
      userId: session.userId,
      username: session.username,
      loading: false,
    );
    return session;
  }

  Future<SessionInfo> login(String username) async {
    final repo = ref.read(authRepositoryProvider);
    final session = await repo.login(username: username);
    state = AuthState(
      token: session.token,
      userId: session.userId,
      username: session.username,
      loading: false,
    );
    return session;
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AuthState(loading: false);
  }
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(
  AuthStateNotifier.new,
);
