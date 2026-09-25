import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/paginated.dart';
import '../models/comment.dart';
import '../models/post.dart';

/// Likes, bookmarks, comments and behaviour telemetry.
///
/// Engagement state is held in one [ValueNotifier] per post, shared by every
/// widget showing that post — liking it on the detail screen updates the card
/// in the feed underneath without a refetch. Stats for all cards built in the
/// same frame are loaded with one batch request.
class EngagementRepository {
  EngagementRepository(this._api, {required this.isSignedIn});

  final ApiClient _api;
  final bool Function() isSignedIn;

  final Map<String, ValueNotifier<PostStats?>> _stats = {};
  final Set<String> _queue = {};
  Timer? _flushTimer;
  bool _batchSupported = true;

  /// Live stats for [postId]; null until loaded. Triggers a (batched) load
  /// the first time a post is seen.
  ValueListenable<PostStats?> statsFor(String postId, {PostStats? seed}) {
    final existing = _stats[postId];
    if (existing != null) return existing;
    final notifier = ValueNotifier<PostStats?>(seed);
    _stats[postId] = notifier;
    _queue.add(postId);
    _flushTimer ??= Timer(const Duration(milliseconds: 16), _flush);
    return notifier;
  }

  /// Forget cached state (pull-to-refresh, sign-in/out).
  void resetStats() {
    for (final n in _stats.values) {
      n.dispose();
    }
    _stats.clear();
  }

  Future<void> refreshStats(String postId) async {
    _queue.add(postId);
    await _flush();
  }

  Future<void> _flush() async {
    _flushTimer = null;
    final ids = _queue.toList();
    _queue.clear();
    if (ids.isEmpty) return;

    if (_batchSupported) {
      try {
        for (var i = 0; i < ids.length; i += 50) {
          final chunk = ids.sublist(i, (i + 50).clamp(0, ids.length));
          final json = await _api.get<Json>(
            '/api/engagement/stats',
            query: {'postIds': chunk.join(',')},
          );
          for (final item in (json['items'] as List? ?? const [])) {
            final map = item as Json;
            _stats[map['postId']]?.value = PostStats.fromJson(map);
          }
        }
        return;
      } on ApiException catch (e) {
        if (e.isNotFound) {
          _batchSupported = false;
        } else {
          return;
        }
      }
    }
    // Fallback for a backend without the batch route: two reads per post.
    await Future.wait(ids.map(_loadSingle));
  }

  Future<void> _loadSingle(String postId) async {
    try {
      final likes = await _api.get<Json>('/api/engagement/likes/$postId');
      var bookmarked = false;
      if (isSignedIn()) {
        final b = await _api.get<Json>('/api/engagement/bookmarks/$postId');
        bookmarked = b['bookmarked'] == true;
      }
      _stats[postId]?.value = PostStats(
        likeCount: (likes['count'] as num?)?.toInt() ?? 0,
        commentCount: _stats[postId]?.value?.commentCount,
        hasLiked: likes['hasLiked'] == true,
        bookmarked: bookmarked,
      );
    } on ApiException {
      // Leave the card without counts rather than failing it.
    }
  }

  void _update(String postId, PostStats Function(PostStats) change) {
    final n = _stats[postId];
    if (n == null) return;
    n.value = change(n.value ?? PostStats.empty);
  }

  /// Optimistic like/unlike; rolls back on failure and adopts the server's
  /// authoritative count on success.
  Future<void> toggleLike(String postId) async {
    final before = _stats[postId]?.value ?? PostStats.empty;
    final liking = !before.hasLiked;
    _update(postId, (s) => s.copyWith(
          hasLiked: liking,
          likeCount: (s.likeCount + (liking ? 1 : -1)).clamp(0, 1 << 31),
        ));
    try {
      final json = await _api.post<Json>(
        liking ? '/api/engagement/like' : '/api/engagement/unlike',
        body: {'postId': postId},
      );
      final count = (json['likeCount'] as num?)?.toInt();
      if (count != null) _update(postId, (s) => s.copyWith(likeCount: count));
    } catch (_) {
      _stats[postId]?.value = before;
      rethrow;
    }
  }

  Future<bool> toggleBookmark(String postId) async {
    final before = _stats[postId]?.value ?? PostStats.empty;
    final saving = !before.bookmarked;
    _update(postId, (s) => s.copyWith(bookmarked: saving));
    try {
      await _api.post<Json>(
        saving ? '/api/engagement/bookmark' : '/api/engagement/unbookmark',
        body: {'postId': postId},
      );
      return saving;
    } catch (_) {
      _stats[postId]?.value = before;
      rethrow;
    }
  }

  void _bumpComments(String postId, int delta) {
    _update(postId, (s) => s.copyWith(
          commentCount: ((s.commentCount ?? 0) + delta).clamp(0, 1 << 31),
        ));
  }

  // --- comments ---

  Future<Paginated<Comment>> comments(String postId, {String? cursor}) async {
    final json = await _api.get<Json>(
      '/api/engagement/comments/$postId',
      query: {'cursor': cursor, 'limit': 50},
    );
    return Paginated.fromJson(json, Comment.fromJson);
  }

  Future<Comment> addComment({
    required String postId,
    required String body,
    String? parentCommentId,
  }) async {
    final json = await _api.post<Json>(
      '/api/engagement/comments',
      body: {
        'postId': postId,
        'body': body.trim(),
        'parentCommentId': ?parentCommentId,
      },
    );
    _bumpComments(postId, 1);
    return Comment.fromJson(json);
  }

  Future<Comment> editComment(Comment comment, String body) async {
    final json = await _api.put<Json>(
      '/api/engagement/comments/${comment.id}',
      body: {'body': body.trim()},
    );
    final updated = Comment.fromJson({...json, 'postId': comment.postId});
    return comment.copyWith(body: updated.body.isEmpty ? body.trim() : updated.body);
  }

  Future<void> deleteComment(Comment comment) async {
    await _api.delete<Json>('/api/engagement/comments/${comment.id}');
    _bumpComments(comment.postId, -1);
  }

  Future<Comment> toggleCommentLike(Comment comment) async {
    final json = await _api.post<Json>(
      '/api/engagement/comments/${comment.id}/${comment.hasLiked ? 'unlike' : 'like'}',
    );
    return comment.copyWith(
      hasLiked: json['liked'] == true,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? comment.likeCount,
    );
  }

  // --- telemetry ---

  final List<Json> _events = [];
  Timer? _eventTimer;

  /// Queue a behaviour event (view/dwell) for the recommender; sent in
  /// batches. Fire-and-forget: telemetry must never affect the UI.
  void track({
    required String eventType,
    required String postId,
    required num value,
    String contextType = 'feed',
    bool isPrivateGroup = false,
  }) {
    if (!isSignedIn()) return;
    _events.add({
      'eventType': eventType,
      'postId': postId,
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'contextType': contextType,
      'isPrivateGroup': isPrivateGroup,
    });
    if (_events.length >= 50) {
      flushEvents();
    } else {
      _eventTimer ??= Timer(const Duration(seconds: 20), flushEvents);
    }
  }

  Future<void> flushEvents() async {
    _eventTimer?.cancel();
    _eventTimer = null;
    if (_events.isEmpty) return;
    final batch = List<Json>.of(_events.take(100));
    _events.removeRange(0, batch.length);
    try {
      await _api.post<Json>('/api/engagement/behavior/batch', body: {'events': batch});
    } catch (_) {}
  }
}
