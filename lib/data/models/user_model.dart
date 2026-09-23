import '../../domain/entities/user.dart';

/// Safely parses a timestamp field that may arrive as:
///   - an [int]  (Unix epoch milliseconds, as used by some backends), or
///   - a [String] (ISO 8601, e.g. "2024-01-15T10:30:00Z")
/// Returns milliseconds since epoch in both cases.
int _parseTimestamp(dynamic value) {
  if (value is int) return value;
  if (value is String) return DateTime.parse(value).millisecondsSinceEpoch;
  throw ArgumentError('Unexpected timestamp type: ${value.runtimeType} ($value)');
}

class UserModel {
  final String id;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final String? coverUrl;
  final List<String> interests;
  final List<String> languages;
  final bool isPrivate;
  final int createdAt;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.bio,
    this.avatarUrl,
    this.coverUrl,
    required this.interests,
    required this.languages,
    required this.isPrivate,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        bio: json['bio'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        coverUrl: json['coverUrl'] as String?,
        interests: (json['interests'] as List?)?.cast<String>() ?? [],
        languages: (json['languages'] as List?)?.cast<String>() ?? [],
        isPrivate: json['isPrivate'] as bool? ?? false,
        createdAt: _parseTimestamp(json['createdAt']),
      );

  User toEntity() => User(
        id: id,
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        interests: interests,
        languages: languages,
        isPrivate: isPrivate,
        createdAt: createdAt,
      );
}

class OwnUserModel extends UserModel {
  final String email;
  final int updatedAt;
  final String platformRole;

  const OwnUserModel({
    required super.id,
    required this.email,
    required super.displayName,
    required super.bio,
    super.avatarUrl,
    super.coverUrl,
    required super.interests,
    required super.languages,
    required super.isPrivate,
    required super.createdAt,
    required this.updatedAt,
    required this.platformRole,
  });

  factory OwnUserModel.fromJson(Map<String, dynamic> json) => OwnUserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        bio: json['bio'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        coverUrl: json['coverUrl'] as String?,
        interests: (json['interests'] as List?)?.cast<String>() ?? [],
        languages: (json['languages'] as List?)?.cast<String>() ?? [],
        isPrivate: json['isPrivate'] as bool? ?? false,
        createdAt: _parseTimestamp(json['createdAt']),
        updatedAt: _parseTimestamp(json['updatedAt']),
        platformRole: json['platformRole'] as String? ?? 'user',
      );

  OwnUser toOwnEntity() => OwnUser(
        id: id,
        email: email,
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        interests: interests,
        languages: languages,
        isPrivate: isPrivate,
        createdAt: createdAt,
        updatedAt: updatedAt,
        platformRole: _parsePlatformRole(platformRole),
      );

  PlatformRole _parsePlatformRole(String role) {
    switch (role) {
      case 'moderator':
        return PlatformRole.moderator;
      case 'admin':
        return PlatformRole.admin;
      default:
        return PlatformRole.user;
    }
  }
}

class AuthSessionModel {
  final OwnUserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthSessionModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) =>
      AuthSessionModel(
        user: OwnUserModel.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );

  AuthSession toEntity() => AuthSession(
        user: user.toOwnEntity(),
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
}
