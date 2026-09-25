import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/service_locator.dart';
import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'data/repositories/engagement_repository.dart';
import 'data/repositories/user_repository.dart';
import 'features/auth/session_cubit.dart';
import 'features/markets/watchlist_cubit.dart';
import 'features/notifications/notification_center.dart';

class TradingBookApp extends StatefulWidget {
  const TradingBookApp({super.key});

  @override
  State<TradingBookApp> createState() => _TradingBookAppState();
}

class _TradingBookAppState extends State<TradingBookApp> {
  late final SessionCubit _session = sl<SessionCubit>();
  late final GoRouter _router = createRouter(_session);

  @override
  void initState() {
    super.initState();
    final push = sl<PushService>();
    final notifications = sl<NotificationCenter>();

    _session
      ..onSignedIn = (user) async {
        sl<UserRepository>().primeCache(user);
        await notifications.start();
        push.registerForUser();
      }
      ..onSigningOut = () async {
        await push.unregister();
        await sl<EngagementRepository>().flushEvents();
      };
    _session.stream.listen((state) {
      if (state is Unauthenticated) {
        notifications.stop();
        sl<EngagementRepository>().resetStats();
      }
    });

    push.onOpen = _openFromPush;
    // Never gate startup on Firebase: without google-services.json its init
    // takes seconds to fail. Registration runs again after sign-in anyway.
    _session.bootstrap();
    push.init().then((_) {
      if (_session.state is Authenticated) push.registerForUser();
    });
  }

  /// A tapped push carries the same ids as the notification record.
  void _openFromPush(Map<String, dynamic> data) {
    final postId = data['postId'] as String?;
    final actorId = data['actorId'] as String?;
    final groupId = data['groupId'] as String?;
    final pageId = data['pageId'] as String?;
    if (postId != null) {
      _router.push(Routes.post(postId));
    } else if (groupId != null) {
      _router.push(Routes.group(groupId));
    } else if (pageId != null) {
      _router.push(Routes.page(pageId));
    } else if (data['type'] == 'new_follower' && actorId != null) {
      _router.push(Routes.user(actorId));
    } else {
      _router.push(Routes.notifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        BlocProvider.value(value: sl<ThemeCubit>()),
        BlocProvider.value(value: sl<WatchlistCubit>()),
        BlocProvider.value(value: sl<NotificationCenter>()),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, mode) {
          return MaterialApp.router(
            title: 'TradingBook',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode.toThemeMode(),
            routerConfig: _router,
            builder: (context, child) {
              final dark = Theme.of(context).brightness == Brightness.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                ),
                // Respect the user's font size, but cap it so layouts hold.
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.4,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
