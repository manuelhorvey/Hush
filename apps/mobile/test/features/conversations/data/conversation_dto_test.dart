import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/conversations/data/models/conversation_dto.dart';
import 'package:hush_mobile/features/conversations/data/models/message_dto.dart';

void main() {
  group('ConversationDto', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'conv-1',
        'participants': [
          {'user_id': 'user-1', 'username': 'Alice'},
          {'user_id': 'user-2', 'username': 'Bob'},
        ],
        'status': 'active',
        'expires_at': '2026-12-31T23:59:59Z',
        'created_at': '2026-01-01T00:00:00Z',
        'is_verified': true,
      };

      final dto = ConversationDto.fromJson(json);

      expect(dto.id, 'conv-1');
      expect(dto.participants, hasLength(2));
      expect(dto.participants[0].userId, 'user-1');
      expect(dto.participants[0].username, 'Alice');
      expect(dto.participants[1].userId, 'user-2');
      expect(dto.status, 'active');
      expect(dto.expiresAt, '2026-12-31T23:59:59Z');
      expect(dto.isVerified, isTrue);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'conv-2',
        'participants': [],
        'status': null,
        'created_at': '2026-01-01T00:00:00Z',
      };

      final dto = ConversationDto.fromJson(json);

      expect(dto.id, 'conv-2');
      expect(dto.status, 'active');
      expect(dto.expiresAt, isNull);
      expect(dto.isVerified, isNull);
    });

    test('toJson produces correct output', () {
      final dto = ConversationDto(
        id: 'conv-1',
        participants: [
          ParticipantDto(userId: 'user-1', username: 'Alice'),
        ],
        status: 'active',
        createdAt: '2026-01-01T00:00:00Z',
        isVerified: true,
      );

      final json = dto.toJson();

      expect(json['id'], 'conv-1');
      expect(json['participants'], hasLength(1));
      expect(json['status'], 'active');
      expect(json['is_verified'], isTrue);
    });
  });

  group('MessageDto', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'msg-1',
        'sender_id': 'user-1',
        'ciphertext': 'base64encrypted',
        'created_at': '2026-01-01T00:00:00Z',
      };

      final dto = MessageDto.fromJson(json);

      expect(dto.id, 'msg-1');
      expect(dto.senderId, 'user-1');
      expect(dto.ciphertext, 'base64encrypted');
    });

    test('toJson produces correct output', () {
      final dto = MessageDto(
        id: 'msg-1',
        senderId: 'user-1',
        ciphertext: 'base64encrypted',
        createdAt: '2026-01-01T00:00:00Z',
      );

      final json = dto.toJson();

      expect(json['id'], 'msg-1');
      expect(json['sender_id'], 'user-1');
      expect(json['ciphertext'], 'base64encrypted');
    });
  });

  group('SendMessageRequest', () {
    test('toJson produces correct output', () {
      final request = SendMessageRequest(ciphertext: 'encrypted-data');
      expect(request.toJson(), {'ciphertext': 'encrypted-data'});
    });
  });
}
