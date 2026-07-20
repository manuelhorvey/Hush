import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

class AuthState {
  final SessionInfo? session;
  final bool loading;

  const AuthState({this.session, this.loading = true});

  bool get isLoggedIn => session != null;
  String? get token => session?.token;
  String? get userId => session?.userId;
  String? get username => session?.username;
}

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> init() async {
    final auth = ref.read(authServiceProvider);
    final session = await auth.getSession();
    state = AuthState(session: session, loading: false);
  }

  Future<SessionInfo> register(String username, String publicKey) async {
    final auth = ref.read(authServiceProvider);
    final session = await auth.register(username, publicKey);
    state = AuthState(session: session, loading: false);
    return session;
  }

  Future<SessionInfo> login(String username) async {
    final auth = ref.read(authServiceProvider);
    final session = await auth.login(username);
    state = AuthState(session: session, loading: false);
    return session;
  }

  Future<void> logout() async {
    final auth = ref.read(authServiceProvider);
    await auth.clearSession();
    state = const AuthState(session: null, loading: false);
  }
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(
  AuthStateNotifier.new,
);

final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError('AuthService must be overridden in ProviderScope');
});
