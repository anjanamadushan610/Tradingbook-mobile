import '../../domain/entities/group.dart';

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final bool isPrivate;
  final String? rules;
  final String? avatarUrl;
  final String? coverUrl;
  final String? creatorId;
  final int memberCount;
  final String? viewerRole;
  final int? createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.isPrivate,
    this.rules,
    this.avatarUrl,
    this.coverUrl,
    this.creatorId,
    required this.memberCount,
    this.viewerRole,
    this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        isPrivate: json['isPrivate'] as bool? ?? false,
        rules: json['rules'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        coverUrl: json['coverUrl'] as String?,
        creatorId: json['creatorId'] as String?,
        memberCount: json['memberCount'] as int? ?? 0,
        viewerRole: json['viewerRole'] as String? ?? json['role'] as String?,
        createdAt: json['createdAt'] as int?,
      );

  Group toEntity() => Group(
        id: id,
        name: name,
        description: description,
        isPrivate: isPrivate,
        rules: rules,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        creatorId: creatorId,
        memberCount: memberCount,
        viewerRole: viewerRole,
        createdAt: createdAt,
      );
}
