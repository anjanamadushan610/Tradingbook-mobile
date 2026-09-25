import 'package:equatable/equatable.dart';

import 'json_utils.dart';

/// Every market response is stamped with its upstream and fetch time. The UI
/// must show that age — on a trading platform a plausible stale number is
/// worse than a visible error.
class MarketEnvelope<T> {
  const MarketEnvelope({
    required this.provider,
    required this.fetchedAt,
    required this.items,
  });

  final String provider;
  final DateTime fetchedAt;
  final T items;
}

class Quote extends Equatable {
  const Quote({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.changePercent24h,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    required this.quoteVolume24h,
  });

  final String symbol;
  final double price;
  final double change24h;

  /// Already a percentage: -0.18 means -0.18%.
  final double changePercent24h;
  final double high24h;
  final double low24h;
  final double volume24h;
  final double quoteVolume24h;

  bool get isUp => changePercent24h >= 0;

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        symbol: readString(json['symbol']),
        price: readDouble(json['price']),
        change24h: readDouble(json['change24h']),
        changePercent24h: readDouble(json['changePercent24h']),
        high24h: readDouble(json['high24h']),
        low24h: readDouble(json['low24h']),
        volume24h: readDouble(json['volume24h']),
        quoteVolume24h: readDouble(json['quoteVolume24h']),
      );

  @override
  List<Object?> get props => [symbol, price, changePercent24h];
}

class Candle extends Equatable {
  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  /// Bar OPEN time.
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  factory Candle.fromJson(Map<String, dynamic> json) => Candle(
        time: readTime(json['t']),
        open: readDouble(json['o']),
        high: readDouble(json['h']),
        low: readDouble(json['l']),
        close: readDouble(json['c']),
        volume: readDouble(json['v']),
      );

  @override
  List<Object?> get props => [time, close];
}

class MarketSymbol extends Equatable {
  const MarketSymbol({
    required this.symbol,
    required this.baseAsset,
    required this.quoteAsset,
    required this.label,
  });

  final String symbol;
  final String baseAsset;
  final String quoteAsset;
  final String label;

  factory MarketSymbol.fromJson(Map<String, dynamic> json) => MarketSymbol(
        symbol: readString(json['symbol']),
        baseAsset: readString(json['baseAsset']),
        quoteAsset: readString(json['quoteAsset']),
        label: readString(json['label'], readString(json['symbol'])),
      );

  @override
  List<Object?> get props => [symbol];
}

enum CandleInterval {
  m1('1m', '1m'),
  m5('5m', '5m'),
  m15('15m', '15m'),
  m30('30m', '30m'),
  h1('1h', '1H'),
  h4('4h', '4H'),
  d1('1d', '1D'),
  w1('1w', '1W');

  const CandleInterval(this.wire, this.label);
  final String wire;
  final String label;
}
