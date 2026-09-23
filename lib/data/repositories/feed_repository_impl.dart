import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../models/post_model.dart';

class FeedRepositoryImpl implements FeedRepository {
  final DioClient _client;

  FeedRepositoryImpl({required DioClient client}) : _client = client;

  @override
  Future<({List<Post> items, String? nextCursor})> getFeed({
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;

    final response = await _client.get(
      ApiEndpoints.feed,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    final nextCursor = data['nextCursor'] as String?;

    return (items: items, nextCursor: nextCursor);
  }
}

class PostsRepositoryImpl implements PostsRepository {
  final DioClient _client;

  PostsRepositoryImpl({required DioClient client}) : _client = client;

  @override
  Future<Post> createPost({
    required String type,
    required String caption,
    List<String>? mediaRefs,
    String? mediaRef,
    String language = 'en',
  }) async {
    final data = <String, dynamic>{
      'type': type,
      'caption': caption,
      'language': language,
    };
    if (mediaRefs != null) data['mediaRefs'] = mediaRefs;
    if (mediaRef != null) data['mediaRef'] = mediaRef;

    final response = await _client.post(ApiEndpoints.posts, data: data);
    return PostModel.fromJson(response.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<Post> submitPost(String postId) async {
    final response = await _client.post(ApiEndpoints.postSubmit(postId));
    return PostModel.fromJson(response.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<({List<Post> items, String? nextCursor})> getMyPosts({
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;

    final response = await _client.get(ApiEndpoints.myPosts, queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    return (items: items, nextCursor: data['nextCursor'] as String?);
  }

  @override
  Future<({List<Post> items, String? nextCursor})> searchPosts({
    required String query,
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'q': query, 'limit': limit};
    if (cursor != null) params['cursor'] = cursor;

    final response = await _client.get(ApiEndpoints.searchPosts, queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    return (items: items, nextCursor: data['nextCursor'] as String?);
  }

  @override
  Future<Post> getPost(String postId) async {
    final response = await _client.get(ApiEndpoints.postById(postId));
    return PostModel.fromJson(response.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<({bool success, int likeCount})> likePost(String postId) async {
    final response = await _client.post(ApiEndpoints.like, data: {'postId': postId});
    final data = response.data as Map<String, dynamic>;
    return (
      success: data['success'] as bool? ?? true,
      likeCount: data['likeCount'] as int? ?? 0,
    );
  }

  @override
  Future<({bool success, int likeCount})> unlikePost(String postId) async {
    final response = await _client.post(ApiEndpoints.unlike, data: {'postId': postId});
    final data = response.data as Map<String, dynamic>;
    return (
      success: data['success'] as bool? ?? true,
      likeCount: data['likeCount'] as int? ?? 0,
    );
  }

  @override
  Future<Comment> postComment({
    required String postId,
    required String body,
    String? parentCommentId,
  }) async {
    final data = <String, dynamic>{'postId': postId, 'body': body};
    if (parentCommentId != null) data['parentCommentId'] = parentCommentId;

    final response = await _client.post(ApiEndpoints.comments, data: data);
    return CommentModel.fromJson(response.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<({List<Comment> items, String? nextCursor})> getComments({
    required String postId,
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;

    final response = await _client.get(
      ApiEndpoints.commentsForPost(postId),
      queryParameters: params,
    );
    final resData = response.data as Map<String, dynamic>;
    final items = (resData['items'] as List)
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    return (items: items, nextCursor: resData['nextCursor'] as String?);
  }

  @override
  Future<void> deletePost(String postId) async {
    await _client.delete(ApiEndpoints.postById(postId));
  }

  @override
  Future<bool> deleteComment(String commentId) async {
    final response = await _client.delete(ApiEndpoints.deleteComment(commentId));
    return (response.data as Map<String, dynamic>)['success'] as bool;
  }

  @override
  Future<void> toggleBookmark(String postId) async {
    await _client.post('${ApiEndpoints.posts}/$postId/bookmark');
  }
}
