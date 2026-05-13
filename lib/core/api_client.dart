import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'app_logger.dart';
import '../services/session_service.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    SessionService? sessionService,
  }) : _sessionService = sessionService,
       dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? _defaultBaseUrl(),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _sessionService?.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }

          AppLogger.i(
            'HTTP REQUEST ${options.method.toUpperCase()} ${options.uri}',
          );
          AppLogger.i(
            'query=${AppLogger.pretty(options.queryParameters)}',
          );
          AppLogger.i(
            'body=${AppLogger.pretty(options.data)}',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          final request = response.requestOptions;
          AppLogger.i(
            'HTTP RESPONSE ${request.method.toUpperCase()} ${request.uri}',
          );
          AppLogger.i('status=${response.statusCode}');
          AppLogger.i('body=${AppLogger.pretty(response.data)}');
          handler.next(response);
        },
        onError: (error, handler) {
          final request = error.requestOptions;
          AppLogger.e(
            'HTTP ERROR ${request.method.toUpperCase()} ${request.uri}\n'
            'type=${error.type}\n'
            'status=${error.response?.statusCode}\n'
            'response=${AppLogger.pretty(error.response?.data)}',
            error,
            error.stackTrace,
          );
          handler.next(error);
        },
      ),
    );
  }

  final SessionService? _sessionService;
  final Dio dio;

  static String _defaultBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv != '') {
      return fromEnv;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator uses host loopback via 10.0.2.2.
      return 'http://10.0.2.2:4010';
    }

    return 'http://127.0.0.1:4010';
  }
}
