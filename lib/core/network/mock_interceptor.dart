import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../constants/api_endpoints.dart';

class MockInterceptor extends Interceptor {
  /// Set to [true] to intercept all requests with canned responses (offline / UI dev).
  /// Set to [false] (default) to allow requests to reach the real network.
  static bool isMockEnabled = false;

  final Uuid _uuid = const Uuid();

  String _generateId() => _uuid.v4();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // ── MOCK GUARD ──────────────────────────────────────────────────────────────
    // When disabled, pass the request straight through to the real network.
    if (!isMockEnabled) {
      return handler.next(options);
    }
    // ────────────────────────────────────────────────────────────────────────────

    // Artificial delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 800));

    final path = options.path;

    // --- AUTH ---
    if (path.endsWith(ApiEndpoints.signup) || path.endsWith(ApiEndpoints.login)) {
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'user': {
            'id': _generateId(),
            'handle': '@mock_trader',
            'displayName': 'Mock Trader',
            'email': 'mock@tradingbooknet.com',
            'avatarUrl': 'https://i.pravatar.cc/150?u=mock',
            'tier': 'pro',
            'followersCount': 1337,
            'followingCount': 420,
            'bio': 'Crypto enthusiast. Price action trader.',
            'joinedAt': DateTime.now().toIso8601String(),
          },
          'accessToken': 'mock.access.token',
          'refreshToken': 'mock.refresh.token',
        },
      ));
    }

    if (path.endsWith(ApiEndpoints.me)) {
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'id': _generateId(),
          'handle': '@mock_trader',
          'displayName': 'Mock Trader',
          'email': 'mock@tradingbooknet.com',
          'avatarUrl': 'https://i.pravatar.cc/150?u=mock',
          'tier': 'pro',
          'followersCount': 1337,
          'followingCount': 420,
          'bio': 'Crypto enthusiast. Price action trader.',
          'joinedAt': DateTime.now().toIso8601String(),
        },
      ));
    }

    // --- FEED ---
    if (path.endsWith(ApiEndpoints.feed) || path.endsWith(ApiEndpoints.myPosts)) {
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'items': [
            {
              'id': _generateId(),
              'authorId': _generateId(),
              'authorHandle': '@whale_alert',
              'authorName': 'Whale Alert',
              'authorAvatar': 'https://i.pravatar.cc/150?u=whale',
              'authorTier': 'pro',
              'content': 'Just noticed a massive 10,000 BTC transfer to Binance. Brace for impact! 📉 #Bitcoin #Crypto',
              'type': 'text',
              'createdAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
              'likesCount': 245,
              'commentsCount': 42,
              'isLiked': false,
            },
            {
              'id': _generateId(),
              'authorId': _generateId(),
              'authorHandle': '@swing_king',
              'authorName': 'Swing King',
              'authorAvatar': 'https://i.pravatar.cc/150?u=swing',
              'authorTier': 'verified',
              'content': 'ETH is holding the line perfectly. If we break 3200, it\'s blue skies ahead.',
              'type': 'trade_setup',
              'symbol': 'ETH/USD',
              'bias': 'LONG',
              'entryPrice': 3100.50,
              'takeProfit': 3500.00,
              'stopLoss': 2950.00,
              'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
              'likesCount': 892,
              'commentsCount': 156,
              'isLiked': true,
            }
          ],
          'nextCursor': 'next_page_cursor_mock'
        },
      ));
    }

    // --- SOCIAL / FOLLOW ---
    if (path.contains('/api/social/')) {
       return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true},
      ));
    }

    // --- GROUPS ---
    if (path.endsWith(ApiEndpoints.groups)) {
       return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'data': [
            {
              'id': _uuid.v4(),
              'name': 'Crypto Degens',
              'description': 'High risk, high reward plays only.',
              'imageUrl': 'https://images.unsplash.com/photo-1621504450181-5d356f61d307?auto=format&fit=crop&w=200',
              'membersCount': 15000,
              'isPrivate': false,
              'isJoined': true,
              'category': 'crypto'
            },
            {
              'id': _uuid.v4(),
              'name': 'Forex Fundamentals',
              'description': 'Daily macro analysis and forex pairs setups.',
              'imageUrl': 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?auto=format&fit=crop&w=200',
              'membersCount': 8200,
              'isPrivate': false,
              'isJoined': false,
              'category': 'forex'
            }
          ]
        }
      ));
    }

    // --- MARKETS ---
    if (path.endsWith(ApiEndpoints.marketsDetails)) {
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'items': [
            {'symbol': 'EUR/USD', 'shortName': 'EUR', 'name': 'Euro / US Dollar', 'price': 1.0845, 'change': 0.24, 'category': 'forex'},
            {'symbol': 'BTC/USD', 'shortName': 'BTC', 'name': 'Bitcoin', 'price': 64230.0, 'change': 2.15, 'category': 'crypto'},
            {'symbol': 'ETH/USD', 'shortName': 'ETH', 'name': 'Ethereum', 'price': 3450.0, 'change': -0.88, 'category': 'crypto'},
            {'symbol': 'AAPL', 'shortName': 'AAPL', 'name': 'Apple Inc.', 'price': 173.50, 'change': -0.85, 'category': 'stocks'},
            {'symbol': 'GBP/JPY', 'shortName': 'GBP', 'name': 'British Pound / Yen', 'price': 191.20, 'change': 0.12, 'category': 'forex'},
            {'symbol': 'XAU/USD', 'shortName': 'XAU', 'name': 'Gold / US Dollar', 'price': 2345.80, 'change': 0.85, 'category': 'commodities'},
            {'symbol': 'SOL/USD', 'shortName': 'SOL', 'name': 'Solana', 'price': 148.20, 'change': 5.12, 'category': 'crypto'},
            {'symbol': 'USD/JPY', 'shortName': 'JPY', 'name': 'US Dollar / Yen', 'price': 149.60, 'change': -0.32, 'category': 'forex'},
          ]
        },
      ));
    }

    // --- DEFAULT FALLBACK ---
    return handler.resolve(Response(
      requestOptions: options,
      statusCode: 200,
      data: {'success': true, 'mock': true},
    ));
  }
}
