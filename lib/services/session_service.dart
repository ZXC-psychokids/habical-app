import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionTokens {
  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

abstract class SessionStorage {
  Future<SessionTokens?> loadTokens();

  Future<void> saveTokens(SessionTokens tokens);

  Future<void> clearTokens();
}

class SharedPreferencesSessionStorage implements SessionStorage {
  static const _accessTokenKey = 'session_access_token';
  static const _refreshTokenKey = 'session_refresh_token';

  @override
  Future<SessionTokens?> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    final refreshToken = prefs.getString(_refreshTokenKey);

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return SessionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> saveTokens(SessionTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, tokens.accessToken);
    await prefs.setString(_refreshTokenKey, tokens.refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}

class SessionService extends ChangeNotifier {
  SessionService({
    required SessionStorage storage,
  }) : _storage = storage;

  final SessionStorage _storage;

  SessionTokens? _tokens;
  bool _restored = false;

  bool get isRestored => _restored;

  bool get isAuthenticated => _tokens != null;

  String? get accessToken => _tokens?.accessToken;

  String? get refreshToken => _tokens?.refreshToken;

  Future<void> restore() async {
    if (_restored) {
      return;
    }
    _tokens = await _storage.loadTokens();
    _restored = true;
    notifyListeners();
  }

  Future<void> setTokens(SessionTokens tokens) async {
    _tokens = tokens;
    await _storage.saveTokens(tokens);
    notifyListeners();
  }

  Future<void> clear() async {
    _tokens = null;
    await _storage.clearTokens();
    notifyListeners();
  }
}
