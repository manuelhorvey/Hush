import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/config/endpoints.dart';

void main() {
  group('ApiEndpoints', () {
    test('auth endpoints are correct', () {
      expect(ApiEndpoints.register, '/api/v1/auth/register');
      expect(ApiEndpoints.login, '/api/v1/auth/login');
      expect(ApiEndpoints.refreshToken, '/api/v1/auth/refresh');
      expect(ApiEndpoints.logout, '/api/v1/auth/logout');
    });

    test('identity endpoints with parameters', () {
      expect(ApiEndpoints.identityById('user-1'), '/api/v1/identity/user-1');
      expect(ApiEndpoints.deviceById('dev-1'),
          '/api/v1/identity/devices/dev-1');
      expect(ApiEndpoints.exchangeKeyForUser('user-1'),
          '/api/v1/identity/user-1/exchange-key');
      expect(ApiEndpoints.challenge('user-2'),
          '/api/v1/identity/challenge/user-2');
      expect(ApiEndpoints.verifyChallenge('ch-1'),
          '/api/v1/identity/challenge/ch-1/verify');
    });

    test('conversation endpoints with parameters', () {
      expect(ApiEndpoints.conversationById('conv-1'),
          '/api/v1/conversations/conv-1');
      expect(ApiEndpoints.completeConversation('conv-1'),
          '/api/v1/conversations/conv-1/complete');
      expect(ApiEndpoints.conversationKeyById('conv-1'),
          '/api/v1/conversations/conv-1/key');
      expect(ApiEndpoints.conversationParticipants('conv-1'),
          '/api/v1/conversations/conv-1/participants');
    });

    test('message endpoints with parameters', () {
      expect(ApiEndpoints.messages('conv-1'),
          '/api/v1/conversations/conv-1/messages');
      expect(ApiEndpoints.messageById('conv-1', 'msg-1'),
          '/api/v1/conversations/conv-1/messages/msg-1');
    });

    test('user endpoints are correct', () {
      expect(ApiEndpoints.searchUsers, '/api/v1/users/search');
    });
  });
}
