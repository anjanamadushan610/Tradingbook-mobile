import 'package:equatable/equatable.dart';

import 'json_utils.dart';

enum PostType { text, image, video }

enum PostVisibility {
  public('public', 'Public'),
  followersOnly('followers_only', 'Followers'),
  private('private', 'Only me');

  const PostVisibility(this.wire, this.label);
  final String wire;
  final String label;

  static PostVisibility fromWire(Object? value) => PostVisibility.values
      .firstWhere((v) => v.wire == value, orElse: () => PostVisibility.public);
}

/// Lifecycle states from the backend. Only [live] is visible to others.
enum PostStatus {
  draft,
  transcoding,
  pending,
  pendingGroup,
  pendingPlatform,
  approved,
  live,
  rejected,
  failed;

  static PostStatus fromWire(Object? value) {
    switch (value) {
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

  bool get isInReview =>
      this == pending ||
      this == pendingGroup ||
      this == pendingPlatform ||
      this == approved ||
      this == transcoding;

  String get label {
    switch (this) {
      case PostStatus.draft:
        return 'Draft';
      case PostStatus.transcoding:
        return 'Processing';
      case PostStatus.pending:
      case PostStatus.pendingPlatform:
      case PostStatus.approved:
        return 'In review';
      case PostStatus.pendingGroup:
        return 'Awaiting group approval';
      case PostStatus.live:
        return 'Live';
      case PostStatus.rejected:
        return 'Rejected';
      case PostStatus.failed:
        return 'Failed';
    }
  }
}

/// A post as any list endpoint returns it. The feed sends `FeedItem`
/// (`postId`, no status); everything else sends `PostRecord` (`id`, status,
/// visibility…); ranked lists add counts. One model reads all of them.
class Post extends Equatable {
  const Post({
    required this.id,
    required this.authorId,
    required this.type,
    required this.caption,
    this.mediaRefs = const [],
    this.language = 'und',
    this.status = PostStatus.live,
    this.visibility = PostVisibility.public,
    this.groupId,
    this.pageId,
    required this.createdAt,
    this.updatedAt,
    this.rejectedReason,
    this.likeCount,
    this.commentCount,
    this.authorName,
  });

  final String id;
  final String authorId;
  final PostType type;
  final String caption;

  /// Raw R2 object keys (images) or a Stream uid (video) — not URLs. Resolve
  /// with `MediaUrls`.
  final List<String> mediaRefs;
  final String language;
  final PostStatus status;
  final PostVisibility visibility;
  final String? groupId;
  final String? pageId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? rejectedReason;
  final int? likeCount;
  final int? commentCount;

  /// Only the moderation queue sends this.
  final String? authorName;

  bool get isCommunityPost => groupId != null || pageId != null;

  factory Post.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    return Post(
      id: readString(json['id'] ?? json['postId']),
      authorId: readString(json['authorId']),
      type: PostType.values.firstWhere(
        (t) => t.name == type,
        orElse: () => PostType.text,
      ),
      caption: readString(json['caption']),
      mediaRefs: readStringList(json['mediaRefs']),
      language: readString(json['language'], 'und'),
      status: PostStatus.fromWire(json['status']),
      visibility: PostVisibility.fromWire(json['visibility']),
      groupId: readNullableString(json['groupId']),
      pageId: readNullableString(json['pageId']),
      createdAt: readTime(json['createdAt']),
      updatedAt: json['updatedAt'] == null ? null : readTime(json['updatedAt']),
      rejectedReason: readNullableString(json['rejectedReason']),
      likeCount: json['likeCount'] == null ? null : readInt(json['likeCount']),
      commentCount:
          json['commentCount'] == null ? null : readInt(json['commentCount']),
      authorName: readNullableString(json['authorName']),
    );
  }

  Post copyWith({String? caption, PostVisibility? visibility}) => Post(
        id: id,
        authorId: authorId,
        type: type,
        caption: caption ?? this.caption,
        mediaRefs: mediaRefs,
        language: language,
        status: status,
        visibility: visibility ?? this.visibility,
        groupId: groupId,
        pageId: pageId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        rejectedReason: rejectedReason,
        likeCount: likeCount,
        commentCount: commentCount,
        authorName: authorName,
      );

  @override
  List<Object?> get props => [id, caption, visibility, status, likeCount];
}

/// Per-post engagement for the viewer: counts plus their own like/save state.
class PostStats extends Equatable {
  const PostStats({
    required this.likeCount,
    required this.commentCount,
    required this.hasLiked,
    required this.bookmarked,
  });

  final int likeCount;

  /// Null when unknown (the per-post fallback path can't count cheaply).
  final int? commentCount;
  final bool hasLiked;
  final bool bookmarked;

  static const empty =
      PostStats(likeCount: 0, commentCount: 0, hasLiked: false, bookmarked: false);

  PostStats copyWith({
    int? likeCount,
    int? commentCount,
    bool? hasLiked,
    bool? bookmarked,
  }) =>
      PostStats(
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        hasLiked: hasLiked ?? this.hasLiked,
        bookmarked: bookmarked ?? this.bookmarked,
      );

  factory PostStats.fromJson(Map<String, dynamic> json) => PostStats(
        likeCount: readInt(json['likeCount']),
        commentCount: readInt(json['commentCount']),
        hasLiked: readBool(json['hasLiked']),
        bookmarked: readBool(json['bookmarked']),
      );

  @override
  List<Object?> get props => [likeCount, commentCount, hasLiked, bookmarked];
}

class TrendingTopic extends Equatable {
  const TrendingTopic({
    required this.tag,
    required this.label,
    required this.postCount,
  });

  /// Lowercase, no '#': use for search.
  final String tag;

  /// Display form, e.g. "#BTC".
  final String label;
  final int postCount;

  factory TrendingTopic.fromJson(Map<String, dynamic> json) => TrendingTopic(
        tag: readString(json['tag']),
        label: readString(json['label'], '#${readString(json['tag'])}'),
        postCount: readInt(json['postCount']),
      );

  @override
  List<Object?> get props => [tag];
}
