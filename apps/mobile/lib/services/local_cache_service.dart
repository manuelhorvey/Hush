import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/conversations/conversation/models/message.dart';
import '../features/conversations/models/conversation.dart';

class PendingMessage {
  final String conversationId;
  final String plaintext;

  const PendingMessage({
    required this.conversationId,
    required this.plaintext,
  });

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'plaintext': plaintext,
  };

  factory PendingMessage.fromJson(Map<String, dynamic> json) {
    return PendingMessage(
      conversationId: json['conversation_id'] as String,
      plaintext: json['plaintext'] as String,
    );
  }
}

abstract class CacheService {
  Future<void> cacheConversations(List<Conversation> conversations);
  Future<List<Conversation>?> getCachedConversations();
  Future<void> cacheMessages(String conversationId, List<Message> messages);
  Future<List<Message>?> getCachedMessages(String conversationId);
  Future<void> addPendingMessage(String conversationId, String plaintext);
  Future<List<PendingMessage>> getPendingMessages(String conversationId);
  Future<void> clearPendingMessages(String conversationId);
  Future<int> clearConversationCache();
}

class SharedPrefsCacheService implements CacheService {
  static const _conversationsKey = 'cached_conversations';
  static const _messagesPrefix = 'cached_messages_';
  static const _pendingPrefix = 'pending_messages_';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<void> cacheConversations(List<Conversation> conversations) async {
    final prefs = await _prefs;
    final json = conversations.map((c) => _conversationToJson(c)).toList();
    await prefs.setString(_conversationsKey, jsonEncode(json));
  }

  @override
  Future<List<Conversation>?> getCachedConversations() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_conversationsKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => _conversationFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheMessages(
      String conversationId, List<Message> messages) async {
    final prefs = await _prefs;
    final json = messages.map((m) => _messageToJson(m)).toList();
    await prefs.setString('$_messagesPrefix$conversationId', jsonEncode(json));
  }

  @override
  Future<List<Message>?> getCachedMessages(String conversationId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_messagesPrefix$conversationId');
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => _messageFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addPendingMessage(String conversationId, String plaintext) async {
    final prefs = await _prefs;
    final key = '$_pendingPrefix$conversationId';
    final raw = prefs.getString(key);
    final list = raw != null
        ? (jsonDecode(raw) as List<dynamic>)
            .map((e) => PendingMessage.fromJson(e as Map<String, dynamic>))
            .toList()
        : <PendingMessage>[];
    list.add(PendingMessage(conversationId: conversationId, plaintext: plaintext));
    await prefs.setString(
      key,
      jsonEncode(list.map((p) => p.toJson()).toList()),
    );
  }

  @override
  Future<List<PendingMessage>> getPendingMessages(
      String conversationId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_pendingPrefix$conversationId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PendingMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearPendingMessages(String conversationId) async {
    final prefs = await _prefs;
    await prefs.remove('$_pendingPrefix$conversationId');
  }

  @override
  Future<int> clearConversationCache() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys().toList();
    int count = 0;
    for (final key in keys) {
      if (key.startsWith(_messagesPrefix) ||
          key.startsWith(_pendingPrefix)) {
        await prefs.remove(key);
        count++;
      }
    }
    await prefs.remove(_conversationsKey);
    return count;
  }

  Map<String, dynamic> _conversationToJson(Conversation c) => {
    'id': c.id,
    'participants': c.participants
        .map((p) => {'id': p.id, 'display_name': p.displayName})
        .toList(),
    'lifecycle': c.lifecycle.name,
    'created_at': c.createdAt.toIso8601String(),
    'completed_at': c.completedAt?.toIso8601String(),
    'is_verified': c.isVerified,
  };

  Conversation _conversationFromJson(Map<String, dynamic> json) {
    final participants = (json['participants'] as List<dynamic>)
        .map((p) => ConversationParticipant(
              id: p['id'] as String,
              displayName: p['display_name'] as String,
            ))
        .toList();
    return Conversation(
      id: json['id'] as String,
      participants: participants,
      lifecycle: ConversationLifecycle.values.firstWhere(
        (l) => l.name == json['lifecycle'],
        orElse: () => ConversationLifecycle.active,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _messageToJson(Message m) => {
    'id': m.id,
    'sender_id': m.senderId,
    'sender_name': m.senderName,
    'content': m.content,
    'created_at': m.createdAt.toIso8601String(),
    'status': m.status.name,
  };

  Message _messageFromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    senderId: json['sender_id'] as String,
    senderName: json['sender_name'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    status: MessageStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => MessageStatus.sent,
    ),
  );
}

class InMemoryCacheService implements CacheService {
  List<Conversation>? _conversations;
  final Map<String, List<Message>> _messages = {};
  final Map<String, List<PendingMessage>> _pending = {};

  @override
  Future<void> cacheConversations(List<Conversation> conversations) async {
    _conversations = conversations;
  }

  @override
  Future<List<Conversation>?> getCachedConversations() async {
    return _conversations;
  }

  @override
  Future<void> cacheMessages(
      String conversationId, List<Message> messages) async {
    _messages[conversationId] = messages;
  }

  @override
  Future<List<Message>?> getCachedMessages(String conversationId) async {
    return _messages[conversationId];
  }

  @override
  Future<void> addPendingMessage(
      String conversationId, String plaintext) async {
    _pending.putIfAbsent(conversationId, () => []);
    _pending[conversationId]!.add(
      PendingMessage(conversationId: conversationId, plaintext: plaintext),
    );
  }

  @override
  Future<List<PendingMessage>> getPendingMessages(
      String conversationId) async {
    return _pending[conversationId] ?? [];
  }

  @override
  Future<void> clearPendingMessages(String conversationId) async {
    _pending.remove(conversationId);
  }

  @override
  Future<int> clearConversationCache() async {
    final count = _messages.length + _pending.length;
    _conversations = null;
    _messages.clear();
    _pending.clear();
    return count;
  }
}

final localCacheServiceProvider = Provider<CacheService>((ref) {
  return SharedPrefsCacheService();
});
