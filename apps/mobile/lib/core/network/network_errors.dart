sealed class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const NetworkException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;

  String get userFacingMessage {
    switch (this) {
      case UnauthorizedException():
        return 'Your session has expired. Please sign in again.';
      case ForbiddenException():
        return 'You don\'t have permission to perform this action.';
      case NotFoundException():
        return 'The requested resource was not found.';
      case ConflictException():
        return 'This action conflicts with the current state.';
      case ServerErrorException():
        return 'Something went wrong on our end. Please try again.';
      case TimeoutException():
        return 'The request timed out. Please check your connection.';
      case NetworkConnectionException():
        return 'Unable to connect. Please check your internet connection.';
      case BadRequestException():
        return message;
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

class BadRequestException extends NetworkException {
  const BadRequestException({
    super.message = 'Bad request',
    super.statusCode = 400,
    super.originalError,
  });
}

class UnauthorizedException extends NetworkException {
  const UnauthorizedException({
    super.message = 'Unauthorized',
    super.statusCode = 401,
    super.originalError,
  });
}

class ForbiddenException extends NetworkException {
  const ForbiddenException({
    super.message = 'Forbidden',
    super.statusCode = 403,
    super.originalError,
  });
}

class NotFoundException extends NetworkException {
  const NotFoundException({
    super.message = 'Not found',
    super.statusCode = 404,
    super.originalError,
  });
}

class ConflictException extends NetworkException {
  const ConflictException({
    super.message = 'Conflict',
    super.statusCode = 409,
    super.originalError,
  });
}

class ServerErrorException extends NetworkException {
  const ServerErrorException({
    super.message = 'Internal server error',
    super.statusCode = 500,
    super.originalError,
  });
}

class TimeoutException extends NetworkException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.originalError,
  });
}

class NetworkConnectionException extends NetworkException {
  const NetworkConnectionException({
    super.message = 'No internet connection',
    super.originalError,
  });
}

class UnknownNetworkException extends NetworkException {
  const UnknownNetworkException({
    required super.message,
    super.originalError,
  });
}
