import '../../domain/entities/post.dart';

class PostModel {
  final String id;
  final String authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final String type;
  final String caption;
  final List<String> mediaRefs;
  final String language;
  final String status;
  final String? groupId;
  final String? pageId;
  final int likeCount;
  final int commentCount;
  final bool hasLiked;
  final int createdAt;
  final int? updatedAt;

  const PostModel({
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

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String?,
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        type: json['type'] as String? ?? 'text',
        caption: json['caption'] as String? ?? '',
        mediaRefs: (json['mediaRefs'] as List?)?.cast<String>() ?? [],
        language: json['language'] as String? ?? 'en',
        status: json['status'] as String? ?? 'live',
        groupId: json['groupId'] as String?,
        pageId: json['pageId'] as String?,
        likeCount: json['likeCount'] as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        hasLiked: json['hasLiked'] as bool? ?? false,
        createdAt: json['createdAt'] as int,
        updatedAt: json['updatedAt'] as int?,
      );

  Post toEntity() => Post(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        type: _parseType(type),
        caption: caption,
        mediaRefs: mediaRefs,
        language: language,
        status: _parseStatus(status),
        groupId: groupId,
        pageId: pageId,
        likeCount: likeCount,
        commentCount: commentCount,
        hasLiked: hasLiked,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  PostType _parseType(String t) {
    switch (t) {
      case 'image':
        return PostType.image;
      case 'video':
        return PostType.video;
      default:
        return PostType.text;
    }
  }

  PostStatus _parseStatus(String s) {
    switch (s) {
      case 'draft':
        return PostStatus.draft;
      case 'transcoding':
        return PostStatus.transcoding;
      case 'pending':
        return PostStatus.pending;
      case 'pending_group':
        return PostStatus.pendingGroup;
      case 'pending_platform':
        return PostStatus.pendingPlatform;
      case 'approved':
        return PostStatus.approved;
      case 'rejected':
        return PostStatus.rejected;
      case 'failed':
        return PostStatus.failed;
      default:
        return PostStatus.live;
    }
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? parentCommentId;
  final String body;
  final String status;
  final int createdAt;

  const CommentModel({
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

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] as String,
        postId: json['postId'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String?,
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        parentCommentId: json['parentCommentId'] as String?,
        body: json['body'] as String,
        status: json['status'] as String? ?? 'visible',
        createdAt: json['createdAt'] as int,
      );

  Comment toEntity() => Comment(
        id: id,
        postId: postId,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        parentCommentId: parentCommentId,
        body: body,
        status: status,
        createdAt: createdAt,
      );
}
