import 'package:dio/dio.dart';

import '../services/session_service.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    SessionService? sessionService,
  }) : _sessionService = sessionService,
       dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? 'http://127.0.0.1:4010',
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
}
