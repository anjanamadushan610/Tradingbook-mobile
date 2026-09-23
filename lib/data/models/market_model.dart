import '../../domain/entities/market.dart';

class MarketModel {
  final String symbol;
  final String shortName;
  final String name;
  final double price;
  final double change;
  final double? volume;
  final double? high24h;
  final double? low24h;
  final String category;

  const MarketModel({
    required this.symbol,
    required this.shortName,
    required this.name,
    required this.price,
    required this.change,
    this.volume,
    this.high24h,
    this.low24h,
    required this.category,
  });

  /// Parses a single market object from the API.
  ///
  /// Defensive rules:
  /// - `price` and `change` can arrive as int OR double — we coerce both.
  /// - `shortName` falls back to the first token of [symbol] before "/"
  ///   so we still render something meaningful if the server omits it.
  /// - `category` is lowercased for uniform client-side filtering.
  factory MarketModel.fromJson(Map<String, dynamic> json) {
    final symbol = json['symbol'] as String? ?? '';
    final shortNameRaw = json['shortName'] as String? ??
        json['ticker'] as String? ??
        (symbol.isNotEmpty ? symbol.split('/').first : '?');

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    double? toDoubleNullable(dynamic v) {
      if (v == null) return null;
      return toDouble(v);
    }

    return MarketModel(
      symbol: symbol,
      shortName: shortNameRaw,
      name: json['name'] as String? ?? symbol,
      price: toDouble(json['price'] ?? json['lastPrice'] ?? json['close']),
      change: toDouble(json['change'] ?? json['changePercent'] ?? json['change24h']),
      volume: toDoubleNullable(json['volume'] ?? json['volume24h']),
      high24h: toDoubleNullable(json['high24h'] ?? json['high']),
      low24h: toDoubleNullable(json['low24h'] ?? json['low']),
      category: (json['category'] as String? ??
              json['assetClass'] as String? ??
              'other')
          .toLowerCase(),
    );
  }

  Market toEntity() => Market(
        symbol: symbol,
        shortName: shortName,
        name: name,
        price: price,
        change: change,
        volume: volume,
        high24h: high24h,
        low24h: low24h,
        category: category,
      );
}
