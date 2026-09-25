import 'dart:async';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/paginated.dart';
import '../models/user.dart';

/// Profiles and the social graph.
///
/// Feeds, comments and follow lists return author *ids* only, so the UI
/// resolves names/avatars through [profile], which caches and de-duplicates:
/// twenty cards by the same author cost one request, and a whole screen's
/// worth of ids is fetched in one batch call when the backend supports it.
class UserRepository {
  UserRepository(this._api);

  final ApiClient _api;

  final Map<String, UserProfile?> _cache = {};
  final Map<String, Completer<UserProfile?>> _pending = {};
  final Set<String> _queue = {};
  Timer? _flushTimer;
  bool _batchSupported = true;

  /// Cached profile or null (unknown / private / deleted). Never throws.
  UserProfile? cached(String userId) => _cache[userId];

  bool isCached(String userId) => _cache.containsKey(userId);

  /// Resolve a profile for display. Calls made in the same frame are
  /// coalesced into one batch request.
  Future<UserProfile?> profile(String userId) {
    if (userId.isEmpty) return Future.value(null);
    if (_cache.containsKey(userId)) return Future.value(_cache[userId]);
    final existing = _pending[userId];
    if (existing != null) return existing.future;
    final completer = Completer<UserProfile?>();
    _pending[userId] = completer;
    _queue.add(userId);
    _flushTimer ??= Timer(const Duration(milliseconds: 16), _flush);
    return completer.future;
  }

  void primeCache(UserProfile profile) => _cache[profile.id] = profile;

  void invalidate(String userId) => _cache.remove(userId);

  Future<void> _flush() async {
    _flushTimer = null;
    final ids = _queue.toList();
    _queue.clear();
    if (ids.isEmpty) return;

    final resolved = <String, UserProfile?>{};
    if (_batchSupported && ids.length > 1) {
      try {
        for (var i = 0; i < ids.length; i += 50) {
          final chunk = ids.sublist(i, (i + 50).clamp(0, ids.length));
          final json = await _api.get<Json>(
            '/api/v1/users/batch',
            query: {'ids': chunk.join(',')},
          );
          for (final item in (json['items'] as List? ?? const [])) {
            final p = UserProfile.fromJson(item as Json);
            resolved[p.id] = p;
          }
        }
        for (final id in ids) {
          resolved.putIfAbsent(id, () => null);
        }
      } on ApiException catch (e) {
        // Older backend without the batch route: fall back to per-id reads.
        if (e.isNotFound) _batchSupported = false;
        resolved.clear();
      }
    }
    if (resolved.isEmpty) {
      await Future.wait(ids.map((id) async {
        try {
          resolved[id] = await fetchProfile(id);
        } on ApiException {
          resolved[id] = null;
        }
      }));
    }

    for (final id in ids) {
      final p = resolved[id];
      _cache[id] = p;
      _pending.remove(id)?.complete(p);
    }
  }

  /// Full profile. Private profiles 404 for everyone but their owner.
  Future<UserProfile> fetchProfile(String userId) async {
    final p = UserProfile.fromJson(await _api.get<Json>('/api/v1/users/$userId'));
    _cache[userId] = p;
    return p;
  }

  Future<Paginated<UserProfile>> search(String query, {String? cursor}) async {
    final json = await _api.get<Json>(
      '/api/v1/users/search',
      query: {'q': query, 'cursor': cursor, 'limit': 20},
    );
    final page = Paginated.fromJson(json, UserProfile.fromJson);
    for (final p in page.items) {
      _cache[p.id] = p;
    }
    return page;
  }

  Future<Paginated<UserProfile>> suggestedTraders({String? cursor, int limit = 20}) =>
      _traders('/api/discover/suggested-traders', cursor, limit);

  Future<Paginated<UserProfile>> popularTraders({String? cursor, int limit = 20}) =>
      _traders('/api/discover/popular-traders', cursor, limit);

  Future<Paginated<UserProfile>> _traders(String path, String? cursor, int limit) async {
    final json = await _api.get<Json>(path, query: {'cursor': cursor, 'limit': limit});
    return Paginated.fromJson(json, UserProfile.fromJson);
  }

  // --- social graph ---

  Future<FollowCounts> followCounts(String userId) async =>
      FollowCounts.fromJson(await _api.get<Json>('/api/social/counts/$userId'));

  Future<bool> isFollowing(String userId) async {
    final json = await _api.get<Json>('/api/social/is-following/$userId');
    return json['following'] == true;
  }

  /// Idempotent from the UI's point of view: the API answers 409 when the
  /// edge already is in the requested state (a double tap, another device).
  Future<void> follow(String userId) => _ignoring(
        'already_following',
        () => _api.post<Json>('/api/social/follow', body: {'targetUserId': userId}),
      );

  Future<void> unfollow(String userId) => _ignoring(
        'not_following',
        () => _api.post<Json>('/api/social/unfollow', body: {'targetUserId': userId}),
      );

  Future<void> _ignoring(String code, Future<Object?> Function() call) async {
    try {
      await call();
    } on ApiException catch (e) {
      if (e.code != code) rethrow;
    }
  }

  Future<void> block(String userId) =>
      _api.post<Json>('/api/social/block', body: {'targetUserId': userId});

  Future<void> unblock(String userId) =>
      _api.post<Json>('/api/social/unblock', body: {'targetUserId': userId});

  Future<Paginated<FollowEdge>> blocked({String? cursor}) async {
    final json = await _api.get<Json>(
      '/api/social/blocked',
      query: {'cursor': cursor, 'limit': 50},
    );
    return Paginated.fromJson(json, FollowEdge.fromJson);
  }

  Future<Paginated<FollowEdge>> followers(String userId, {String? cursor}) =>
      _edges('/api/social/followers/$userId', cursor);

  Future<Paginated<FollowEdge>> following(String userId, {String? cursor}) =>
      _edges('/api/social/following/$userId', cursor);

  Future<Paginated<FollowEdge>> _edges(String path, String? cursor) async {
    final json = await _api.get<Json>(path, query: {'cursor': cursor, 'limit': 30});
    return Paginated.fromJson(json, FollowEdge.fromJson);
  }
}
