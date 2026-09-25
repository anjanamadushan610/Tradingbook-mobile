/// Build-time configuration, injected with `--dart-define` (or
/// `--dart-define-from-file=env/prod.json`). Defaults point at production so a
/// plain `flutter run` talks to the live API, the same way the web app does.
///
/// Local backend:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8787
/// (10.0.2.2 is the Android emulator's alias for the host machine.)
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.tradingbooknet.com',
  );

  /// Public R2 domain. Post `mediaRefs` are raw object keys, not URLs — the
  /// client builds the URL (mirrors the backend's MEDIA_PUBLIC_BASE_URL and
  /// the web app's NEXT_PUBLIC_MEDIA_BASE_URL; keep all three in sync).
  static const String mediaBaseUrl = String.fromEnvironment(
    'MEDIA_BASE_URL',
    defaultValue: 'https://media.tradingbooknet.com',
  );

  /// The web app, used for share links, legal pages and account deletion.
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://tradingbooknet.com',
  );

  /// Google OAuth *web* client id. Android's Credential Manager mints an ID
  /// token whose `aud` is this id, which is what the backend's
  /// GOOGLE_CLIENT_IDS already accepts for the web app. Empty = the Google
  /// button is hidden.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Video posts go through Cloudflare Stream, which is not provisioned on the
  /// production account yet (no storage minutes). Off until it is, so users
  /// never hit an upload that is guaranteed to fail.
  static const bool videoUploadsEnabled = bool.fromEnvironment(
    'VIDEO_UPLOADS_ENABLED',
    defaultValue: false,
  );

  static String get wsBaseUrl => apiBaseUrl.replaceFirst(RegExp('^http'), 'ws');

  static const String supportEmail = 'support@tradingbooknet.com';
  static String get privacyPolicyUrl => '$webBaseUrl/privacy';
  static String get termsUrl => '$webBaseUrl/terms';
  static String postUrl(String postId) => '$webBaseUrl/p/$postId';
  static String profileUrl(String userId) => '$webBaseUrl/profile/$userId';
  static String groupUrl(String groupId) => '$webBaseUrl/groups/$groupId';
  static String channelUrl(String pageId) => '$webBaseUrl/channels/$pageId';
}
