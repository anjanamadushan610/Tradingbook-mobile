import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../constants/api_endpoints.dart';
import '../security/secure_token_store.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';
import 'mock_interceptor.dart';

class DioClient {
  late final Dio _dio;

  DioClient({required SecureTokenStore tokenStore}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      MockInterceptor(),
      AuthInterceptor(tokenStore: tokenStore, dio: _dio),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[DioClient] $obj'),
      ),
    ]);
  }

  Dio get dio => _dio;

  // ===== Convenience Methods =====

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  ApiException _mapDioException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final errorBody = data is Map ? data['error'] : null;
    final message = errorBody?['message'] as String? ?? e.message ?? 'Unexpected error';
    final code = errorBody?['code'] as String?;

    switch (statusCode) {
      case 400:
        final issues = (errorBody?['issues'] as List?)
                ?.map((i) => i as Map<String, dynamic>)
                .toList() ??
            [];
        return ValidationException(message: message, code: code, issues: issues);
      case 401:
        return AuthException(message: message, code: code, statusCode: 401);
      case 403:
        return ForbiddenException(message: message, code: code);
      case 404:
        return NotFoundException(message: message, code: code);
      case 429:
        return RateLimitException(message: message, code: code);
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          return const NetworkException(
            message: 'Connection error. Check your internet.',
            code: 'network_error',
          );
        }
        return ApiException(
          message: message,
          code: code,
          statusCode: statusCode,
        );
    }
  }
}
