import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
          handler.next(options);
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
