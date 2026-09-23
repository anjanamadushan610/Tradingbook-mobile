import '../entities/user.dart';

abstract class SocialRepository {
  Future<bool> followUser(String targetUserId);
  Future<bool> unfollowUser(String targetUserId);
  Future<bool> blockUser(String targetUserId);
  Future<({List<User> items, String? nextCursor})> getFollowing({
    required String userId,
    String? cursor,
    int limit = 20,
  });
  Future<({List<User> items, String? nextCursor})> getFollowers({
    required String userId,
    String? cursor,
    int limit = 20,
  });
  Future<({int followersCount, int followingCount})> getFollowCounts(
    String userId,
  );
  Future<bool> isFollowing(String targetId);
  Future<({List<User> items, String? nextCursor})> searchUsers({
    required String query,
    String? cursor,
    int limit = 20,
  });
  Future<User> getUserProfile(String userId);
}
