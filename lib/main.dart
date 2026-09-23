
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/security/secure_token_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/feed_repository_impl.dart';
import 'data/repositories/markets_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/feed_repository.dart';
import 'presentation/auth/cubit/auth_cubit.dart';
import 'presentation/auth/cubit/forgot_password/forgot_password_cubit.dart';
import 'presentation/home/cubit/feed_cubit.dart';
import 'presentation/markets/cubit/markets_cubit.dart';
import 'presentation/markets/cubit/watchlist_cubit.dart';
import 'data/repositories/notifications_repository_impl.dart';
import 'domain/repositories/notifications_repository.dart';
import 'presentation/notifications/cubit/notifications_cubit.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style — updated dynamically by ThemeCubit listener
  // in _TradingBookAppState; this is the initial light-mode default.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // === DI: Build dependency graph ===
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  final tokenStore = SecureTokenStoreImpl(secureStorage);
  final dioClient = DioClient(tokenStore: tokenStore);

  // SharedPreferences — initialised here so ThemeCubit can read it synchronously.
  final prefs = await SharedPreferences.getInstance();

  // Repositories
  final authRepo = AuthRepositoryImpl(client: dioClient, tokenStore: tokenStore);
  final feedRepo = FeedRepositoryImpl(client: dioClient);
  final postsRepo = PostsRepositoryImpl(client: dioClient);
  final marketsRepo = MarketsRepositoryImpl(client: dioClient);
  final notificationsRepo = NotificationsRepositoryImpl(client: dioClient);

  // Cubits
  final authCubit = AuthCubit(authRepository: authRepo);
  final themeCubit = ThemeCubit(prefs);
  final watchlistCubit = WatchlistCubit(prefs);
  final notificationsCubit = NotificationsCubit(repository: notificationsRepo)..loadNotifications();

  runApp(TradingBookApp(
    authCubit: authCubit,
    themeCubit: themeCubit,
    watchlistCubit: watchlistCubit,
    dioClient: dioClient,
    authRepo: authRepo,
    postsRepo: postsRepo,
    feedRepo: feedRepo,
    marketsRepo: marketsRepo,
    notificationsRepo: notificationsRepo,
    notificationsCubit: notificationsCubit,
  ));
}

class TradingBookApp extends StatefulWidget {
  final AuthCubit authCubit;
  final ThemeCubit themeCubit;
  final WatchlistCubit watchlistCubit;
  final DioClient dioClient;
  final AuthRepository authRepo;
  final PostsRepository postsRepo;
  final FeedRepositoryImpl feedRepo;
  final MarketsRepositoryImpl marketsRepo;
  final NotificationsRepository notificationsRepo;
  final NotificationsCubit notificationsCubit;

  const TradingBookApp({
    super.key,
    required this.authCubit,
    required this.themeCubit,
    required this.watchlistCubit,
    required this.dioClient,
    required this.authRepo,
    required this.postsRepo,
    required this.feedRepo,
    required this.marketsRepo,
    required this.notificationsRepo,
    required this.notificationsCubit,
  });

  @override
  State<TradingBookApp> createState() => _TradingBookAppState();
}

class _TradingBookAppState extends State<TradingBookApp> {
  late final _router = AppRouter.createRouter(widget.authCubit);

  @override
  void initState() {
    super.initState();
    widget.authCubit.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: widget.authRepo),
        RepositoryProvider<PostsRepository>.value(value: widget.postsRepo),
        RepositoryProvider<NotificationsRepository>.value(value: widget.notificationsRepo),
        RepositoryProvider.value(value: widget.dioClient),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: widget.authCubit),
          BlocProvider(
            create: (_) => ForgotPasswordCubit(
              authRepository: widget.authRepo,
            ),
          ),
        // ThemeCubit is provided at the root so any widget in the tree
        // can call context.read<ThemeCubit>().setTheme(...)
        BlocProvider.value(value: widget.themeCubit),
        // WatchlistCubit lives at the root so watchlist state persists
        // across navigation (back-stack pops, tab switches, etc.).
        BlocProvider.value(value: widget.watchlistCubit),
        BlocProvider(
          create: (_) => FeedCubit(
            feedRepository: widget.feedRepo,
            postsRepository: widget.postsRepo,
          ),
        ),
        BlocProvider(
          create: (_) => MarketsCubit(
            marketsRepository: widget.marketsRepo,
          )..loadMarkets(),
        ),
        BlocProvider.value(value: widget.notificationsCubit),
      ],
      // BlocBuilder rebuilds MaterialApp.router whenever ThemeMode changes.
      // This is the ONLY place in the app that needs to listen to ThemeCubit;
      // all child widgets simply call context.read<ThemeCubit>().setTheme(...).
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        bloc: widget.themeCubit,
        builder: (context, themeMode) {
          // Keep system UI overlay in sync with the resolved brightness.
          final isDark = themeMode == AppThemeMode.dark ||
              (themeMode == AppThemeMode.system &&
                  WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                      Brightness.dark);
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ),
          );

          return MaterialApp.router(
            title: 'TradingBook — Nexus Trader',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode.toThemeMode(),
          );
        },
      ),
    ));
  }
}
