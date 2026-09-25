import 'dart:io';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/paginated.dart';
import '../models/community.dart';
import '../models/post.dart';

/// Groups (two-stage moderation, membership roles) and Pages (brand/creator
/// channels, single-stage moderation).
class CommunityRepository {
  CommunityRepository(this._api);

  final ApiClient _api;

  // ─── Groups ────────────────────────────────────────────────────────────────

  Future<Paginated<Group>> myGroups({String? cursor, int limit = 30}) async {
    final json = await _api.get<Json>(
      '/api/groups/mine',
      query: {'cursor': cursor, 'limit': limit},
    );
    return Paginated.fromJson(json, Group.fromJson);
  }

  Future<Paginated<Group>> discoverGroups({String? cursor, int limit = 20}) async {
    final json = await _api.get<Json>(
      '/api/discover/groups',
      query: {'cursor': cursor, 'limit': limit},
    );
    return Paginated.fromJson(json, Group.fromJson);
  }

  Future<Group> group(String groupId) async =>
      Group.fromJson(await _api.get<Json>('/api/groups/$groupId'));

  Future<GroupMembership> membership(String groupId) async =>
      GroupMembership.fromJson(await _api.get<Json>('/api/groups/$groupId/is-member'));

  Future<Paginated<Post>> groupFeed(String groupId, {String? cursor}) async {
    final json = await _api.get<Json>(
      '/api/groups/$groupId/feed',
      query: {'cursor': cursor, 'limit': 20},
    );
    return Paginated.fromJson(json, Post.fromJson);
  }

  Future<Group> createGroup({
    required String name,
    required String description,
    required bool isPrivate,
  }) async {
    final json = await _api.post<Json>('/api/groups', body: {
      'name': name.trim(),
      'description': description.trim(),
      'visibility': isPrivate ? 'private' : 'public',
    });
    return Group.fromJson(json);
  }

  Future<Group> updateGroup(
    String groupId, {
    String? name,
    String? description,
    bool? isPrivate,
  }) async {
    final json = await _api.put<Json>('/api/groups/$groupId', body: {
      'name': ?name?.trim(),
      'description': ?description?.trim(),
      if (isPrivate != null) 'visibility': isPrivate ? 'private' : 'public',
    });
    return Group.fromJson(json);
  }

  Future<Group> uploadGroupImage(String groupId, File file, {required String kind}) async {
    final json = await _api.uploadFile('/api/groups/$groupId/$kind', file: file);
    return Group.fromJson(json['group'] as Json);
  }

  Future<void> deleteGroup(String groupId) => _api.delete<Json>('/api/groups/$groupId');

  Future<void> joinGroup(String groupId) => _api.post<Json>('/api/groups/$groupId/join');

  Future<void> leaveGroup(String groupId) => _api.post<Json>('/api/groups/$groupId/leave');

  Future<Paginated<GroupMember>> members(String groupId, {String? cursor}) async {
    final json = await _api.get<Json>(
      '/api/groups/$groupId/members',
      query: {'cursor': cursor, 'limit': 50},
    );
    return Paginated.fromJson(json, GroupMember.fromJson);
  }

  Future<void> inviteMember(String groupId, String userId) =>
      _api.post<Json>('/api/groups/$groupId/invite', body: {'userId': userId});

  Future<void> setMemberRole(String groupId, String userId, GroupRole role) =>
      _api.post<Json>('/api/groups/$groupId/role', body: {'userId': userId, 'role': role.name});

  Future<void> removeMember(String groupId, String userId) =>
      _api.post<Json>('/api/groups/$groupId/remove-member', body: {'userId': userId});

  /// Pending requests to join a private group (admin+). Approving is an
  /// invite; declining drops the request.
  Future<Paginated<PageFollower>> joinRequests(String groupId, {String? cursor}) async {
    try {
      final json = await _api.get<Json>(
        '/api/groups/$groupId/requests',
        query: {'cursor': cursor, 'limit': 50},
      );
      return Paginated(
        items: (json['items'] as List? ?? const [])
            .cast<Json>()
            .map((j) => PageFollower.fromJson({...j, 'followedAt': j['requestedAt']}))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
      );
    } on ApiException catch (e) {
      if (e.isNotFound) return Paginated.empty();
      rethrow;
    }
  }

  Future<void> declineJoinRequest(String groupId, String userId) =>
      _api.post<Json>('/api/groups/$groupId/requests/$userId/decline');

