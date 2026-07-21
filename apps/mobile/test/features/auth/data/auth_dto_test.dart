import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/auth/data/models/auth_dto.dart';

void main() {
  group('AuthResponseDto', () {
    test('fromJson parses correctly', () {
      final json = {
        'token': 'jwt-token',
        'refresh_token': 'refresh-token',
        'user_id': 'user-1',
        'username': 'Alice',
      };

      final dto = AuthResponseDto.fromJson(json);

      expect(dto.token, 'jwt-token');
      expect(dto.refreshToken, 'refresh-token');
      expect(dto.userId, 'user-1');
      expect(dto.username, 'Alice');
    });

    test('fromJson handles missing refresh_token', () {
      final json = {
        'token': 'jwt-token',
        'user_id': 'user-1',
        'username': 'Alice',
      };

      final dto = AuthResponseDto.fromJson(json);

      expect(dto.refreshToken, '');
    });
  });

  group('RegisterRequest', () {
    test('toJson produces correct output', () {
      final request = RegisterRequest(
        username: 'Alice',
        publicKey: 'base64pubkey',
      );

      expect(request.toJson(), {
        'username': 'Alice',
        'public_key': 'base64pubkey',
      });
    });
  });

  group('LoginRequest', () {
    test('toJson produces correct output', () {
      final request = LoginRequest(username: 'Alice');
      expect(request.toJson(), {'username': 'Alice'});
    });
  });

  group('RefreshResponseDto', () {
    test('fromJson parses correctly', () {
      final json = {
        'token': 'new-jwt',
        'refresh_token': 'new-refresh',
      };

      final dto = RefreshResponseDto.fromJson(json);

      expect(dto.token, 'new-jwt');
      expect(dto.refreshToken, 'new-refresh');
    });
  });
}
