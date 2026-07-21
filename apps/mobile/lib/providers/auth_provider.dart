import 'package:flutter/foundation.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _auth;

  SessionInfo? _session;
  bool _loading = true;

  AuthProvider({required this._auth});

  SessionInfo? get session => _session;
  bool get isLoggedIn => _session != null;
  String? get token => _session?.token;
  String? get userId => _session?.userId;
  String? get username => _session?.username;
  bool get loading => _loading;

  Future<void> init() async {
    _session = await _auth.tryRestoreSession();
    _loading = false;
    notifyListeners();
  }

  Future<SessionInfo> register(String username, String publicKey) async {
    final session = await _auth.register(username: username, publicKey: publicKey);
    _session = session;
    notifyListeners();
    return session;
  }

  Future<SessionInfo> login(String username) async {
    final session = await _auth.login(username: username);
    _session = session;
    notifyListeners();
    return session;
  }

  Future<void> logout() async {
    await _auth.logout();
    _session = null;
    notifyListeners();
  }
}
