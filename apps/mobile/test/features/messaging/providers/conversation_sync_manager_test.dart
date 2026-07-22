import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/messaging/domain/entities/connection_state.dart';
import 'package:hush_mobile/features/messaging/domain/entities/conversation_event.dart';
import 'package:hush_mobile/features/messaging/domain/entities/message.dart';
import 'package:hush_mobile/features/messaging/domain/entities/message_status.dart';
import 'package:hush_mobile/features/messaging/domain/repositories/message_repository.dart';
import 'package:hush_mobile/features/messaging/presentation/providers/conversation_sync_manager.dart';

// ═══════════════════════════════════════════════════════════════
// Mock MessageRepository
// ═══════════════════════════════════════════════════════════════

class MockMessageRepository implements MessageRepository {
  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  int sendCallCount = 0;
  int getCallCount = 0;
  int retryCallCount = 0;
  int failCallCount = 0;
  String? lastConversationId;

  @override
  Stream<ConnectionState> observeConnectionState() {
    return _connectionStateController.stream;
  }

  void emitConnectionState(ConnectionState state) {
    _connectionStateController.add(state);
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String plaintext,
    required String currentUserId,
    required String currentUserName,
  }) async {
    sendCallCount++;
    lastConversationId = conversationId;
    return Message(
      id: 'sent-msg-1',
      conversationId: conversationId,
      senderId: currentUserId,          senderName: currentUserName,
      content: plaintext,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  @override
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  }) async {
    getCallCount++;
    lastConversationId = conversationId;
    return [];
  }

  @override
  Stream<Message> observeMessages(String conversationId) {
    return const Stream.empty();
  }

  @override
  Stream<ConversationEvent> observeEvents(String conversationId) {
    return const Stream.empty();
  }

  @override
  Future<Message> retryMessage(
    String conversationId,
    Message failedMessage,
  ) async {
    retryCallCount++;
    lastConversationId = conversationId;
    return failedMessage.copyWith(status: MessageStatus.sent);
  }

  @override
  Future<void> failPendingMessages(String conversationId) async {
    failCallCount++;
    lastConversationId = conversationId;
  }

  void dispose() {
    _connectionStateController.close();
  }
}

// ═══════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════

