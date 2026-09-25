import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/engagement_repository.dart';
import '../../data/repositories/market_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/moderation_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../features/auth/session_cubit.dart';
import '../../features/markets/watchlist_cubit.dart';
import '../../features/notifications/notification_center.dart';
import '../network/api_client.dart';
import '../push/push_service.dart';
import '../storage/token_storage.dart';
import '../theme/theme_cubit.dart';

final sl = GetIt.instance;

/// Builds the object graph once at startup. Repositories are app-lifetime
/// singletons (they own caches shared across screens); screen state lives in
/// cubits created by the screens themselves.
Future<void> setupServiceLocator() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  const secure = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  final tokens = TokenStorage(secure);
  sl.registerSingleton<TokenStorage>(tokens);

  final api = ApiClient(
    tokenStorage: tokens,
    onSessionExpired: () => sl<SessionCubit>().sessionExpired(),
  );
  sl.registerSingleton<ApiClient>(api);

  sl
    ..registerSingleton(AuthRepository(api, tokens))
    ..registerSingleton(UserRepository(api))
    ..registerSingleton(PostRepository(api))
    ..registerSingleton(MediaRepository(api))
    ..registerSingleton(CommunityRepository(api))
    ..registerSingleton(NotificationRepository(api))
    ..registerSingleton(MarketRepository(api))
    ..registerSingleton(ModerationRepository(api))
    ..registerSingleton(EngagementRepository(
      api,
      isSignedIn: () => sl<SessionCubit>().state is Authenticated,
    ));

  sl
    ..registerSingleton(SessionCubit(sl(), prefs))
    ..registerSingleton(ThemeCubit(prefs))
    ..registerSingleton(WatchlistCubit(prefs))
    ..registerSingleton(NotificationCenter(sl(), tokens))
    ..registerSingleton(PushService(sl()));
}
