import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});
  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  });
  Future<OwnUser> getMe();
  Future<OwnUser> updateMe({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    List<String>? interests,
    List<String>? languages,
    bool? isPrivate,
  });
  Future<void> logout();
  Future<bool> hasValidSession();
  Future<void> forgotPassword(String email);
  Future<void> verifyOtp(String email, String otp);
  Future<void> resetPassword(String email, String otp, String newPassword);
}
