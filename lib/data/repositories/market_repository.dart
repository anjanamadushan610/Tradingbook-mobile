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
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['fetchedAt'] as num?)?.toInt() ?? 0,
      ),
      items: (json['items'] as List? ?? const [])
          .cast<Json>()
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
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['fetchedAt'] as num?)?.toInt() ?? 0,
      ),
      items: (json['items'] as List? ?? const [])
          .cast<Json>()
          .map(Candle.fromJson)
          .toList(),
    );
  }

  /// The curated instrument list; cached for the session (server caches 1h).
  Future<List<MarketSymbol>> symbols() async {
    if (_symbols != null) return _symbols!;
    final json = await _api.get<Json>('/api/markets/symbols');
    _symbols = (json['items'] as List? ?? const [])
        .cast<Json>()
        .map(MarketSymbol.fromJson)
        .toList();
    return _symbols!;
  }
}
