import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static const Set<String> _sensitiveKeys = {
    'authorization',
    'access_token',
    'accesstoken',
    'refresh_token',
    'refreshtoken',
    'token',
    'password',
    'passwordconfirmation',
    'newpassword',
    'newpasswordconfirmation',
    'resetpasswordtoken',
  };

  static void i(String message) {
    _log('INFO', message);
  }

  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    _log('WARN', message, error, stackTrace);
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  static dynamic sanitize(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is MultipartFile) {
      return '***';
    }
    if (value is FormData) {
      return {
        'fields': value.fields
            .map((field) => {'key': field.key, 'value': _maskIfSensitive(field.key, field.value)})
            .toList(growable: false),
        'files': value.files
            .map((file) => {'key': file.key, 'value': '***'})
            .toList(growable: false),
      };
    }
    if (value is Map) {
      final result = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        result[key] = _maskIfSensitive(key, entry.value);
      }
      return result;
    }
    if (value is Iterable) {
      return value.map(sanitize).toList(growable: false);
    }
    return value;
  }

  static String pretty(dynamic value) {
    final sanitized = sanitize(value);
    try {
      return const JsonEncoder.withIndent('  ').convert(sanitized);
    } catch (_) {
      return sanitized.toString();
    }
  }

  static void _log(
    String level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[$level] $message');
    if (error != null) {
      debugPrint('error=$error');
    }
    if (stackTrace != null) {
      debugPrint('stack=$stackTrace');
    }
  }

  static dynamic _maskIfSensitive(String key, dynamic value) {
    final normalized = key.toLowerCase().replaceAll('_', '');
    if (_sensitiveKeys.contains(normalized)) {
      if (normalized == 'authorization') {
        return 'Bearer ***';
      }
      return '***';
    }
    return sanitize(value);
  }
}
