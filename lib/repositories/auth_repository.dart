import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/app_logger.dart';
import '../services/session_service.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SessionService sessionService,
  }) : _apiClient = apiClient,
       _sessionService = sessionService;

  final ApiClient _apiClient;
  final SessionService _sessionService;

  Future<void> login({
    required String login,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/login',
      data: {
        'login': login.trim(),
        'password': password,
      },
    );
    final tokens = _extractTokens(response.data);
    await _sessionService.setTokens(tokens);
  }

  Future<void> register({
    required String email,
    required String handle,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/register',
      data: {
        'email': email.trim(),
        'handle': handle.trim(),
        'password': password,
        'passwordConfirmation': passwordConfirmation,
      },
    );
    final tokens = _extractTokens(response.data);
    await _sessionService.setTokens(tokens);
  }

  Future<void> refresh() async {
    final refreshToken = _sessionService.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      AppLogger.e(
        'AuthRepository.refresh failed: no refresh token in session',
        StateError('No refresh token in session.'),
        StackTrace.current,
      );
      throw StateError('No refresh token in session.');
    }

    final response = await _apiClient.dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(headers: {'Authorization': null}),
    );
    final tokens = _extractTokenPair(response.data);
    await _sessionService.setTokens(tokens);
  }

  Future<void> logout() async {
    final refreshToken = _sessionService.refreshToken;
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.dio.post(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } finally {
      await _sessionService.clear();
    }
  }

  Future<void> requestPasswordReset({
    required String email,
  }) async {
    await _apiClient.dio.post(
      '/auth/password-reset/request',
      data: {'email': email.trim()},
      options: Options(headers: {'Authorization': null}),
    );
  }

  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _apiClient.dio.post(
      '/auth/password-reset/confirm',
      data: {
        'token': token.trim(),
        'newPassword': newPassword,
        'newPasswordConfirmation': newPasswordConfirmation,
      },
      options: Options(headers: {'Authorization': null}),
    );
  }

  Future<Map<String, dynamic>> fetchMe() async {
    final response = await _apiClient.dio.get('/me');
    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'AuthRepository.fetchMe failed: invalid /me payload',
        StateError('Invalid /me payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid /me payload.');
    }
    return Map<String, dynamic>.from(raw);
  }

  SessionTokens _extractTokens(dynamic data) {
    if (data is! Map) {
      AppLogger.e(
        'AuthRepository._extractTokens failed: invalid auth payload',
        StateError('Invalid auth payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid auth payload.');
    }

    final map = Map<String, dynamic>.from(data);
    final rawTokens = map['tokens'];
    if (rawTokens is! Map) {
      AppLogger.e(
        'AuthRepository._extractTokens failed: response has no tokens',
        StateError('Auth response does not contain tokens.'),
        StackTrace.current,
      );
      throw StateError('Auth response does not contain tokens.');
    }

    return _extractTokenPair(rawTokens);
  }

  SessionTokens _extractTokenPair(dynamic data) {
    if (data is! Map) {
      AppLogger.e(
        'AuthRepository._extractTokenPair failed: invalid token payload',
        StateError('Invalid token payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid token payload.');
    }

    final map = Map<String, dynamic>.from(data);
    final accessToken = map['accessToken'];
    final refreshToken = map['refreshToken'];
    if (accessToken is! String || accessToken.isEmpty) {
      AppLogger.e(
        'AuthRepository._extractTokenPair failed: invalid access token',
        StateError('Invalid access token.'),
        StackTrace.current,
      );
      throw StateError('Invalid access token.');
    }
    if (refreshToken is! String || refreshToken.isEmpty) {
      AppLogger.e(
        'AuthRepository._extractTokenPair failed: invalid refresh token',
        StateError('Invalid refresh token.'),
        StackTrace.current,
      );
      throw StateError('Invalid refresh token.');
    }

    return SessionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
