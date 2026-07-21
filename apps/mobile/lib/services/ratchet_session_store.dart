import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'double_ratchet.dart';

class RatchetSessionStore {
  final FlutterSecureStorage _storage;
  static const _prefix = 'ratchet_session_';

  RatchetSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<DoubleRatchetSession?> load(String conversationId) async {
    final raw = await _storage.read(key: '$_prefix$conversationId');
    if (raw == null) return null;
    return DoubleRatchetSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(
      String conversationId, DoubleRatchetSession session) async {
    await _storage.write(
      key: '$_prefix$conversationId',
      value: jsonEncode(session.toJson()),
    );
  }

  Future<void> delete(String conversationId) async {
    await _storage.delete(key: '$_prefix$conversationId');
  }
}
