import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

typedef Json = Map<String, dynamic>;

/// Thin wrapper over Dio: one place for base URL, timeouts, auth and error
/// mapping. Repositories call the verb helpers and get decoded JSON back or an
/// [ApiException] thrown — never a raw [DioException].
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required void Function() onSessionExpired,
    String? baseUrl,
    @visibleForTesting HttpClientAdapter? adapter,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
      responseType: ResponseType.json,
    );
    _dio = Dio(options);
    final refreshClient = Dio(options);
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
      refreshClient.httpClientAdapter = adapter;
    }
    final auth = AuthInterceptor(
      storage: tokenStorage,
      refreshClient: refreshClient,
      onSessionExpired: onSessionExpired,
    )..client = _dio;
    _dio.interceptors.add(auth);
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => debugPrint('[api] $o'),
      ));
    }
  }

  late final Dio _dio;

  /// Raw Dio for the rare call that needs it (e.g. uploads to a presigned
  /// URL on another host — see [putBytesToUrl]).
  Dio get dio => _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<T>(path, queryParameters: _clean(query)));

  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? query}) =>
      _send(() => _dio.post<T>(path, data: body, queryParameters: _clean(query)));

  Future<T> put<T>(String path, {Object? body}) =>
      _send(() => _dio.put<T>(path, data: body));

  Future<T> patch<T>(String path, {Object? body}) =>
      _send(() => _dio.patch<T>(path, data: body));

  Future<T> delete<T>(String path, {Object? body}) =>
      _send(() => _dio.delete<T>(path, data: body));

  /// Unauthenticated POST (login/signup/password reset): no Bearer header, and
  /// a 401 here means "wrong credentials", not "refresh the session".
  Future<T> postPublic<T>(String path, {Object? body}) => _send(
        () => _dio.post<T>(
          path,
          data: body,
          options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
        ),
      );

  /// multipart/form-data upload through the API (profile/group/page images —
  /// the only binary the Worker accepts). Dio sets the boundary itself.
  Future<Json> uploadFile(
    String path, {
    required File file,
    String field = 'file',
    void Function(double progress)? onProgress,
  }) {
    return _send(() async {
      final form = FormData.fromMap({
        field: await MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
      });
      return _dio.post<Json>(
        path,
        data: form,
        onSendProgress: onProgress == null
            ? null
            : (sent, total) => total > 0 ? onProgress(sent / total) : null,
      );
    });
  }

  /// PUT raw bytes to a presigned URL (R2 direct upload). A fresh Dio: the
  /// presigned URL carries its own auth and must not get our Bearer header.
  Future<void> putBytesToUrl(
    String url, {
    required File file,
    required Map<String, String> headers,
    void Function(double progress)? onProgress,
  }) async {
    final length = await file.length();
    try {
      await Dio().put<void>(
        url,
        data: file.openRead(),
        options: Options(
          headers: {...headers, Headers.contentLengthHeader: length},
          sendTimeout: const Duration(minutes: 5),
        ),
        onSendProgress: onProgress == null
            ? null
            : (sent, total) => onProgress(sent / (total > 0 ? total : length)),
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// multipart POST to a third-party upload URL (Cloudflare Stream direct
  /// creator upload). Fresh Dio for the same reason as [putBytesToUrl].
  Future<void> postMultipartToUrl(
    String url, {
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      await Dio().post<void>(
        url,
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.uri.pathSegments.last,
          ),
        }),
        options: Options(sendTimeout: const Duration(minutes: 15)),
        onSendProgress: onProgress == null
            ? null
            : (sent, total) => total > 0 ? onProgress(sent / total) : null,
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<T> _send<T>(Future<Response<T>> Function() call) async {
    try {
      final res = await call();
      return res.data as T;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    return Map.fromEntries(query.entries.where((e) => e.value != null));
  }

  ApiException _map(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    final response = e.response;
    if (response == null) return ApiException.network;
    final data = response.data;
    String? code;
    String? message;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      code = error['code'] as String?;
      message = error['message'] as String?;
    }
    return ApiException(
      statusCode: response.statusCode,
      code: code,
      message: message ?? 'Request failed (${response.statusCode}).',
    );
  }
}
