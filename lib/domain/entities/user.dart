import 'package:equatable/equatable.dart';

enum PlatformRole { user, moderator, admin }

class User extends Equatable {
  final String id;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final String? coverUrl;
  final List<String> interests;
  final List<String> languages;
  final bool isPrivate;
  final int createdAt;

  const User({
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

  @override
  List<Object?> get props => [id, displayName, avatarUrl, isPrivate];
}

class OwnUser extends User {
  final String email;
  final int updatedAt;
  final PlatformRole platformRole;

  const OwnUser({
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

  @override
  List<Object?> get props => [...super.props, email, platformRole];
}

class AuthSession extends Equatable {
  final OwnUser user;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [user, accessToken];
}
