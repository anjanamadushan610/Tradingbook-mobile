# Releasing the Android app

## One-time setup

1. **Upload key.** The upload keystore lives outside the repo at
   `D:\tradingbook-android-signing\upload-keystore.jks`; its passwords are in
   `key.properties` next to it. Copy that file to `android/key.properties`
   (gitignored). **Back up both files somewhere safe** — losing them means
   asking Google for an upload-key reset.
   - Alias `upload`, RSA 4096, valid ~27 years.
   - SHA-1 `65:78:40:8C:AE:81:AD:0D:B8:D0:A4:FE:C2:FB:A2:FE:20:6A:78:46`
   - SHA-256 `90:BD:B4:DE:84:6F:1A:6B:12:06:5B:88:84:F9:E9:6D:7A:73:0F:27:C7:64:14:26:BC:AE:CB:33:1F:C9:1D:27`
2. **Play Console.** Create the app with package name
   `com.tradingbooknet.app` (permanent) and enrol in Play App Signing (the
   default). Google then holds the real signing key; this upload key only
   proves uploads come from you.

## Every release

1. Bump `version:` in `pubspec.yaml` — the number after `+` (versionCode)
   must increase on every upload.
2. Build:
   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`.
   Keep `build/symbols` for that version (to de-obfuscate crash traces).
3. Upload the `.aab` to the **Internal testing** track first, install from
   the Play link on a real phone, then promote to Production.

## Optional features and what they need

| Feature | What to do |
| :--- | :--- |
| Push notifications | Create a Firebase project, add an Android app `com.tradingbooknet.app`, download `google-services.json` into `android/app/`, rebuild. On the backend: `wrangler secret put FCM_SERVICE_ACCOUNT` with a service-account JSON (Firebase → Project settings → Service accounts). |
| Google sign-in | In the Google Cloud project that owns web client `173855133258-…`, create an **Android** OAuth client for `com.tradingbooknet.app` with the SHA-1 of the **Play app-signing** key (Play Console → App integrity) and of the upload key. Then build with `--dart-define=GOOGLE_SERVER_CLIENT_ID=173855133258-qj3d1da93f50a5r32rn8nmd7n93i5435.apps.googleusercontent.com`. |
| App Links (tradingbooknet.com links open the app) | Serve `https://tradingbooknet.com/.well-known/assetlinks.json` from the web app with the Play app-signing SHA-256 (template below). |
| Password reset & email verification | Backend `RESEND_API_KEY` secret + a verified sending domain in Resend. |
| Video posts | Cloudflare Stream plan, then build with `--dart-define=VIDEO_UPLOADS_ENABLED=true`. |

`assetlinks.json` template:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.tradingbooknet.app",
    "sha256_cert_fingerprints": ["<PLAY APP SIGNING SHA-256>"]
  }
}]
```
