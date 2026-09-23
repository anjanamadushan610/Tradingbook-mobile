import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/social_repository.dart';
import '../models/user_model.dart';

class SocialRepositoryImpl implements SocialRepository {
  final DioClient _client;

  SocialRepositoryImpl({required DioClient client}) : _client = client;

  @override
  Future<bool> followUser(String targetUserId) async {
    final response = await _client.post(
      ApiEndpoints.follow,
      data: {'targetUserId': targetUserId},
    );
    return (response.data as Map<String, dynamic>)['success'] as bool;
  }

  @override
  Future<bool> unfollowUser(String targetUserId) async {
    final response = await _client.post(
      ApiEndpoints.unfollow,
      data: {'targetUserId': targetUserId},
    );
    return (response.data as Map<String, dynamic>)['success'] as bool;
  }

  @override
  Future<bool> blockUser(String targetUserId) async {
    final response = await _client.post(
      ApiEndpoints.block,
      data: {'targetUserId': targetUserId},
    );
    return (response.data as Map<String, dynamic>)['success'] as bool;
  }

  @override
  Future<({List<User> items, String? nextCursor})> getFollowing({
    required String userId,
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    final response = await _client.get(
      ApiEndpoints.following(userId),
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    return (items: items, nextCursor: data['nextCursor'] as String?);
  }

  @override
  Future<({List<User> items, String? nextCursor})> getFollowers({
    required String userId,
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    final response = await _client.get(
      ApiEndpoints.followers(userId),
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    return (items: items, nextCursor: data['nextCursor'] as String?);
  }

  @override
  Future<({int followersCount, int followingCount})> getFollowCounts(
    String userId,
  ) async {
    final response = await _client.get(ApiEndpoints.followCounts(userId));
    final data = response.data as Map<String, dynamic>;
    return (
      followersCount: data['followersCount'] as int,
      followingCount: data['followingCount'] as int,
    );
  }

  @override
  Future<bool> isFollowing(String targetId) async {
    final response = await _client.get(ApiEndpoints.isFollowing(targetId));
    return (response.data as Map<String, dynamic>)['following'] as bool;
  }

  @override
  Future<({List<User> items, String? nextCursor})> searchUsers({
    required String query,
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{'q': query, 'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    final response = await _client.get(
      ApiEndpoints.usersSearch,
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    return (items: items, nextCursor: data['nextCursor'] as String?);
  }

  @override
  Future<User> getUserProfile(String userId) async {
    final response = await _client.get(ApiEndpoints.userById(userId));
    return UserModel.fromJson(response.data as Map<String, dynamic>).toEntity();
  }
}
