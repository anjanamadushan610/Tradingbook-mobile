import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Holds the session's token pair: Keystore/Keychain-backed on disk, mirrored
/// in memory so the request path never waits on platform channels.
///
/// The refresh token is single-use (the backend rotates it on every refresh),
/// so a stale copy is worthless — [save] always writes both together.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'tb_access_token';
  static const _refreshKey = 'tb_refresh_token';

  AuthTokens? _cached;
  bool _loaded = false;

  Future<AuthTokens?> read() async {
    if (_loaded) return _cached;
    try {
      final access = await _storage.read(key: _accessKey);
      final refresh = await _storage.read(key: _refreshKey);
      _cached = (access != null && refresh != null)
          ? AuthTokens(accessToken: access, refreshToken: refresh)
          : null;
    } catch (_) {
      // A Keystore that can't decrypt (e.g. restored from a backup onto a new
      // device) is the same as no session: start signed out, don't crash.
      _cached = null;
      await _safeDeleteAll();
    }
    _loaded = true;
    return _cached;
  }

  String? get accessToken => _cached?.accessToken;

  Future<void> save(AuthTokens tokens) async {
    _cached = tokens;
    _loaded = true;
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _safeDeleteAll();
  }

  Future<void> _safeDeleteAll() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
  }
}
