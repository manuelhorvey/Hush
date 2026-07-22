import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'double_ratchet.dart';

class RatchetSessionStore {
  final FlutterSecureStorage _storage;
  static const _prefix = 'ratchet_session_';
  static const _sendSuffix = '_send';
  static const _recvSuffix = '_recv';

  RatchetSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String _sendKey(String conversationId) =>
      '$_prefix${conversationId}$_sendSuffix';
  String _recvKey(String conversationId) =>
      '$_prefix${conversationId}$_recvSuffix';
  String _oldKey(String conversationId) =>
      '$_prefix$conversationId';

  Future<DoubleRatchetSession?> loadSend(String conversationId) async {
    final raw = await _storage.read(key: _sendKey(conversationId));
    if (raw == null) return null;
    return DoubleRatchetSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSend(
      String conversationId, DoubleRatchetSession session) async {
    await _storage.write(
      key: _sendKey(conversationId),
      value: jsonEncode(session.toJson()),
    );
  }

  Future<DoubleRatchetSession?> loadRecv(String conversationId) async {
    final raw = await _storage.read(key: _recvKey(conversationId));
    if (raw == null) return null;
    return DoubleRatchetSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveRecv(
      String conversationId, DoubleRatchetSession session) async {
    await _storage.write(
      key: _recvKey(conversationId),
      value: jsonEncode(session.toJson()),
    );
  }

  Future<void> delete(String conversationId) async {
    await _storage.delete(key: _sendKey(conversationId));
    await _storage.delete(key: _recvKey(conversationId));
    // Clean up any sessions persisted with the old single-key format.
    await _storage.delete(key: _oldKey(conversationId));
  }
}
