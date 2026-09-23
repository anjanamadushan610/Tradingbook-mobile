class ApiEndpoints {
  ApiEndpoints._();

  static const String _baseUrl = 'https://api.tradingbooknet.com';
  static const String _devUrl = 'http://localhost:8787';
  static const String _wsBase = 'wss://api.tradingbooknet.com';

  // Toggle for dev vs prod
  static const bool _isDev = false;

  static String get baseUrl => _isDev ? _devUrl : _baseUrl;
  static String get wsBaseUrl => _isDev ? 'ws://localhost:8787' : _wsBase;

  // ===  Auth ===
  static const String signup = '/api/v1/auth/signup';
  static const String login = '/api/v1/auth/login';
  static const String refresh = '/api/v1/auth/refresh';
  static const String me = '/api/v1/me';
  static const String usersSearch = '/api/v1/users/search';
  static String userById(String id) => '/api/v1/users/$id';

  // === Social ===
  static const String follow = '/api/social/follow';
  static const String unfollow = '/api/social/unfollow';
  static const String block = '/api/social/block';
  static String following(String userId) => '/api/social/following/$userId';
  static String followers(String userId) => '/api/social/followers/$userId';
  static String followCounts(String userId) => '/api/social/counts/$userId';
  static String isFollowing(String targetId) => '/api/social/is-following/$targetId';

  // === Posts ===
  static const String posts = '/api/posts';
  static String postSubmit(String postId) => '/api/posts/$postId/submit';
  static const String myPosts = '/api/posts/mine';
  static const String searchPosts = '/api/posts/search';
  static String postById(String postId) => '/api/posts/$postId';

  // === Media ===
  static const String imageUploadUrl = '/api/media/image/upload-url';
  static const String videoUploadUrl = '/api/media/video/upload-url';
  static String mediaStatus(String mediaId) => '/api/media/status/$mediaId';
  static String deleteMedia(String mediaId) => '/api/media/$mediaId';

  // === Feed ===
  static const String feed = '/api/feed';

  // === Engagement ===
  static const String like = '/api/engagement/like';
  static const String unlike = '/api/engagement/unlike';
  static String likes(String postId) => '/api/engagement/likes/$postId';
  static const String comments = '/api/engagement/comments';
  static String commentsForPost(String postId) => '/api/engagement/comments/$postId';
  static String deleteComment(String commentId) => '/api/engagement/comments/$commentId';
  static const String behavior = '/api/engagement/behavior';
  static const String behaviorBatch = '/api/engagement/behavior/batch';

  // === Notifications ===
  static String get notificationsWs => '${ApiEndpoints.wsBaseUrl}/api/notifications/ws';
  static const String notifications = '/api/notifications';
  static const String notificationsRead = '/api/notifications/read';
  static const String notificationsReadAll = '/api/notifications/read-all';
  static const String notificationsUnreadCount = '/api/notifications/unread-count';

  // === Markets ===
  static const String marketsDetails = '/api/markets/details';

  // === Groups ===
  static const String groups = '/api/groups';
  static const String myGroups = '/api/groups/mine';
  static String groupById(String groupId) => '/api/groups/$groupId';
  static String groupJoin(String groupId) => '/api/groups/$groupId/join';
  static String groupLeave(String groupId) => '/api/groups/$groupId/leave';
  static String groupMembers(String groupId) => '/api/groups/$groupId/members';
  static String groupPosts(String groupId) => '/api/groups/$groupId/posts';
  static String groupFeed(String groupId) => '/api/groups/$groupId/feed';

  // === Health ===
  static const String health = '/health';
}
