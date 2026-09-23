import 'package:equatable/equatable.dart';

class Group extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isPrivate;
  final String? rules;
  final String? avatarUrl;
  final String? coverUrl;
  final String? creatorId;
  final int memberCount;
  final String? viewerRole; // "owner"|"admin"|"moderator"|"member"|null
  final int? createdAt;

  const Group({
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

  bool get isMember => viewerRole != null;

  @override
  List<Object?> get props => [id, memberCount, viewerRole];
}
