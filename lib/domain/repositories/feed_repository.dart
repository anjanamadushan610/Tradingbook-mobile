import '../entities/post.dart';

abstract class FeedRepository {
  Future<({List<Post> items, String? nextCursor})> getFeed({
    String? cursor,
    int limit = 20,
  });
}

abstract class PostsRepository {
  Future<Post> createPost({
    required String type,
    required String caption,
    List<String>? mediaRefs,
    String? mediaRef,
    String language = 'en',
  });
  Future<Post> submitPost(String postId);
  Future<({List<Post> items, String? nextCursor})> getMyPosts({
    String? cursor,
    int limit = 20,
  });
  Future<({List<Post> items, String? nextCursor})> searchPosts({
    required String query,
    String? cursor,
    int limit = 20,
  });
  Future<Post> getPost(String postId);
  Future<({bool success, int likeCount})> likePost(String postId);
  Future<({bool success, int likeCount})> unlikePost(String postId);
  Future<Comment> postComment({
    required String postId,
    required String body,
    String? parentCommentId,
  });
  Future<({List<Comment> items, String? nextCursor})> getComments({
    required String postId,
    String? cursor,
    int limit = 20,
  });
  Future<void> deletePost(String postId);
  Future<bool> deleteComment(String commentId);
  Future<void> toggleBookmark(String postId);
}
