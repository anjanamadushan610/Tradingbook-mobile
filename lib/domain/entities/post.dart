import 'package:equatable/equatable.dart';

enum PostType { text, image, video }

enum PostStatus {
  draft,
  transcoding,
  pending,
  pendingGroup,
  pendingPlatform,
  approved,
  live,
  rejected,
  failed,
}

class Post extends Equatable {
  final String id;
  final String authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final PostType type;
  final String caption;
  final List<String> mediaRefs;
  final String language;
  final PostStatus status;
  final String? groupId;
  final String? pageId;
  final int likeCount;
  final int commentCount;
  final bool hasLiked;
  final int createdAt;
  final int? updatedAt;

  const Post({
    required this.id,
    required this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    required this.type,
    required this.caption,
    required this.mediaRefs,
    required this.language,
    required this.status,
    this.groupId,
    this.pageId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.hasLiked = false,
    required this.createdAt,
    this.updatedAt,
  });

  Post copyWith({
    int? likeCount,
    int? commentCount,
    bool? hasLiked,
  }) {
    return Post(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      type: type,
      caption: caption,
      mediaRefs: mediaRefs,
      language: language,
      status: status,
      groupId: groupId,
      pageId: pageId,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      hasLiked: hasLiked ?? this.hasLiked,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, likeCount, commentCount, hasLiked];
}

class Comment extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? parentCommentId;
  final String body;
  final String status;
  final int createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    this.parentCommentId,
    required this.body,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, body];
}
