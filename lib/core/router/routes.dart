/// Every navigable location. Builders take ids so call sites never assemble
/// paths by hand.
class Routes {
  Routes._();

  static const splash = '/splash';

  // auth
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static String verifyEmail(String email) =>
      '/verify-email?email=${Uri.encodeQueryComponent(email)}';
  static String resetPassword([String email = '']) =>
      '/reset-password?email=${Uri.encodeQueryComponent(email)}';

  // tabs
  static const home = '/home';
  static const discover = '/discover';
  static const markets = '/markets';
  static const communities = '/communities';
  static const me = '/me';

  // content
  static String compose({String? groupId, String? pageId}) {
    final q = <String>[
      if (groupId != null) 'groupId=$groupId',
      if (pageId != null) 'pageId=$pageId',
    ];
    return q.isEmpty ? '/compose' : '/compose?${q.join('&')}';
  }

  static String post(String id, {bool focusComment = false}) =>
      focusComment ? '/post/$id?comment=1' : '/post/$id';
  static String user(String id) => '/user/$id';
  static String followers(String id) => '/user/$id/connections?tab=followers';
  static String following(String id) => '/user/$id/connections?tab=following';
  static String search([String q = '']) =>
      q.isEmpty ? '/search' : '/search?q=${Uri.encodeQueryComponent(q)}';
  static const notifications = '/notifications';
  static const bookmarks = '/bookmarks';
  static const editProfile = '/me/edit';
  static const myPosts = '/me/posts';

  // groups
  static const createGroup = '/groups/new';
  static String group(String id) => '/group/$id';
  static String editGroup(String id) => '/group/$id/edit';
  static String groupMembers(String id) => '/group/$id/members';
  static String groupPending(String id) => '/group/$id/pending';

  // pages
  static const createPage = '/pages/new';
  static String page(String id) => '/page/$id';
  static String editPage(String id) => '/page/$id/edit';
  static String pageTeam(String id) => '/page/$id/team';

  // markets
  static String market(String symbol) => '/market/$symbol';

  // settings
  static const settings = '/settings';
  static const changePassword = '/settings/password';
  static const blockedUsers = '/settings/blocked';
  static const deleteAccount = '/settings/delete-account';

  // moderation
  static const moderation = '/moderation';
  static const moderationAudit = '/moderation/audit';
  static const moderationReports = '/moderation/reports';

  static const authPaths = {
    login,
    signup,
    forgotPassword,
    '/verify-email',
    '/reset-password',
  };
}
