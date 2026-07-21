import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kReleaseMode) {
      debugPrint('[HTTP] --> ${options.method} ${options.uri}');
      if (options.data != null) {
        debugPrint('[HTTP] Body: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!kReleaseMode) {
      debugPrint(
          '[HTTP] <-- ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kReleaseMode) {
      debugPrint(
          '[HTTP] ERROR ${err.response?.statusCode} ${err.requestOptions.uri}');
      debugPrint('[HTTP] ${err.message}');
    }
    handler.next(err);
  }
}
