import 'package:dio/dio.dart';

const _defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:4010',
);

class ApiClient {
  ApiClient({String? baseUrl})
    : _baseUrl = baseUrl ?? _defaultApiBaseUrl,
      dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? _defaultApiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ),
      _authDio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? _defaultApiBaseUrl,
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
          if (_accessToken != null && _accessToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (_shouldRefresh(error)) {
            final refreshed = await _refreshSession();
            if (refreshed) {
              final requestOptions = error.requestOptions;
              final retryOptions = Options(
                method: requestOptions.method,
                headers: Map<String, dynamic>.from(requestOptions.headers),
                contentType: requestOptions.contentType,
                responseType: requestOptions.responseType,
              );
              retryOptions.headers?['Authorization'] = 'Bearer $_accessToken';

              try {
                final response = await dio.request<dynamic>(
                  requestOptions.path,
                  data: requestOptions.data,
                  queryParameters: requestOptions.queryParameters,
                  options: retryOptions,
                );
                handler.resolve(response);
                return;
              } catch (_) {
                // ignore and continue with original error handling
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final String _baseUrl;
  final Dio dio;
  final Dio _authDio;

  String? _accessToken;
  String? _refreshToken;
  String? _currentUserId;

  String? get currentUserId => _currentUserId;

  bool isCurrentUser(String userId) {
    return _currentUserId != null && _currentUserId == userId;
  }

  void setSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _currentUserId = userId;
  }

  void clearSession() {
    _accessToken = null;
    _refreshToken = null;
    _currentUserId = null;
  }

  bool _shouldRefresh(DioException error) {
    return error.response?.statusCode == 401 &&
        _refreshToken != null &&
        _refreshToken!.isNotEmpty &&
        !error.requestOptions.path.contains('/auth/refresh') &&
        !error.requestOptions.path.contains('/auth/login') &&
        !error.requestOptions.path.contains('/auth/register');
  }

  Future<bool> _refreshSession() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _authDio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );
      final data = response.data;
      if (data is! Map) {
        return false;
      }
      final map = Map<String, dynamic>.from(data);
      final nextAccess = map['accessToken'] as String?;
      final nextRefresh = map['refreshToken'] as String?;
      if (nextAccess == null || nextRefresh == null) {
        return false;
      }
      _accessToken = nextAccess;
      _refreshToken = nextRefresh;
      return true;
    } catch (_) {
      clearSession();
      return false;
    }
  }

  Dio createRawClient() {
    return Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