  /// Posts waiting for this group's moderators (stage 1).
  Future<Paginated<Post>> pendingGroupPosts(String groupId, {String? cursor}) async {
    try {
      final json = await _api.get<Json>(
        '/api/groups/$groupId/pending',
        query: {'cursor': cursor, 'limit': 20},
      );
      return Paginated.fromJson(json, Post.fromJson);
    } on ApiException catch (e) {
      if (e.isNotFound) return Paginated.empty();
      rethrow;
    }
  }

  Future<void> approveGroupPost(String groupId, String postId) =>
      _api.post<Json>('/api/groups/$groupId/posts/$postId/approve');

  Future<void> rejectGroupPost(String groupId, String postId, String reason) =>
      _api.post<Json>('/api/groups/$groupId/posts/$postId/reject', body: {'reason': reason});

  // ─── Pages ─────────────────────────────────────────────────────────────────

  Future<Paginated<CommunityPage>> myPages({String? cursor, int limit = 50}) async {
    final json = await _api.get<Json>(
      '/api/pages/mine',
      query: {'cursor': cursor, 'limit': limit},
    );
    return Paginated.fromJson(json, CommunityPage.fromJson);
  }

  Future<Paginated<CommunityPage>> discoverPages({String? cursor, int limit = 20}) async {
    final json = await _api.get<Json>(
      '/api/discover/pages',
      query: {'cursor': cursor, 'limit': limit},
    );
    return Paginated.fromJson(json, CommunityPage.fromJson);
  }

  Future<Paginated<CommunityPage>> allPages({String? cursor}) async {
    final json = await _api.get<Json>('/api/pages', query: {'cursor': cursor, 'limit': 30});
    return Paginated.fromJson(json, CommunityPage.fromJson);
  }

  Future<CommunityPage> page(String pageId) async =>
      CommunityPage.fromJson(await _api.get<Json>('/api/pages/$pageId'));

  Future<Paginated<Post>> pageFeed(String pageId, {String? cursor}) async {
    final json = await _api.get<Json>(
      '/api/pages/$pageId/feed',
      query: {'cursor': cursor, 'limit': 20},
    );
    return Paginated.fromJson(json, Post.fromJson);
  }

  Future<bool> isFollowingPage(String pageId) async {
    try {
      final json = await _api.get<Json>('/api/pages/$pageId/is-following');
      return json['following'] == true;
    } on ApiException catch (e) {
      if (!e.isNotFound) rethrow;
      // Older backend: ranked discovery excludes followed pages, so absence
      // from it (among pages that exist) means "following". Same inference
      // the web app makes.
      final discover = await discoverPages(limit: 50);
      return !discover.items.any((p) => p.id == pageId);
    }
  }

  Future<void> followPage(String pageId) => _api.post<Json>('/api/pages/$pageId/follow');

  Future<void> unfollowPage(String pageId) => _api.post<Json>('/api/pages/$pageId/unfollow');

  Future<CommunityPage> createPage({required String name, required String description}) async {
    final json = await _api.post<Json>(
      '/api/pages',
      body: {'name': name.trim(), 'description': description.trim()},
    );
    return CommunityPage.fromJson(json);
  }

  Future<CommunityPage> updatePage(String pageId, {String? name, String? description}) async {
    final json = await _api.put<Json>('/api/pages/$pageId', body: {
      'name': ?name?.trim(),
      'description': ?description?.trim(),
    });
    return CommunityPage.fromJson(json);
  }

  Future<CommunityPage> uploadPageImage(String pageId, File file, {required String kind}) async {
    final json = await _api.uploadFile('/api/pages/$pageId/$kind', file: file);
    return CommunityPage.fromJson(json['page'] as Json);
  }

  Future<void> deletePage(String pageId) => _api.delete<Json>('/api/pages/$pageId');

  Future<List<PageRoleEntry>> pageRoles(String pageId) async {
    final json = await _api.get<Json>('/api/pages/$pageId/roles');
    return (json['roles'] as List? ?? const [])
        .cast<Json>()
        .map(PageRoleEntry.fromJson)
        .toList();
  }

  Future<void> setPageRole(String pageId, String userId, PageRole role) =>
      _api.post<Json>('/api/pages/$pageId/role', body: {'userId': userId, 'role': role.name});

  Future<void> removePageRole(String pageId, String userId) =>
      _api.post<Json>('/api/pages/$pageId/remove-role', body: {'userId': userId});

  Future<Paginated<PageFollower>> pageFollowers(String pageId, {String? cursor}) async {
    final json = await _api.get<Json>(
      '/api/pages/$pageId/followers',
      query: {'cursor': cursor, 'limit': 50},
    );
    return Paginated.fromJson(json, PageFollower.fromJson);
  }
}
