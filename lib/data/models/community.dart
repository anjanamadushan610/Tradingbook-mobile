import 'package:equatable/equatable.dart';

import 'json_utils.dart';

enum GroupRole {
  owner,
  admin,
  moderator,
  member;

  static GroupRole? fromWire(Object? value) =>
      GroupRole.values.where((r) => r.name == value).firstOrNull;

  int get rank => switch (this) {
        GroupRole.owner => 3,
        GroupRole.admin => 2,
        GroupRole.moderator => 1,
        GroupRole.member => 0,
      };

  bool get canManage => rank >= GroupRole.admin.rank;

  String get label => name[0].toUpperCase() + name.substring(1);
}

class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    this.description = '',
    this.isPrivate = false,
    required this.ownerId,
    this.avatarUrl,
    this.coverUrl,
    this.memberCount = 0,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final bool isPrivate;
  final String ownerId;
  final String? avatarUrl;
  final String? coverUrl;
  final int memberCount;
  final DateTime createdAt;

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: readString(json['id']),
        name: readString(json['name'], 'Group'),
        description: readString(json['description']),
        isPrivate:
            json['visibility'] == 'private' || readBool(json['isPrivate']),
        ownerId: readString(json['ownerId'] ?? json['creatorId']),
        avatarUrl: readNullableString(json['avatarUrl']),
        coverUrl: readNullableString(json['coverUrl']),
        memberCount: readInt(json['memberCount']),
        createdAt: readTime(json['createdAt']),
      );

  @override
  List<Object?> get props =>
      [id, name, description, isPrivate, avatarUrl, coverUrl, memberCount];
}

class GroupMember extends Equatable {
  const GroupMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final GroupRole role;
  final DateTime joinedAt;

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        userId: readString(json['userId']),
        role: GroupRole.fromWire(json['role']) ?? GroupRole.member,
        joinedAt: readTime(json['joinedAt']),
      );

  @override
  List<Object?> get props => [userId, role];
}

class GroupMembership extends Equatable {
  const GroupMembership({required this.isMember, this.role});

  final bool isMember;
  final GroupRole? role;

  static const none = GroupMembership(isMember: false);

  factory GroupMembership.fromJson(Map<String, dynamic> json) =>
      GroupMembership(
        isMember: readBool(json['isMember']),
        role: GroupRole.fromWire(json['role']),
      );

  @override
  List<Object?> get props => [isMember, role];
}

enum PageRole {
  owner,
  admin,
  editor;

  static PageRole? fromWire(Object? value) =>
      PageRole.values.where((r) => r.name == value).firstOrNull;

  String get label => name[0].toUpperCase() + name.substring(1);
}

/// A TradingBook "Page" (brand / creator channel; `/channels` on the web).
/// Named CommunityPage so it never collides with pagination's page.
class CommunityPage extends Equatable {
  const CommunityPage({
    required this.id,
    required this.name,
    this.description = '',
    required this.ownerId,
    this.avatarUrl,
    this.coverUrl,
    this.followerCount = 0,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String? avatarUrl;
  final String? coverUrl;
  final int followerCount;
  final DateTime createdAt;

  factory CommunityPage.fromJson(Map<String, dynamic> json) => CommunityPage(
        id: readString(json['id']),
        name: readString(json['name'], 'Page'),
        description: readString(json['description']),
        ownerId: readString(json['ownerId'] ?? json['creatorId']),
        avatarUrl: readNullableString(json['avatarUrl']),
        coverUrl: readNullableString(json['coverImageUrl'] ?? json['coverUrl']),
        followerCount: readInt(json['followerCount']),
        createdAt: readTime(json['createdAt']),
      );

  @override
  List<Object?> get props =>
      [id, name, description, avatarUrl, coverUrl, followerCount];
}

class PageRoleEntry extends Equatable {
  const PageRoleEntry({required this.userId, required this.role});

  final String userId;
  final PageRole role;

  factory PageRoleEntry.fromJson(Map<String, dynamic> json) => PageRoleEntry(
        userId: readString(json['userId']),
        role: PageRole.fromWire(json['role']) ?? PageRole.editor,
      );

  @override
  List<Object?> get props => [userId, role];
}

class PageFollower extends Equatable {
  const PageFollower({required this.userId, required this.followedAt});

  final String userId;
  final DateTime followedAt;

  factory PageFollower.fromJson(Map<String, dynamic> json) => PageFollower(
        userId: readString(json['userId']),
        followedAt: readTime(json['followedAt'] ?? json['createdAt']),
      );

  @override
  List<Object?> get props => [userId];
}
