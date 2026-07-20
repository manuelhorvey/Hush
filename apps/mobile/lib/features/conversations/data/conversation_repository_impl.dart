import 'dart:math';

import '../domain/conversation_repository.dart';
import '../models/conversation.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final Random _rng;

  ConversationRepositoryImpl({Random? random})
      : _rng = random ?? Random();

  static const _names = <String>[
    'Sarah', 'Alex', 'Jordan', 'Taylor', 'Morgan',
    'Riley', 'Avery', 'Quinn', 'Harper', 'Casey',
    'Reese', 'Skyler', 'Emerson', 'Finley', 'Rowan',
  ];

  @override
  Future<List<Conversation>> listConversations() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return generateMockData();
  }

  @override
  Conversation generateMockConversation({ConversationLifecycle? lifecycle}) {
    final cycle = lifecycle ??
        ConversationLifecycle.values[_rng.nextInt(ConversationLifecycle.values.length)];
    final name = _names[_rng.nextInt(_names.length)];
    final now = DateTime.now();
    final createdAgo = switch (cycle) {
      ConversationLifecycle.active => Duration(hours: _rng.nextInt(48) + 1),
      ConversationLifecycle.waiting => Duration(hours: _rng.nextInt(24) + 1),
      ConversationLifecycle.completing => Duration(hours: _rng.nextInt(12) + 1),
      ConversationLifecycle.closed => Duration(days: _rng.nextInt(7) + 1),
      ConversationLifecycle.warning => Duration(hours: _rng.nextInt(72) + 1),
    };

    return Conversation(
      id: 'conv-${_rng.nextInt(99999)}',
      participants: [
        ConversationParticipant(
          id: 'user-${_rng.nextInt(9999)}',
          displayName: name,
        ),
      ],
      lifecycle: cycle,
      createdAt: now.subtract(createdAgo),
      completedAt: cycle == ConversationLifecycle.closed
          ? now.subtract(Duration(hours: _rng.nextInt(24)))
          : null,
      isVerified: _rng.nextBool(),
    );
  }

  @override
  List<Conversation> generateMockData() {
    return [
      Conversation(
        id: 'conv-1',
        participants: [
          const ConversationParticipant(id: 'user-1', displayName: 'Sarah'),
        ],
        lifecycle: ConversationLifecycle.active,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isVerified: true,
      ),
      Conversation(
        id: 'conv-2',
        participants: [
          const ConversationParticipant(id: 'user-2', displayName: 'Jordan'),
        ],
        lifecycle: ConversationLifecycle.waiting,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isVerified: false,
      ),
      Conversation(
        id: 'conv-3',
        participants: [
          const ConversationParticipant(id: 'user-3', displayName: 'Taylor'),
        ],
        lifecycle: ConversationLifecycle.completing,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        isVerified: true,
      ),
      Conversation(
        id: 'conv-4',
        participants: [
          const ConversationParticipant(id: 'user-4', displayName: 'Morgan'),
        ],
        lifecycle: ConversationLifecycle.closed,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        completedAt: DateTime.now().subtract(const Duration(hours: 6)),
        isVerified: true,
      ),
      Conversation(
        id: 'conv-5',
        participants: [
          const ConversationParticipant(id: 'user-5', displayName: 'Reese'),
        ],
        lifecycle: ConversationLifecycle.closed,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
        isVerified: false,
      ),
      Conversation(
        id: 'conv-6',
        participants: [
          const ConversationParticipant(id: 'user-6', displayName: 'Alex'),
        ],
        lifecycle: ConversationLifecycle.warning,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        isVerified: false,
      ),
    ];
  }
}
