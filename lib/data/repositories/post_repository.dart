import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/paginated.dart';
import '../models/post.dart';

/// Posts: reading lists, the create → upload → submit lifecycle, and author
/// controls (edit, visibility, delete).
class PostRepository {
  PostRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Post>> _list(
    String path, {
    String? cursor,
    int limit = 20,
    Map<String, dynamic>? query,
  }) async {
    final json = await _api.get<Json>(
      path,
      query: {'cursor': cursor, 'limit': limit, ...?query},
    );
    return Paginated.fromJson(json, Post.fromJson);
  }

  /// Personalised home feed (followed traders, pages and joined groups).
  Future<Paginated<Post>> feed({String? cursor}) => _list('/api/feed', cursor: cursor);

  Future<Paginated<Post>> trending({String? cursor, int limit = 20}) =>
      _list('/api/discover/trending-posts', cursor: cursor, limit: limit);

  Future<Paginated<TrendingTopic>> trendingTopics({int limit = 15}) async {
    final json = await _api.get<Json>(
      '/api/discover/trending-topics',
      query: {'limit': limit},
    );
    return Paginated.fromJson(json, TrendingTopic.fromJson);
  }

  Future<Paginated<Post>> search(String query, {String? cursor}) =>
      _list('/api/posts/search', cursor: cursor, query: {'q': query});

  /// Every post the caller wrote, any status (drafts, in review, rejected…).
  Future<Paginated<Post>> mine({String? cursor}) =>
      _list('/api/posts/mine', cursor: cursor);

  /// Another trader's posts the viewer is allowed to see.
  Future<Paginated<Post>> byAuthor(String userId, {String? cursor}) async {
    try {
      return await _list('/api/v1/users/$userId/posts', cursor: cursor);
    } on ApiException catch (e) {
      // Private profile, or a backend that predates the route.
      if (e.isNotFound) return Paginated.empty();
      rethrow;
    }
  }

  Future<Paginated<Post>> bookmarks({String? cursor}) =>
      _list('/api/posts/bookmarks', cursor: cursor);

  Future<Post> byId(String postId) async =>
      Post.fromJson(await _api.get<Json>('/api/posts/$postId'));

  /// Step 1 of publishing: a draft. Images/video attach to it next.
  Future<Post> createDraft({
    required PostType type,
    required String caption,
    required PostVisibility visibility,
    required String language,
    int imageCount = 0,
  }) async {
    final body = <String, Object?>{
      'type': type.name,
      'caption': caption.trim(),
      'visibility': visibility.wire,
      'language': language,
      // Placeholders: the upload-url call replaces them with the real keys.
      if (type == PostType.image)
        'mediaRefs': List.filled(imageCount.clamp(1, 10), 'pending'),
      if (type == PostType.video) 'mediaRef': 'pending',
    };
    return Post.fromJson(await _api.post<Json>('/api/posts', body: body));
  }

  /// Personal post → platform review queue.
  Future<void> submitForReview(String postId) =>
      _api.post<Json>('/api/posts/$postId/submit');

  /// Group post → group moderators first (stage 1), then the platform.
  Future<void> submitToGroup(String groupId, String postId) =>
      _api.post<Json>('/api/groups/$groupId/posts', body: {'postId': postId});

  /// Page post → platform review (single stage).
  Future<void> submitToPage(String pageId, String postId) =>
      _api.post<Json>('/api/pages/$pageId/posts', body: {'postId': postId});

  Future<Post> updateCaption(String postId, String caption) async =>
      Post.fromJson(
        await _api.put<Json>('/api/posts/$postId', body: {'caption': caption.trim()}),
      );

  Future<PostVisibility> updateVisibility(
    String postId,
    PostVisibility visibility,
  ) async {
    final json = await _api.patch<Json>(
      '/api/posts/$postId/visibility',
      body: {'visibility': visibility.wire},
    );
    return PostVisibility.fromWire(json['visibility']);
  }

  Future<void> delete(String postId) => _api.delete<Json>('/api/posts/$postId');
}
