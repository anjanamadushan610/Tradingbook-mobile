import 'package:equatable/equatable.dart';

import 'json_utils.dart';

enum AuthProvider { password, google, apple }

/// One class for every profile shape the API returns:
///  * public profile (`GET /api/v1/users/:id`),
///  * own profile (`GET /api/v1/me`, auth envelopes) — adds [email],
///    [platformRole], [authProvider],
///  * ranked trader (`/api/discover/*-traders`) — adds [followerCount].
/// Fields a given endpoint doesn't send stay null.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.bio = '',
    this.avatarUrl,
    this.coverUrl,
    this.interests = const [],
    this.languages = const [],
    this.isPrivate = false,
    required this.createdAt,
    this.email,
    this.platformRole,
    this.authProvider,
    this.followerCount,
  });

  final String id;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final String? coverUrl;
  final List<String> interests;
  final List<String> languages;
  final bool isPrivate;
  final DateTime createdAt;
  final String? email;
  final String? platformRole;
  final AuthProvider? authProvider;
  final int? followerCount;

  bool get isModerator =>
      platformRole == 'moderator' || platformRole == 'admin';

  /// Social accounts have no password — hide change-password for them.
  bool get hasPassword =>
      authProvider == null || authProvider == AuthProvider.password;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final provider = json['authProvider'];
    return UserProfile(
      id: readString(json['id']),
      displayName: readString(json['displayName'], 'Trader'),
      bio: readString(json['bio']),
      avatarUrl: readNullableString(json['avatarUrl']),
      coverUrl: readNullableString(json['coverUrl']),
      interests: readStringList(json['interests']),
      languages: readStringList(json['languages']),
      isPrivate: readBool(json['isPrivate']),
      createdAt: readTime(json['createdAt']),
      email: readNullableString(json['email']),
      platformRole: readNullableString(json['platformRole']),
      authProvider: provider is String
          ? AuthProvider.values.firstWhere(
              (p) => p.name == provider,
              orElse: () => AuthProvider.password,
            )
          : null,
      followerCount: json['followerCount'] == null
          ? null
          : readInt(json['followerCount']),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    List<String>? interests,
    List<String>? languages,
    bool? isPrivate,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      interests: interests ?? this.interests,
      languages: languages ?? this.languages,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt,
      email: email,
      platformRole: platformRole,
      authProvider: authProvider,
      followerCount: followerCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        bio,
        avatarUrl,
        coverUrl,
        interests,
        languages,
        isPrivate,
        email,
        platformRole,
        authProvider,
        followerCount,
      ];
}

class FollowCounts extends Equatable {
  const FollowCounts({required this.followers, required this.following});

  final int followers;
  final int following;

  factory FollowCounts.fromJson(Map<String, dynamic> json) => FollowCounts(
        followers: readInt(json['followers'] ?? json['followersCount']),
        following: readInt(json['following'] ?? json['followingCount']),
      );

  @override
  List<Object?> get props => [followers, following];
}

/// An entry in a followers/following list — the API returns ids only; the UI
/// hydrates names through the profile cache.
class FollowEdge extends Equatable {
  const FollowEdge({required this.userId, required this.createdAt});

  final String userId;
  final DateTime createdAt;

  factory FollowEdge.fromJson(Map<String, dynamic> json) => FollowEdge(
        userId: readString(json['userId'] ?? json['id']),
        createdAt: readTime(json['createdAt']),
      );

  @override
  List<Object?> get props => [userId];
}
