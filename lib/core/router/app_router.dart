import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import '../../presentation/auth/cubit/auth_cubit.dart';
import '../../presentation/auth/cubit/auth_state.dart';
import '../../presentation/auth/pages/forgot_password_page.dart';
import '../../presentation/auth/pages/login_page.dart';
import '../../presentation/auth/pages/register_page.dart';
import '../../presentation/auth/pages/otp_page.dart';
import '../../presentation/auth/pages/reset_password_page.dart';
import '../../presentation/shell/main_shell.dart';
import '../../presentation/home/pages/home_page.dart';
import '../../presentation/discover/pages/discover_page.dart';
import '../../presentation/markets/pages/markets_page.dart';
import '../../presentation/markets/pages/market_detail_page.dart';
import '../../presentation/groups/pages/groups_page.dart';
import '../../presentation/profile/pages/my_profile_page.dart';
import '../../presentation/profile/pages/settings_page.dart';
import '../../presentation/profile/pages/edit_profile_page.dart';
import '../../presentation/notifications/pages/notifications_page.dart';
import '../../presentation/create_post/pages/create_post_page.dart';
import '../../presentation/trader_profile/pages/trader_profile_page.dart';
import '../../presentation/messages/pages/messages_page.dart';
import '../../presentation/splash/pages/splash_page.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otp = '/otp';
  static const resetPassword = '/reset-password';
  static const home = '/home';
  static const discover = '/discover';
  static const markets = '/markets';
  static const marketDetail = '/markets/:symbol';
  static const groups = '/groups';
  static const profile = '/profile';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const createPost = '/create-post';
  static const traderProfile = '/trader/:userId';
  static const messages = '/messages';
  static const editProfile = '/edit-profile';
}

class AppRouter {
  static GoRouter createRouter(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      redirect: (context, state) {
        final authState = authCubit.state;
        final isOnAuthPage = state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register ||
            state.matchedLocation == AppRoutes.forgotPassword ||
            state.matchedLocation == AppRoutes.otp ||
            state.matchedLocation == AppRoutes.resetPassword;
        final isOnSplashPage = state.matchedLocation == AppRoutes.splash;

        if (authState is AuthLoading || authState is AuthInitial) {
          return isOnSplashPage ? null : AppRoutes.splash; 
        }

        if (authState is AuthUnauthenticated && !isOnAuthPage) {
          return AppRoutes.login;
        }

        if (authState is AuthAuthenticated && (isOnAuthPage || isOnSplashPage)) {
          return AppRoutes.home;
        }

        return null;
      },
      refreshListenable: _GoRouterAuthNotifier(authCubit),
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (_, __) => const SplashPage(),
        ),
        // === Auth routes ===
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (_, __) => const RegisterPage(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, __) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: AppRoutes.otp,
          builder: (_, __) => const OtpPage(),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (_, __) => const ResetPasswordPage(),
        ),

        // === Main Shell (Bottom Nav) ===
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const HomePage(),
            ),
            GoRoute(
              path: AppRoutes.discover,
              builder: (_, __) => const DiscoverPage(),
            ),
            GoRoute(
              path: AppRoutes.markets,
              builder: (_, __) => const MarketsPage(),
            ),
            GoRoute(
              path: AppRoutes.groups,
              builder: (_, __) => const GroupsPage(),
            ),
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) => const MyProfilePage(),
            ),
          ],
        ),

        // === Standalone / Overlay routes ===
        GoRoute(
          path: AppRoutes.marketDetail,
          builder: (_, state) => MarketDetailPage(
            symbol: state.pathParameters['symbol'] ?? 'BTC/USD',
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, __) => const SettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (_, __) => const EditProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (_, __) => const NotificationsPage(),
        ),
        GoRoute(
          path: AppRoutes.createPost,
          builder: (_, __) => const CreatePostPage(),
        ),
        GoRoute(
          path: AppRoutes.traderProfile,
          builder: (_, state) => TraderProfilePage(
            userId: state.pathParameters['userId'] ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.messages,
          builder: (_, __) => const MessagesPage(),
        ),
      ],
    );
  }
}

/// Notifies GoRouter of auth state changes so it re-evaluates redirects
class _GoRouterAuthNotifier extends ChangeNotifier {
  final AuthCubit _authCubit;

  _GoRouterAuthNotifier(this._authCubit) {
    _authCubit.stream.listen((_) => notifyListeners());
  }
}
