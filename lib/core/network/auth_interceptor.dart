import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../security/secure_token_store.dart';
import 'api_exception.dart';

/// Auth interceptor implementing the dual-token JWT refresh scheme.
/// Uses a queue to prevent race conditions when multiple requests
/// simultaneously trigger a 401.
class AuthInterceptor extends QueuedInterceptorsWrapper {
  final SecureTokenStore _tokenStore;
  final Dio _dio; // The same Dio instance (for retry after refresh)

  AuthInterceptor({
    required SecureTokenStore tokenStore,
    required Dio dio,
  })  : _tokenStore = tokenStore,
        _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStore.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Do NOT attempt a token refresh when the failing request IS the login
      // or signup endpoint — those 401s mean wrong credentials, not an expired
      // session. Attempting a refresh here causes a confusing "session expired"
      // error message instead of the real "invalid credentials" one.
      final path = err.requestOptions.path;
      final isAuthEndpoint = path.endsWith(ApiEndpoints.login) ||
          path.endsWith(ApiEndpoints.signup);

      if (!isAuthEndpoint) {
        try {
          final newTokens = await _refreshTokens();
          // Retry the original request with the new access token
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer ${newTokens.$1}';
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {
          // Refresh failed — clear tokens so router redirects to login
          await _tokenStore.clearTokens();
          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const AuthException(
                message: 'Session expired. Please log in again.',
                code: 'session_expired',
              ),
            ),
          );
        }
      }
    }
    handler.next(err);
  }

  Future<(String, String)> _refreshTokens() async {
    final refreshToken = await _tokenStore.getRefreshToken();
    if (refreshToken == null) {
      throw const AuthException(
        message: 'No refresh token available',
        code: 'no_refresh_token',
      );
    }

    // Use a bare Dio (no interceptors) to avoid infinite loop
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final response = await refreshDio.post(
      ApiEndpoints.refresh,
      data: {'refreshToken': refreshToken},
    );

    final accessToken = response.data['accessToken'] as String;
    final newRefreshToken = response.data['refreshToken'] as String;

    await _tokenStore.saveTokens(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
    );

    return (accessToken, newRefreshToken);
  }
}
