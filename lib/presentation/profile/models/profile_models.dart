class UserModel {
  final String name;
  final String username;
  final String bio;
  final int followers;
  final int following;
  final String? avatarUrl;
  final String? coverUrl;
  final List<String> interests;

  const UserModel({
    required this.name,
    required this.username,
    required this.bio,
    required this.followers,
    required this.following,
    this.avatarUrl,
    this.coverUrl,
    this.interests = const [],
  });
}

class PostModel {
  final String id;
  final String authorName;
  final String authorUsername;
  final String date;
  final String content;
  final String? authorAvatarUrl;
  final List<String> mediaUrls;
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final bool isSaved;
  final String status;

  const PostModel({
    this.id = '',
    required this.authorName,
    required this.authorUsername,
    required this.date,
    required this.content,
    this.authorAvatarUrl,
    this.mediaUrls = const [],
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.status = 'live',
  });

  PostModel copyWith({
    String? id,
    String? authorName,
    String? authorUsername,
    String? date,
    String? content,
    String? authorAvatarUrl,
    List<String>? mediaUrls,
    int? likes,
    int? comments,
    int? shares,
    bool? isLiked,
    bool? isSaved,
    String? status,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      date: date ?? this.date,
      content: content ?? this.content,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      status: status ?? this.status,
    );
  }
}
