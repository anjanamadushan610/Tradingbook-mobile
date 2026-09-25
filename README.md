# TradingBook — mobile app

Flutter client for [TradingBook](https://tradingbooknet.com), the social
network for traders. It talks to the same production API as the web app
(`https://api.tradingbooknet.com`, repo `Tradingbook-backend`) and covers
every web feature.

## Features

| Area | What's in the app |
| :--- | :--- |
| Account | Sign up (email verification when the backend has email), sign in, forgot/reset password (6-digit code), Google sign-in (behind a build flag), change password, delete account |
| Feed | Personalised feed, compose (text + up to 10 images, audience, language, post as a Page or into a Group), edit caption, change audience, delete |
| Posts | Image carousel with zoom, like, threaded comments (like, reply, edit, delete), save, share links, report, block author |
| Discover | Trending topics, traders to follow, communities, trending posts, search (traders, posts, #tags) |
| Profiles | Own profile with post review status, other traders' profiles and posts, followers/following, edit profile with avatar/cover upload, private profile |
| Groups | Discover, join / request to join, member list and roles, invite, join requests, stage-1 post approvals, create/edit/delete, avatar/cover |
| Pages | Discover, follow, post as page, team roles, followers, create/edit/delete, avatar/cover |
| Markets | Live spot crypto quotes with data age, watchlist, candlestick charts (1m–1W) |
| Notifications | Live badge and list over WebSocket; push via FCM once Firebase is configured |
| Moderation | Review queue with bulk actions, user reports, audit log (moderators only) |
| Settings | Theme (light/dark/auto), blocked traders, saved posts, legal links, licenses |

## Architecture

```
lib/
  core/        config, DI (get_it), network (Dio + token refresh), router
               (go_router), theme, shared widgets, pagination
  data/        models (mirroring the backend's types) and repositories
  features/    one folder per product area: pages + widgets + cubits
```

- **State:** `flutter_bloc` cubits. Every infinite list is a `PagedCubit<T>`
  over a `fetch(cursor)` function (`core/paging`).
- **Auth:** access token (15 min) + single-use rotating refresh token in the
  Keystore. `AuthInterceptor` refreshes once for any number of concurrent
  401s — see `test/auth_interceptor_test.dart`.
- **Hydration:** feeds return author *ids*. Profiles and per-post engagement
  are resolved through batched, de-duplicating caches
  (`UserRepository.profile`, `EngagementRepository.statsFor`), so a page of
  posts costs ~3 requests, with a per-item fallback for older backends.
- **Media:** images are re-encoded to JPEG on-device (EXIF/GPS stripped),
  uploaded straight to R2 with presigned URLs, and displayed from the WebP
  variants with a fallback to the original.

## Running

```bash
flutter pub get
flutter run                                   # production API
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8787   # local wrangler dev
```

Build-time flags (`--dart-define`): `API_BASE_URL`, `MEDIA_BASE_URL`,
`WEB_BASE_URL`, `GOOGLE_SERVER_CLIENT_ID` (shows "Continue with Google"),
`VIDEO_UPLOADS_ENABLED` (off: Cloudflare Stream isn't provisioned).

### Windows build notes (this machine)

The C: drive is nearly full, so builds keep Gradle and temp files on D:

```bash
export GRADLE_USER_HOME=D:/dev-cache/gradle TEMP=D:/dev-cache/tmp TMP=D:/dev-cache/tmp
```

`android/gradle.properties` sets `kotlin.incremental=false` because plugins
compile from the pub cache on C: while the project is on D:.

## Tests

```bash
flutter analyze
flutter test
```

## Releasing

See [docs/RELEASE.md](docs/RELEASE.md) and the store listing material in
[docs/PLAY_STORE.md](docs/PLAY_STORE.md).
