import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/security/secure_token_store.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DioClient _client;
  final SecureTokenStore _tokenStore;

  AuthRepositoryImpl({
    required DioClient client,
    required SecureTokenStore tokenStore,
  })  : _client = client,
        _tokenStore = tokenStore;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    debugPrint('\n========================================');
    debugPrint('[AuthRepo] LOGIN ATTEMPT');
    debugPrint('[AuthRepo]   URL    : ${ApiEndpoints.baseUrl}${ApiEndpoints.login}');
    debugPrint('[AuthRepo]   Email  : $email');
    debugPrint('========================================');
    try {
      final response = await _client.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });
      debugPrint('[AuthRepo] ✅ LOGIN SUCCESS');
      debugPrint('[AuthRepo]   Status : ${response.statusCode}');
      debugPrint('[AuthRepo]   Body   : ${response.data}');
      debugPrint('========================================\n');
      final model = AuthSessionModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _tokenStore.saveTokens(
        accessToken: model.accessToken,
        refreshToken: model.refreshToken,
      );
      return model.toEntity();
    } on ApiException catch (e) {
      debugPrint('[AuthRepo] ❌ LOGIN FAILED (ApiException)');
      debugPrint('[AuthRepo]   Type    : ${e.runtimeType}');
      debugPrint('[AuthRepo]   Status  : ${e.statusCode}');
      debugPrint('[AuthRepo]   Code    : ${e.code}');
      debugPrint('[AuthRepo]   Message : ${e.message}');
      debugPrint('========================================\n');
      rethrow;
    } catch (e, st) {
      debugPrint('[AuthRepo] ❌ LOGIN FAILED (Unexpected)');
      debugPrint('[AuthRepo]   Error : $e');
      debugPrint('[AuthRepo]   Stack : $st');
      debugPrint('========================================\n');
      rethrow;
    }
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.post(ApiEndpoints.signup, data: {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    final model = AuthSessionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
    await _tokenStore.saveTokens(
      accessToken: model.accessToken,
      refreshToken: model.refreshToken,
    );
    return model.toEntity();
  }

  @override
  Future<OwnUser> getMe() async {
    final response = await _client.get(ApiEndpoints.me);
    return OwnUserModel.fromJson(response.data as Map<String, dynamic>)
        .toOwnEntity();
  }

  @override
  Future<OwnUser> updateMe({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    List<String>? interests,
    List<String>? languages,
    bool? isPrivate,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (coverUrl != null) data['coverUrl'] = coverUrl;
    if (interests != null) data['interests'] = interests;
    if (languages != null) data['languages'] = languages;
    if (isPrivate != null) data['isPrivate'] = isPrivate;

    final response = await _client.put(ApiEndpoints.me, data: data);
    return OwnUserModel.fromJson(response.data as Map<String, dynamic>)
        .toOwnEntity();
  }

  @override
  Future<void> logout() async {
    await _tokenStore.clearTokens();
  }

  @override
  Future<bool> hasValidSession() async {
    final token = await _tokenStore.getAccessToken();
    if (token == null) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = json.decode(payload) as Map<String, dynamic>;

      final exp = payloadMap['exp'];
      if (exp == null) return false;

      final expiresAt = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      if (DateTime.now().isAfter(expiresAt)) {
        await _tokenStore.clearTokens();
        return false;
      }

      return true;
    } catch (e) {
      await _tokenStore.clearTokens();
      return false;
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _client.post('/api/v1/auth/forgot-password', data: {
      'email': email,
    });
  }

  @override
  Future<void> verifyOtp(String email, String otp) async {
    await _client.post('/api/v1/auth/verify-otp', data: {
      'email': email,
      'otp': otp,
    });
  }

  @override
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await _client.post('/api/v1/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }
}
