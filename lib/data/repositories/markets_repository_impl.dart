import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/market.dart';
import '../../domain/repositories/markets_repository.dart';
import '../models/market_model.dart';

class MarketsRepositoryImpl implements MarketsRepository {
  final DioClient _client;

  MarketsRepositoryImpl({required DioClient client}) : _client = client;

  @override
  Future<List<Market>> getMarkets({
    String? category,
    int limit = 100,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (category != null) params['category'] = category;

    final response = await _client.get(
      ApiEndpoints.marketsDetails,
      queryParameters: params,
    );

    final body = response.data as Map<String, dynamic>;

    // Support both { "items": [...] } and { "data": [...] } envelopes.
    final rawList = body['items'] as List? ?? body['data'] as List? ?? [];

    return rawList
        .map((e) => MarketModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }
}
