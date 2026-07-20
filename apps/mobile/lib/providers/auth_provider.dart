import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth;

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
    _session = await _auth.getSession();
    _loading = false;
    notifyListeners();
  }

  Future<SessionInfo> register(String username, String publicKey) async {
    final session = await _auth.register(username, publicKey);
    _session = session;
    notifyListeners();
    return session;
  }

  Future<SessionInfo> login(String username) async {
    final session = await _auth.login(username);
    _session = session;
    notifyListeners();
    return session;
  }

  Future<void> logout() async {
    await _auth.clearSession();
    _session = null;
    notifyListeners();
  }
}
