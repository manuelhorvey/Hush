import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/network/network_errors.dart';

void main() {
  group('NetworkException', () {
    group('userFacingMessage', () {
      test('UnauthorizedException returns session expired message', () {
        const err = UnauthorizedException();
        expect(err.userFacingMessage,
            'Your session has expired. Please sign in again.');
      });

      test('ForbiddenException returns permission message', () {
        const err = ForbiddenException();
        expect(err.userFacingMessage,
            "You don't have permission to perform this action.");
      });

      test('NotFoundException returns not found message', () {
        const err = NotFoundException();
        expect(err.userFacingMessage,
            'The requested resource was not found.');
      });

      test('ServerErrorException returns server error message', () {
        const err = ServerErrorException();
        expect(err.userFacingMessage,
            'Something went wrong on our end. Please try again.');
      });

      test('TimeoutException returns timeout message', () {
        const err = TimeoutException();
        expect(err.userFacingMessage,
            'The request timed out. Please check your connection.');
      });

      test('NetworkConnectionException returns connection message', () {
        const err = NetworkConnectionException();
        expect(err.userFacingMessage,
            'Unable to connect. Please check your internet connection.');
      });

      test('BadRequestException returns the error message', () {
        const err =
            BadRequestException(message: 'Invalid input');
        expect(err.userFacingMessage, 'Invalid input');
      });

      test('UnknownNetworkException returns generic message', () {
        const err = UnknownNetworkException(message: 'unknown');
        expect(err.userFacingMessage,
            'An unexpected error occurred. Please try again.');
      });
    });

    group('statusCode', () {
      test('BadRequestException has 400', () {
        expect(const BadRequestException().statusCode, 400);
      });

      test('UnauthorizedException has 401', () {
        expect(const UnauthorizedException().statusCode, 401);
      });

      test('ForbiddenException has 403', () {
        expect(const ForbiddenException().statusCode, 403);
      });

      test('NotFoundException has 404', () {
        expect(const NotFoundException().statusCode, 404);
      });

      test('ConflictException has 409', () {
        expect(const ConflictException().statusCode, 409);
      });

      test('ServerErrorException has 500', () {
        expect(const ServerErrorException().statusCode, 500);
      });

      test('TimeoutException has null statusCode', () {
        expect(const TimeoutException().statusCode, isNull);
      });
    });

    group('toString', () {
      test('returns message', () {
        const err = NotFoundException(message: 'User not found');
        expect(err.toString(), 'User not found');
      });
    });
  });
}
