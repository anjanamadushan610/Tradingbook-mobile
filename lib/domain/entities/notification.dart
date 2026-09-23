import 'package:equatable/equatable.dart';

enum NotificationType {
  postApproved,
  postRejected,
  newFollower,
  comment,
  like,
  groupJoin,
  roleChange,
  pagePost,
}

class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
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

  const AppNotification({
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

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      recipientId: recipientId,
      actorId: actorId,
      actorName: actorName,
      actorAvatarUrl: actorAvatarUrl,
      postId: postId,
      groupId: groupId,
      pageId: pageId,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, isRead];
}
