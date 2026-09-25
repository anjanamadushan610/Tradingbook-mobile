import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/pages/forgot_password_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/reset_password_page.dart';
import '../../features/auth/pages/signup_page.dart';
import '../../features/auth/pages/verify_email_page.dart';
import '../../features/auth/session_cubit.dart';
import '../../features/bookmarks/bookmarks_page.dart';
import '../../features/communities/communities_page.dart';
import '../../features/discover/discover_page.dart';
import '../../features/discover/search_page.dart';
import '../../features/feed/feed_page.dart';
import '../../features/groups/group_detail_page.dart';
import '../../features/groups/group_form_page.dart';
import '../../features/groups/group_members_page.dart';
import '../../features/groups/group_pending_page.dart';
import '../../features/markets/market_detail_page.dart';
import '../../features/markets/markets_page.dart';
import '../../features/moderation/moderation_audit_page.dart';
import '../../features/moderation/moderation_page.dart';
import '../../features/moderation/moderation_reports_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/pages/page_detail_page.dart';
import '../../features/pages/page_form_page.dart';
import '../../features/pages/page_team_page.dart';
import '../../features/post/compose_page.dart';
import '../../features/post/post_detail_page.dart';
import '../../features/profile/connections_page.dart';
import '../../features/profile/edit_profile_page.dart';
import '../../features/profile/my_posts_page.dart';
import '../../features/profile/my_profile_page.dart';
import '../../features/profile/user_profile_page.dart';
import '../../features/settings/blocked_users_page.dart';
import '../../features/settings/change_password_page.dart';
import '../../features/settings/delete_account_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/shell/main_shell.dart';
import '../../features/shell/splash_page.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(SessionCubit session) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: _StreamListenable(session.stream),
    redirect: (context, state) {
      final s = session.state;
      final path = state.uri.path;
      final onAuth = Routes.authPaths.contains(path);
      final onSplash = path == Routes.splash;

      if (s is SessionUnknown) return onSplash ? null : Routes.splash;
      if (s is Unauthenticated) return onAuth ? null : Routes.login;
      // Authenticated: leave the auth flow / splash for the feed.
      if (onAuth || onSplash) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),

      // ── auth ──
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.signup, builder: (_, _) => const SignupPage()),
      GoRoute(path: Routes.forgotPassword, builder: (_, _) => const ForgotPasswordPage()),
      GoRoute(
        path: '/verify-email',
        builder: (_, s) => VerifyEmailPage(email: s.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, s) => ResetPasswordPage(email: s.uri.queryParameters['email'] ?? ''),
      ),

      // ── tabs ──
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, _) => const FeedPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.discover, builder: (_, _) => const DiscoverPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.markets, builder: (_, _) => const MarketsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.communities,
              builder: (_, s) => CommunitiesPage(initialTab: s.uri.queryParameters['tab']),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.me, builder: (_, _) => const MyProfilePage()),
          ]),
        ],
      ),

      // ── full-screen routes ──
      GoRoute(
        path: '/compose',
        pageBuilder: (_, s) => MaterialPage(
          fullscreenDialog: true,
          child: ComposePage(
            groupId: s.uri.queryParameters['groupId'],
            pageId: s.uri.queryParameters['pageId'],
          ),
        ),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (_, s) => PostDetailPage(
          postId: s.pathParameters['id']!,
          focusComment: s.uri.queryParameters['comment'] == '1',
        ),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (_, s) => UserProfilePage(userId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'connections',
            builder: (_, s) => ConnectionsPage(
              userId: s.pathParameters['id']!,
              initialTab: s.uri.queryParameters['tab'] == 'following' ? 1 : 0,
            ),
          ),
        ],
      ),
      GoRoute(path: Routes.editProfile, builder: (_, _) => const EditProfilePage()),
      GoRoute(path: Routes.myPosts, builder: (_, _) => const MyPostsPage()),
      GoRoute(
        path: '/search',
        builder: (_, s) => SearchPage(initialQuery: s.uri.queryParameters['q'] ?? ''),
      ),
      GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsPage()),
      GoRoute(path: Routes.bookmarks, builder: (_, _) => const BookmarksPage()),

      GoRoute(path: Routes.createGroup, builder: (_, _) => const GroupFormPage()),
      GoRoute(
        path: '/group/:id',
        builder: (_, s) => GroupDetailPage(groupId: s.pathParameters['id']!),
        routes: [
          GoRoute(path: 'edit', builder: (_, s) => GroupFormPage(groupId: s.pathParameters['id'])),
          GoRoute(
            path: 'members',
            builder: (_, s) => GroupMembersPage(groupId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'pending',
            builder: (_, s) => GroupPendingPage(groupId: s.pathParameters['id']!),
          ),
        ],
      ),

      GoRoute(path: Routes.createPage, builder: (_, _) => const PageFormPage()),
      GoRoute(
        path: '/page/:id',
        builder: (_, s) => PageDetailPage(pageId: s.pathParameters['id']!),
        routes: [
          GoRoute(path: 'edit', builder: (_, s) => PageFormPage(pageId: s.pathParameters['id'])),
          GoRoute(path: 'team', builder: (_, s) => PageTeamPage(pageId: s.pathParameters['id']!)),
        ],
      ),

      GoRoute(
        path: '/market/:symbol',
        builder: (_, s) => MarketDetailPage(symbol: s.pathParameters['symbol']!),
      ),

      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsPage()),
      GoRoute(path: Routes.changePassword, builder: (_, _) => const ChangePasswordPage()),
      GoRoute(path: Routes.blockedUsers, builder: (_, _) => const BlockedUsersPage()),
      GoRoute(path: Routes.deleteAccount, builder: (_, _) => const DeleteAccountPage()),

      GoRoute(path: Routes.moderation, builder: (_, _) => const ModerationPage()),
      GoRoute(path: Routes.moderationAudit, builder: (_, _) => const ModerationAuditPage()),
      GoRoute(path: Routes.moderationReports, builder: (_, _) => const ModerationReportsPage()),

      // ── web URLs (App Links from tradingbooknet.com) ──
      GoRoute(path: '/', redirect: (_, _) => Routes.home),
      GoRoute(path: '/feed', redirect: (_, _) => Routes.home),
      GoRoute(path: '/p/:id', redirect: (_, s) => Routes.post(s.pathParameters['id']!)),
      GoRoute(path: '/profile', redirect: (_, _) => Routes.me),
      GoRoute(path: '/profile/:id', redirect: (_, s) => Routes.user(s.pathParameters['id']!)),
      GoRoute(path: '/groups', redirect: (_, _) => Routes.communities),
      GoRoute(path: '/groups/:id', redirect: (_, s) => Routes.group(s.pathParameters['id']!)),
      GoRoute(path: '/channels', redirect: (_, _) => '${Routes.communities}?tab=pages'),
      GoRoute(path: '/channels/:id', redirect: (_, s) => Routes.page(s.pathParameters['id']!)),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('Page not found')),
    ),
  );
}

class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
