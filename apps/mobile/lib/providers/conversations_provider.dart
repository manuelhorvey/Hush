import 'package:flutter/foundation.dart';
import '../services/messaging_service.dart';

class ConversationsProvider extends ChangeNotifier {
  final MessagingService _messaging;

  List<ConversationInfo> _conversations = [];
  bool _loading = false;

  ConversationsProvider({required this._messaging});

  List<ConversationInfo> get conversations => _conversations;
  bool get loading => _loading;

  Future<void> load(String token) async {
    _loading = true;
    notifyListeners();

    try {
      _conversations = await _messaging.listConversations(token);
    } catch (_) {
      _conversations = [];
    }

    _loading = false;
    notifyListeners();
  }

  Future<ConversationInfo> create(
    String token,
    List<String> participantIds, {
    Map<String, String>? encryptedKeys,
  }) async {
    final conv = await _messaging.createConversation(
      token,
      participantIds,
      encryptedKeys: encryptedKeys,
    );
    _conversations.insert(0, conv);
    notifyListeners();
    return conv;
  }

  Future<ConversationInfo> complete(String token, String id) async {
    final conv = await _messaging.completeConversation(token, id);
    final i = _conversations.indexWhere((c) => c.id == id);
    if (i != -1) {
      _conversations[i] = conv;
      notifyListeners();
    }
    return conv;
  }

  Future<void> destroy(String token, String id) async {
    await _messaging.destroyConversation(token, id);
    _conversations.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
