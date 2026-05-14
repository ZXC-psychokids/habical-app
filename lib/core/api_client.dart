import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

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
          response.data = _normalizePayload(response.data);
          final request = response.requestOptions;
          AppLogger.i(
            'HTTP RESPONSE ${request.method.toUpperCase()} ${request.uri}',
          );
          AppLogger.i('status=${response.statusCode}');
          AppLogger.i('body=${AppLogger.pretty(response.data)}');
          handler.next(response);
        },
        onError: (error, handler) {
          final response = error.response;
          if (response != null) {
            response.data = _normalizePayload(response.data);
          }
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

  dynamic _normalizePayload(dynamic value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key, _normalizePayload(item)));
    }
    if (value is List) {
      return value.map(_normalizePayload).toList(growable: false);
    }
    if (value is String) {
      return _normalizeString(value);
    }
    return value;
  }

  String _normalizeString(String raw) {
    var current = raw;
    if (current.trim().isEmpty) {
      return raw;
    }

    for (var i = 0; i < 3; i++) {
      if (!_looksMojibake(current)) {
        break;
      }
      try {
        final decoded = utf8.decode(latin1.encode(current));
        if (decoded == current) {
          break;
        }
        current = decoded;
      } catch (_) {
        break;
      }
    }

    if (_looksMojibake(current)) {
      try {
        final bytes = current.codeUnits
            .map((unit) => unit & 0xFF)
            .toList(growable: false);
        final decoded = utf8.decode(bytes, allowMalformed: true);
        if (decoded.trim().isNotEmpty) {
          current = decoded;
        }
      } catch (_) {}
    }

    return current;
  }

  bool _looksMojibake(String text) {
    if (text.isEmpty) {
      return false;
    }
    final hasBrokenCyr = text.contains('Р') || text.contains('Ð') || text.contains('Ñ');
    final hasPairNoise = text.contains('С') || text.contains('Ѓ') || text.contains('Ў');
    return hasBrokenCyr && hasPairNoise;
  }

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
