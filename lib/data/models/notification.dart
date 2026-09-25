import 'package:equatable/equatable.dart';

import 'json_utils.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    this.postId,
    this.commentId,
    this.groupId,
    this.pageId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final String id;

  /// post_approved | post_rejected | new_follower | comment | like |
  /// comment_like | group_join | role_change | page_post
  final String type;
  final String actorId;
  final String actorName;
  final String? postId;
  final String? commentId;
  final String? groupId;
  final String? pageId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: readString(json['id']),
        type: readString(json['type']),
        actorId: readString(json['actorId']),
        actorName: readString(json['actorName'], 'Someone'),
        postId: readNullableString(json['postId']),
        commentId: readNullableString(json['commentId']),
        groupId: readNullableString(json['groupId']),
        pageId: readNullableString(json['pageId']),
        message: readString(json['message']),
        isRead: readBool(json['isRead']),
        createdAt: readTime(json['createdAt']),
      );

  AppNotification markRead() => AppNotification(
        id: id,
        type: type,
        actorId: actorId,
        actorName: actorName,
        postId: postId,
        commentId: commentId,
        groupId: groupId,
        pageId: pageId,
        message: message,
        isRead: true,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, isRead];
}
