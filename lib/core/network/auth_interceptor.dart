import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches the Bearer token and transparently recovers from an expired one.
///
/// Access tokens live 15 minutes; refresh tokens are single-use and rotate on
/// every refresh. Two consequences shape this class:
///  * concurrent 401s must share ONE refresh — a second refresh with the same
///    (already rotated) token would fail and sign the user out;
///  * a request that 401'd with an older token than the one now stored was
///    simply overtaken by another request's refresh — retry, don't refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage storage,
    required Dio refreshClient,
    required this.onSessionExpired,
  })  : _storage = storage,
        _refreshClient = refreshClient;

  final TokenStorage _storage;

  /// A bare Dio (no interceptors) so the refresh call can't recurse into here.
  final Dio _refreshClient;

  /// Called once the session is unrecoverable (refresh token rejected).
  final void Function() onSessionExpired;

  /// The retrying client; set right after the owning Dio is constructed.
  late Dio client;

  Future<AuthTokens?>? _inFlightRefresh;

  static const skipAuthKey = 'skipAuth';
  static const _retriedKey = 'authRetried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final tokens = await _storage.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final eligible = err.response?.statusCode == 401 &&
        options.extra[skipAuthKey] != true &&
        options.extra[_retriedKey] != true &&
        options.headers['Authorization'] != null;
    if (!eligible) return handler.next(err);

    final sentToken =
        (options.headers['Authorization'] as String).replaceFirst('Bearer ', '');

    AuthTokens? fresh;
    try {
      final current = await _storage.read();
      if (current != null && current.accessToken != sentToken) {
        fresh = current; // someone else already refreshed
      } else {
        fresh = await _refreshOnce();
      }
    } on DioException catch (e) {
      // Network failure while refreshing: keep the session, surface the error.
      return handler.next(e);
    }

    if (fresh == null) {
      onSessionExpired();
      return handler.next(err);
    }

    try {
      options.headers['Authorization'] = 'Bearer ${fresh.accessToken}';
      options.extra[_retriedKey] = true;
      final response = await client.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<AuthTokens?> _refreshOnce() {
    return _inFlightRefresh ??=
        _refresh().whenComplete(() => _inFlightRefresh = null);
  }

  Future<AuthTokens?> _refresh() async {
    final current = await _storage.read();
    if (current == null) return null;
    try {
      final res = await _refreshClient.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refreshToken': current.refreshToken},
      );
      final data = res.data!;
      final tokens = AuthTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      await _storage.save(tokens);
      return tokens;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await _storage.clear();
        return null;
      }
      rethrow;
    }
  }
}
