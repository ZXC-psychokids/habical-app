import 'package:dio/dio.dart';

import '../core/api_client.dart';

class ApiSessionBootstrapper {
  ApiSessionBootstrapper({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const _demoEmail = 'demo@habical.local';
  static const _demoHandle = 'demo_user';
  static const _demoPassword = 'DemoPassword123!';

  Future<String> ensureSession() async {
    final raw = _apiClient.createRawClient();

    try {
      final loginResponse = await raw.post(
        '/auth/login',
        data: {
          'login': _demoEmail,
          'password': _demoPassword,
        },
      );
      return _saveSessionFromAuthResponse(loginResponse);
    } on DioException catch (error) {
      if (error.response?.statusCode != 401 &&
          error.response?.statusCode != 400) {
        rethrow;
      }
    }

    try {
      final registerResponse = await raw.post(
        '/auth/register',
        data: {
          'email': _demoEmail,
          'handle': _demoHandle,
          'password': _demoPassword,
          'passwordConfirmation': _demoPassword,
        },
      );
      return _saveSessionFromAuthResponse(registerResponse);
    } on DioException catch (error) {
      if (error.response?.statusCode != 409) {
        rethrow;
      }
    }

    final loginAfterConflict = await raw.post(
      '/auth/login',
      data: {
        'login': _demoEmail,
        'password': _demoPassword,
      },
    );
    return _saveSessionFromAuthResponse(loginAfterConflict);
  }

  String _saveSessionFromAuthResponse(Response<dynamic> response) {
    final raw = response.data;
    if (raw is! Map) {
      throw StateError('Некорректный ответ auth.');
    }
    final map = Map<String, dynamic>.from(raw);
    final user = Map<String, dynamic>.from(map['user'] as Map);
    final tokens = Map<String, dynamic>.from(map['tokens'] as Map);
    final userId = user['id'] as String;
    final accessToken = tokens['accessToken'] as String;
    final refreshToken = tokens['refreshToken'] as String;
    _apiClient.setSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
    return userId;
  }
}
