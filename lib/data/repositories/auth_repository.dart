import 'dart:io';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../models/user.dart';

sealed class SignupResult {
  const SignupResult();
}

/// Account exists and the user is signed in (dev/test backends without email).
class SignupSignedIn extends SignupResult {
  const SignupSignedIn(this.user);
  final UserProfile user;
}

/// Production: a verification link was emailed; the account is created only
/// when it's clicked.
class SignupVerificationPending extends SignupResult {
  const SignupVerificationPending(this.message);
  final String message;
}

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<bool> hasSession() async => await _tokens.read() != null;

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final json = await _api.postPublic<Json>(
      '/api/v1/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    return _adoptSession(json);
  }

  Future<SignupResult> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final json = await _api.postPublic<Json>(
      '/api/v1/auth/signup',
      body: {
        'email': email.trim(),
        'password': password,
        'displayName': displayName.trim(),
      },
    );
    if (json['accessToken'] is String) {
      return SignupSignedIn(await _adoptSession(json));
    }
    return SignupVerificationPending(
      json['message'] as String? ??
          'Check your inbox and tap the link to activate your account.',
    );
  }

  Future<UserProfile> signInWithGoogle(String idToken) async {
    final json = await _api.postPublic<Json>(
      '/api/v1/auth/google',
      body: {'idToken': idToken},
    );
    return _adoptSession(json);
  }

  Future<void> requestPasswordReset(String email) async {
    await _api.postPublic<Json>(
      '/api/v1/auth/forgot-password',
      body: {'email': email.trim()},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.postPublic<Json>(
      '/api/v1/auth/reset-password',
      body: {
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );
  }

  Future<UserProfile> fetchMe() async =>
      UserProfile.fromJson(await _api.get<Json>('/api/v1/me'));

  Future<UserProfile> updateMe(Map<String, Object?> patch) async =>
      UserProfile.fromJson(await _api.put<Json>('/api/v1/me', body: patch));

  /// `kind` is `avatar` or `cover`. The response carries the updated profile,
  /// so no refetch is needed.
  Future<UserProfile> uploadProfileImage(File file, {required String kind}) async {
    final json = await _api.uploadFile('/api/v1/me/$kind', file: file);
    return UserProfile.fromJson(json['profile'] as Json);
  }

  /// A password change revokes every refresh token, including ours, and
  /// returns a fresh pair — storing it is what keeps this device signed in.
  Future<int> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final json = await _api.post<Json>(
      '/api/v1/auth/change-password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    if (json['accessToken'] is String && json['refreshToken'] is String) {
      await _tokens.save(AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      ));
    }
    return (json['revokedSessions'] as num?)?.toInt() ?? 0;
  }

  /// Permanently deletes the account. Password accounts must re-enter their
  /// password; social accounts confirm by typing DELETE in the UI.
  Future<void> deleteAccount({String? password}) async {
    await _api.delete<Json>(
      '/api/v1/me',
      body: {'password': ?password, 'confirm': true},
    );
    await _tokens.clear();
  }

  Future<void> logout() => _tokens.clear();

  Future<UserProfile> _adoptSession(Json json) async {
    await _tokens.save(AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    ));
    return UserProfile.fromJson(json['user'] as Json);
  }
}
