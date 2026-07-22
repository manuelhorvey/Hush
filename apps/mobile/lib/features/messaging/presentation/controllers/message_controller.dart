import 'dart:collection';

import '../../domain/entities/message.dart';

/// Controller for managing a message list with efficient updates.
///
/// Responsibilities:
/// - Append new messages (from WebSocket)
/// - Prepend older messages (from pagination)
/// - Update existing messages (status changes)
/// - Remove messages (failed message cleanup)
/// - Deduplicate by message ID
///
/// Uses a [LinkedHashMap] internally for O(1) lookups by ID
/// while preserving insertion order.
class MessageController {
  final LinkedHashMap<String, Message> _messages = LinkedHashMap();

  /// All messages in order (oldest first).
  List<Message> get messages => _messages.values.toList();

  /// Number of messages.
  int get length => _messages.length;

  /// Replace all messages (initial load).
  void reset(List<Message> messages) {
    _messages.clear();
    for (final msg in messages) {
      _messages[msg.id] = msg;
    }
  }

  /// Append messages to the end (new messages from WS).
  void append(List<Message> messages) {
    for (final msg in messages) {
      if (!_messages.containsKey(msg.id)) {
        _messages[msg.id] = msg;
      }
    }
  }

  /// Prepend messages to the start (older messages from pagination).
  void prepend(List<Message> messages) {
    final existing = _messages.values.toList();
    _messages.clear();
    for (final msg in messages) {
      if (!_messages.containsKey(msg.id)) {
        _messages[msg.id] = msg;
      }
    }
    for (final msg in existing) {
      if (!_messages.containsKey(msg.id)) {
        _messages[msg.id] = msg;
      }
    }
  }

  /// Update a single message by ID.
  void update(Message message) {
    if (_messages.containsKey(message.id)) {
      _messages[message.id] = message;
    }
  }

  /// Remove a message by ID.
  void remove(String messageId) {
    _messages.remove(messageId);
  }

  /// Get a message by ID.
  Message? get(String messageId) => _messages[messageId];

  /// Clear all messages.
  void clear() {
    _messages.clear();
  }

  /// Group messages by their [Message.dateGroupKey].
  ///
  /// Returns a list of (dateLabel, messages) tuples in display order.
  List<(String, List<Message>)> groupByDate() {
    if (_messages.isEmpty) return [];

    final Map<String, List<Message>> grouped = {};
    for (final message in _messages.values) {
      final key = message.dateGroupKey;
      grouped.putIfAbsent(key, () => []).add(message);
    }

    // Sort groups: Today → Yesterday → Earlier this week → Older dates
    final order = ['Today', 'Yesterday', 'Earlier this week'];
    final result = <(String, List<Message>)>[];
    for (final key in order) {
      if (grouped.containsKey(key)) {
        result.add((key, grouped.remove(key)!));
      }
    }

    // Remaining groups sorted chronologically (newest first)
    final remaining = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    for (final entry in remaining) {
      result.add((entry.key, entry.value));
    }

    return result;
  }
}
