import '../domain/conversation_detail_repository.dart';
import '../models/message.dart';

class ConversationDetailRepositoryImpl
    implements ConversationDetailRepository {
  final Map<String, List<Message>> _messageStore = {};
  final Map<String, String> _statusStore = {};
  int _nextId = 1;

  ConversationDetailRepositoryImpl() {
    _seedMessages();
  }

  String get _nextIdStr => 'msg_${_nextId++}';

  void _seedMessages() {
    final now = DateTime.now();

    // Conversation 1: active conversation with Sarah
    _messageStore['conv_1'] = [
      Message(
        id: _nextIdStr,
        senderId: 'user_2',
        senderName: 'Sarah',
        content: 'Hey! Are you free to talk about the project?',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Message(
        id: _nextIdStr,
        senderId: 'user_1',
        senderName: 'You',
        content: 'Sure, what\'s on your mind?',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 55)),
      ),
      Message(
        id: _nextIdStr,
        senderId: 'user_2',
        senderName: 'Sarah',
        content:
            'I\'ve been thinking about the design direction. The privacy features are really coming together nicely.',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 48)),
      ),
      Message(
        id: _nextIdStr,
        senderId: 'user_1',
        senderName: 'You',
        content: 'I agree. The calm design language fits perfectly with our goals.',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
      ),
      Message(
        id: _nextIdStr,
        senderId: 'user_2',
        senderName: 'Sarah',
        content: 'Should we schedule a review for next week?',
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
    ];
    _statusStore['conv_1'] = 'active';

    // Conversation 2: completed conversation with Alex
    final yesterday = now.subtract(const Duration(days: 1));
    _messageStore['conv_2'] = [
      Message(
        id: _nextIdStr,
        senderId: 'user_3',
        senderName: 'Alex',
        content: 'Thanks for the great conversation yesterday.',
        createdAt: yesterday.subtract(const Duration(hours: 4)),
      ),
      Message(
        id: _nextIdStr,
        senderId: 'user_1',
        senderName: 'You',
        content: 'Of course! Let me know if you need anything else.',
        createdAt: yesterday.subtract(const Duration(hours: 3, minutes: 45)),
      ),
      Message(
        id: _nextIdStr,
        senderId: 'user_3',
        senderName: 'Alex',
        content: 'Will do. Take care!',
        createdAt: yesterday.subtract(const Duration(hours: 3, minutes: 40)),
      ),
    ];
    _statusStore['conv_2'] = 'completed';

    // Conversation 3: older conversation with Jordan
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    _messageStore['conv_3'] = [
      Message(
        id: _nextIdStr,
        senderId: 'user_4',
        senderName: 'Jordan',
        content: 'Hey, check this out — found a great article on privacy-first design.',
        createdAt: twoDaysAgo.subtract(const Duration(hours: 6)),
      ),
      Message(
        id: _nextIdStr,
        senderId: 'user_1',
        senderName: 'You',
        content: 'Looks interesting! I\'ll give it a read.',
        createdAt: twoDaysAgo.subtract(const Duration(hours: 5, minutes: 30)),
      ),
    ];
    _statusStore['conv_3'] = 'active';

    // Conversation 4: multi-participant conversation
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    _messageStore['conv_4'] = [
      Message(
        id: _nextIdStr,
        senderId: 'user_5',
        senderName: 'Morgan',
        content: 'Team, let\'s finalize the timeline this week.',
        createdAt: threeDaysAgo.subtract(const Duration(hours: 8)),
      ),
      Message(
        id: _nextIdStr,
        senderId: 'user_6',
        senderName: 'Casey',
        content: 'Works for me. I\'ll have my section ready by Thursday.',
        createdAt: threeDaysAgo.subtract(const Duration(hours: 7, minutes: 45)),
      ),
      Message(
        id: _nextIdStr,
        senderId: 'user_1',
        senderName: 'You',
        content: 'Same here. Let\'s set a review for Friday.',
        createdAt: threeDaysAgo.subtract(const Duration(hours: 7, minutes: 30)),
      ),
    ];
    _statusStore['conv_4'] = 'active';
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _messageStore[conversationId] ?? [];
  }

  @override
  Future<bool> sendMessage(String conversationId, String content) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final messages = _messageStore.putIfAbsent(conversationId, () => []);

    final message = Message(
      id: _nextIdStr,
      senderId: 'user_1',
      senderName: 'You',
      content: content,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );
    messages.add(message);
    return true;
  }

  @override
  Future<bool> completeConversation(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _statusStore[conversationId] = 'completed';
    return true;
  }

  @override
  Future<bool> destroyConversation(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _messageStore.remove(conversationId);
    _statusStore[conversationId] = 'destroyed';
    return true;
  }

  @override
  String getStatus(String conversationId) {
    return _statusStore[conversationId] ?? 'active';
  }
}
