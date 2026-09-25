import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_book/core/network/api_client.dart';
import 'package:trading_book/core/network/api_exception.dart';
import 'package:trading_book/core/storage/token_storage.dart';

/// In-memory secure storage so the interceptor runs without platform channels.
class _MemoryStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      value == null ? data.remove(key) : data[key] = value;

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      data.remove(key);
}

/// A fake backend: access tokens "a1" (expired) and "a2" (fresh); refresh
/// tokens rotate r1 → r2 and are single-use, like the real API.
class _FakeBackend implements HttpClientAdapter {
  int refreshCalls = 0;
  final Set<String> usedRefreshTokens = {};
  bool rejectRefresh = false;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body, Future<void>? cancel) async {
    ResponseBody json(int status, Object data) => ResponseBody.fromString(
          jsonEncode(data),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );

    if (options.path.endsWith('/auth/refresh')) {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final token = (options.data as Map)['refreshToken'] as String;
      if (rejectRefresh || !usedRefreshTokens.add(token)) {
        return json(401, {'error': {'code': 'unauthorized', 'message': 'bad refresh'}});
      }
      return json(200, {'accessToken': 'a2', 'refreshToken': 'r2'});
    }
    final auth = options.headers['Authorization'];
    if (auth != 'Bearer a2') {
      return json(401, {'error': {'code': 'unauthorized', 'message': 'expired'}});
    }
    return json(200, {'ok': true, 'path': options.path});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeBackend backend;
  late TokenStorage tokens;
  late ApiClient api;
  late int expiredCalls;

  setUp(() async {
    backend = _FakeBackend();
    tokens = TokenStorage(_MemoryStorage());
    await tokens.save(const AuthTokens(accessToken: 'a1', refreshToken: 'r1'));
    expiredCalls = 0;
    api = ApiClient(
      tokenStorage: tokens,
      onSessionExpired: () => expiredCalls++,
      baseUrl: 'https://api.test',
      adapter: backend,
    );
  });

  test('refreshes once for concurrent 401s and retries every request', () async {
    final results = await Future.wait([
      for (var i = 0; i < 5; i++) api.get<Map<String, dynamic>>('/api/thing/$i'),
    ]);
    expect(results.every((r) => r['ok'] == true), isTrue);
    expect(backend.refreshCalls, 1, reason: 'a second refresh would reuse a rotated token');
    expect((await tokens.read())!.refreshToken, 'r2');
    expect(expiredCalls, 0);
  });

  test('an expired session is reported once refresh is rejected', () async {
    backend.rejectRefresh = true;
    await expectLater(api.get<Map<String, dynamic>>('/api/me'), throwsA(isA<ApiException>()));
    expect(expiredCalls, 1);
    expect(await tokens.read(), isNull);
  });

  test('a request overtaken by another refresh retries without refreshing', () async {
    await api.get<Map<String, dynamic>>('/api/one');
    // Simulate a request that was sent with the old token after the refresh.
    await tokens.save(const AuthTokens(accessToken: 'a2', refreshToken: 'r2'));
    final r = await api.get<Map<String, dynamic>>('/api/two');
    expect(r['ok'], isTrue);
    expect(backend.refreshCalls, 1);
  });
}
