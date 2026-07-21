import 'package:dio/dio.dart';

import '../network_errors.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final networkError = _mapToNetworkError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: networkError,
        message: networkError.message,
      ),
    );
  }

  NetworkException _mapToNetworkError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return TimeoutException(originalError: err);
    }

    if (err.type == DioExceptionType.connectionError) {
      return NetworkConnectionException(originalError: err);
    }

    final statusCode = err.response?.statusCode;
    if (statusCode != null) {
      final message = _extractMessage(err.response?.data);

      switch (statusCode) {
        case 400:
          return BadRequestException(message: message, originalError: err);
        case 401:
          return UnauthorizedException(message: message, originalError: err);
        case 403:
          return ForbiddenException(message: message, originalError: err);
        case 404:
          return NotFoundException(message: message, originalError: err);
        case 409:
          return ConflictException(message: message, originalError: err);
        case 422:
          return BadRequestException(message: message, originalError: err);
        default:
          if (statusCode >= 500) {
            return ServerErrorException(message: message, originalError: err);
          }
      }
    }

    return UnknownNetworkException(
      message: err.message ?? 'Unknown error',
      originalError: err,
    );
  }

  String _extractMessage(dynamic data) {
    if (data is Map) {
      return (data['error'] as String?) ??
          (data['message'] as String?) ??
          'Unknown error';
    }
    return 'Unknown error';
  }
}
