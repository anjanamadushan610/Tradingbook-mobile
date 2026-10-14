import '../../core/network/api_client.dart';
import '../models/market.dart';

/// Spot crypto quotes and candles (Bybit upstream, passed through verbatim).
/// Errors are never papered over: 502 = upstream down, 503 = disabled.
class MarketRepository {
  MarketRepository(this._api);

  final ApiClient _api;

  List<MarketSymbol>? _symbols;

  Future<MarketEnvelope<List<Quote>>> quotes([List<String>? symbols]) async {
    final json = await _api.get<Json>(
      '/api/markets/details',
      query: {
        if (symbols != null && symbols.isNotEmpty)
          'symbols': symbols.take(25).join(','),
      },
    );
    return MarketEnvelope(
      provider: json['provider'] as String? ?? '',
      fetchedAt: _parseTime(json['fetchedAt']),
      items: (json['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Quote.fromJson)
          .toList(),
    );
  }

  Future<MarketEnvelope<List<Candle>>> candles(
    String symbol, {
    CandleInterval interval = CandleInterval.h1,
    int limit = 120,
  }) async {
    final json = await _api.get<Json>(
      '/api/markets/candles',
      query: {'symbol': symbol, 'interval': interval.wire, 'limit': limit},
    );
    return MarketEnvelope(
      provider: json['provider'] as String? ?? '',
      fetchedAt: _parseTime(json['fetchedAt']),
      items: (json['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Candle.fromJson)
          .toList(),
    );
  }

  /// The curated instrument list; cached for the session (server caches 1h).
  Future<List<MarketSymbol>> symbols() async {
    if (_symbols != null) return _symbols!;
    final json = await _api.get<Json>('/api/markets/symbols');
    _symbols = (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MarketSymbol.fromJson)
        .toList();
    return _symbols!;
  }
}

/// Safely parses a [fetchedAt] value from either a Unix-epoch int/ms or an
/// ISO-8601 string. Returns [DateTime.now()] as a safe fallback so the UI
/// always has a sensible timestamp to display.
DateTime _parseTime(Object? value) {
  if (value is num) {
    final ms = value.toInt();
    // Epoch-second vs epoch-millisecond heuristic: anything before year 2001
    // in ms (< 978307200000) is likely seconds.
    return DateTime.fromMillisecondsSinceEpoch(
      ms < 978307200000 ? ms * 1000 : ms,
    );
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
