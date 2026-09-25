import 'package:equatable/equatable.dart';

import 'json_utils.dart';

class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.parentCommentId,
    required this.body,
    required this.createdAt,
    this.isDeleted = false,
    this.likeCount = 0,
    this.hasLiked = false,
  });

  final String id;
  final String postId;
  final String authorId;
  final String? parentCommentId;
  final String body;
  final DateTime createdAt;
  final bool isDeleted;
  final int likeCount;
  final bool hasLiked;

  bool get isReply => parentCommentId != null;

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: readString(json['id']),
        postId: readString(json['postId']),
        authorId: readString(json['authorId']),
        parentCommentId:
            readNullableString(json['parentCommentId'] ?? json['parentId']),
        body: readString(json['body'] ?? json['content']),
        createdAt: readTime(json['createdAt']),
        isDeleted: json['status'] == 'deleted',
        likeCount: readInt(json['likeCount']),
        hasLiked: readBool(json['hasLiked']),
      );

  Comment copyWith({String? body, int? likeCount, bool? hasLiked}) => Comment(
        id: id,
        postId: postId,
        authorId: authorId,
        parentCommentId: parentCommentId,
        body: body ?? this.body,
        createdAt: createdAt,
        isDeleted: isDeleted,
        likeCount: likeCount ?? this.likeCount,
        hasLiked: hasLiked ?? this.hasLiked,
      );

  @override
  List<Object?> get props => [id, body, likeCount, hasLiked, isDeleted];
}
