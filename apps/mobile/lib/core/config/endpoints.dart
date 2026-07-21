class ApiEndpoints {
  ApiEndpoints._();

  static const String apiPrefix = '/api/v1';

  // Auth
  static const String register = '$apiPrefix/auth/register';
  static const String login = '$apiPrefix/auth/login';
  static const String session = '$apiPrefix/auth/session';
  static const String refreshToken = '$apiPrefix/auth/refresh';
  static const String logout = '$apiPrefix/auth/logout';

  // Identity
  static const String identity = '$apiPrefix/identity';
  static String identityById(String userId) => '$apiPrefix/identity/$userId';
  static const String devices = '$apiPrefix/identity/devices';
  static String deviceById(String deviceId) =>
      '$apiPrefix/identity/devices/$deviceId';
  static const String exchangeKey = '$apiPrefix/identity/exchange-key';
  static String exchangeKeyForUser(String userId) =>
      '$apiPrefix/identity/$userId/exchange-key';
  static String challenge(String targetUserId) =>
      '$apiPrefix/identity/challenge/$targetUserId';
  static String verifyChallenge(String challengeId) =>
      '$apiPrefix/identity/challenge/$challengeId/verify';

  // Conversations
  static const String conversations = '$apiPrefix/conversations';
  static String conversationById(String id) =>
      '$apiPrefix/conversations/$id';
  static String completeConversation(String id) =>
      '$apiPrefix/conversations/$id/complete';
  static const String conversationKey = '$apiPrefix/conversations/key';
  static String conversationKeyById(String id) =>
      '$apiPrefix/conversations/$id/key';
  static String conversationParticipants(String id) =>
      '$apiPrefix/conversations/$id/participants';

  // Messages
  static String messages(String conversationId) =>
      '$apiPrefix/conversations/$conversationId/messages';
  static String messageById(String conversationId, String messageId) =>
      '$apiPrefix/conversations/$conversationId/messages/$messageId';

  // Users
  static const String searchUsers = '$apiPrefix/users/search';
}
