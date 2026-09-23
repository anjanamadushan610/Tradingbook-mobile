import '../entities/market.dart';

/// Abstract contract that the data layer must satisfy.
/// The cubit depends only on this interface — not the concrete impl.
abstract class MarketsRepository {
  /// Fetch the full list of tradeable instruments.
  ///
  /// [category]  — optional server-side filter (e.g. "forex", "crypto").
  ///               Pass `null` to fetch all categories in one request.
  /// [limit]     — max instruments returned (server may cap lower).
  Future<List<Market>> getMarkets({
    String? category,
    int limit = 100,
  });
}