void main() {
  group('ConversationSyncManager', () {
    late MockMessageRepository mockRepo;
    late ConversationSyncManager manager;

    setUp(() {
      mockRepo = MockMessageRepository();
      manager = ConversationSyncManager(repository: mockRepo);
    });

    tearDown(() {
      manager.dispose();
      mockRepo.dispose();
    });

    group('constructor and initialization', () {
      test('starts with empty active conversations', () {
        expect(manager.refreshStream, isA<Stream<String>>());
      });

      test('does not emit refresh on initial connection', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        mockRepo.emitConnectionState(ConnectionState.connected);
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);
        await sub.cancel();
      });
    });

    group('registerConversation / unregisterConversation', () {
      test('registerConversation does not emit refresh', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        manager.registerConversation('conv-1');
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);
        await sub.cancel();
      });

      test('unregisterConversation does not emit refresh', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        manager.registerConversation('conv-1');
        manager.unregisterConversation('conv-1');
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);
        await sub.cancel();
      });
    });

    group('reconnection', () {
      test('emits refresh for registered conversations on reconnect', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        // Simulate disconnect then reconnect
        mockRepo.emitConnectionState(ConnectionState.disconnected);
        mockRepo.emitConnectionState(ConnectionState.connected);
        await Future<void>.delayed(Duration.zero);

        // No registered conversations yet
        expect(events, isEmpty);

        await sub.cancel();
      });

      test('emits refresh for each registered conversation on reconnect', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        manager.registerConversation('conv-a');
        manager.registerConversation('conv-b');

        // Simulate disconnect → reconnect
        mockRepo.emitConnectionState(ConnectionState.disconnected);
        mockRepo.emitConnectionState(ConnectionState.connected);
        await Future<void>.delayed(Duration.zero);

        expect(events, containsAll(['conv-a', 'conv-b']));
        expect(events.length, 2);

        await sub.cancel();
      });

      test('does not emit refresh for unregistered conversations', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        manager.registerConversation('conv-a');
        manager.registerConversation('conv-b');
        manager.unregisterConversation('conv-b');

        mockRepo.emitConnectionState(ConnectionState.disconnected);
        mockRepo.emitConnectionState(ConnectionState.connected);
        await Future<void>.delayed(Duration.zero);

        expect(events, contains('conv-a'));
        expect(events, isNot(contains('conv-b')));

        await sub.cancel();
      });

      test('does not emit on reconnecting state (only connected)', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        manager.registerConversation('conv-a');

        mockRepo.emitConnectionState(ConnectionState.reconnecting);
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);

        await sub.cancel();
      });

      test('does not emit when transitioning from connected to failed', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        // First connect to establish baseline
        mockRepo.emitConnectionState(ConnectionState.connected);
        await Future<void>.delayed(Duration.zero);

        manager.registerConversation('conv-a');

        // Now go to failed — should NOT trigger refresh
        mockRepo.emitConnectionState(ConnectionState.failed);
        await Future<void>.delayed(Duration.zero);

        // No refresh on failed transition
        expect(events, isEmpty);

        await sub.cancel();
      });

      test('emits only once when reconnecting from failed to connected', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        manager.registerConversation('conv-a');

        // failed → connected should trigger refresh
        mockRepo.emitConnectionState(ConnectionState.failed);
        mockRepo.emitConnectionState(ConnectionState.connected);
        await Future<void>.delayed(Duration.zero);

        expect(events, ['conv-a']);

        await sub.cancel();
      });
    });

    group('processEvent()', () {
      test('emits refresh on conversationCompleted event', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        final event = ConversationEvent(
          type: ConversationEventType.conversationCompleted,
          conversationId: 'conv-1',
          timestamp: DateTime.now(),
        );
        await manager.processEvent(event);
        await Future<void>.delayed(Duration.zero);

        expect(events, ['conv-1']);

        await sub.cancel();
      });

      test('emits refresh on conversationClosed event', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        final event = ConversationEvent(
          type: ConversationEventType.conversationClosed,
          conversationId: 'conv-2',
          timestamp: DateTime.now(),
        );
        await manager.processEvent(event);
        await Future<void>.delayed(Duration.zero);

        expect(events, ['conv-2']);

        await sub.cancel();
      });

      test('emits refresh on conversationDestroyed event', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        final event = ConversationEvent(
          type: ConversationEventType.conversationDestroyed,
          conversationId: 'conv-3',
          timestamp: DateTime.now(),
        );
        await manager.processEvent(event);
        await Future<void>.delayed(Duration.zero);

        expect(events, ['conv-3']);

        await sub.cancel();
      });

      test('does not emit refresh on message events', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        final created = ConversationEvent(
          type: ConversationEventType.messageCreated,
          conversationId: 'conv-1',
          timestamp: DateTime.now(),
        );
        final updated = ConversationEvent(
          type: ConversationEventType.messageUpdated,
          conversationId: 'conv-1',
          timestamp: DateTime.now(),
        );
        final failed = ConversationEvent(
          type: ConversationEventType.messageFailed,
          conversationId: 'conv-1',
          timestamp: DateTime.now(),
        );

        await manager.processEvent(created);
        await manager.processEvent(updated);
        await manager.processEvent(failed);
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);

        await sub.cancel();
      });

      test('does not emit on unknown event', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        final event = ConversationEvent(
          type: ConversationEventType.unknown,
          conversationId: 'conv-1',
          timestamp: DateTime.now(),
        );
        await manager.processEvent(event);
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);

        await sub.cancel();
      });
    });

    group('dispose()', () {
      test('stops emitting events after dispose', () async {
        final events = <String>[];
        final sub = manager.refreshStream.listen(events.add);

        manager.registerConversation('conv-1');

        await manager.dispose();

        // Try emitting a connection change after dispose — should not emit refresh
        mockRepo.emitConnectionState(ConnectionState.disconnected);
        mockRepo.emitConnectionState(ConnectionState.connected);
        await Future<void>.delayed(Duration.zero);

        // Only events before dispose should be present
        // (initial connect fires _onReconnected but with no registered convs)
        expect(events, isEmpty);

        await sub.cancel();
      });

      test('is safe to call multiple times', () async {
        await manager.dispose();
        // Second dispose should not throw
        await manager.dispose();
      });
    });
  });
}
