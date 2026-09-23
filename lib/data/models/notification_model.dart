import '../../domain/entities/notification.dart';

class NotificationModel {
  final String id;
  final String type;
  final String recipientId;
  final String actorId;
  final String actorName;
  final String? actorAvatarUrl;
  final String? postId;
  final String? groupId;
  final String? pageId;
  final String message;
  final bool isRead;
  final int createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.recipientId,
    required this.actorId,
    required this.actorName,
    this.actorAvatarUrl,
    this.postId,
    this.groupId,
    this.pageId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        type: json['type'] as String,
        recipientId: json['recipientId'] as String,
        actorId: json['actorId'] as String,
        actorName: json['actorName'] as String? ?? '',
        actorAvatarUrl: json['actorAvatarUrl'] as String?,
        postId: json['postId'] as String?,
        groupId: json['groupId'] as String?,
        pageId: json['pageId'] as String?,
        message: json['message'] as String,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: json['createdAt'] as int,
      );

  AppNotification toEntity() => AppNotification(
        id: id,
        type: _parseType(type),
        recipientId: recipientId,
        actorId: actorId,
        actorName: actorName,
        actorAvatarUrl: actorAvatarUrl,
        postId: postId,
        groupId: groupId,
        pageId: pageId,
        message: message,
        isRead: isRead,
        createdAt: createdAt,
      );

  NotificationType _parseType(String t) {
    switch (t) {
      case 'post_approved':
        return NotificationType.postApproved;
      case 'post_rejected':
        return NotificationType.postRejected;
      case 'new_follower':
        return NotificationType.newFollower;
      case 'comment':
        return NotificationType.comment;
      case 'like':
        return NotificationType.like;
      case 'group_join':
        return NotificationType.groupJoin;
      case 'role_change':
        return NotificationType.roleChange;
      case 'page_post':
        return NotificationType.pagePost;
      default:
        return NotificationType.like;
    }
  }
}
