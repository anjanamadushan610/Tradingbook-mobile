import 'package:equatable/equatable.dart';

/// Canonical market instrument entity used across the domain layer.
/// All values are normalised (category lowercased, price as double, etc.)
/// before this object is constructed.
class Market extends Equatable {
  final String symbol;   // e.g. "EUR/USD"
  final String shortName; // e.g. "EUR" — used in the icon circle
  final String name;     // e.g. "Euro / US Dollar"
  final double price;    // latest trade / mid price
  final double change;   // 24-hour percentage change (signed)
  final double? volume;  // 24-hour volume (optional, may not be present)
  final double? high24h;
  final double? low24h;
  final String category; // "forex" | "crypto" | "stocks" | "commodities"

  const Market({
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

  bool get isUp => change >= 0;

  @override
  List<Object?> get props => [symbol, price, change, volume, high24h, low24h];
}
