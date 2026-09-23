import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/market.dart';
import '../../../domain/repositories/markets_repository.dart';
import 'markets_state.dart';

/// Category tab labels. Index 0 is always "Watchlist", index 1 is "All",
/// then the instrument categories follow.
///
/// IMPORTANT: keep this list in sync with `_MarketsPageState._categories`.
const kMarketCategories = ['⭐ Watchlist', 'All', 'Forex', 'Crypto', 'Stocks', 'Commodities'];

/// Sentinel index for the Watchlist tab — avoids magic numbers across files.
const kWatchlistCategoryIndex = 0;

class MarketsCubit extends Cubit<MarketsState> {
  final MarketsRepository _marketsRepository;

  MarketsCubit({required MarketsRepository marketsRepository})
      : _marketsRepository = marketsRepository,
        super(const MarketsInitial());

  /// Fetch all markets from the API and start with "All" (index 1) selected.
  Future<void> loadMarkets() async {
    emit(const MarketsLoading());
    try {
      final markets = await _marketsRepository.getMarkets(limit: 100);
      emit(MarketsLoaded(
        allMarkets: markets,
        displayedMarkets: markets, // "All" tab selected by default
        categoryIndex: 1,          // index 1 = "All"
      ));
    } catch (e) {
      emit(MarketsError(e.toString()));
    }
  }

  /// Filter by category tab index.
  ///
  /// When [index] == [kWatchlistCategoryIndex] the caller **must** supply
  /// [watchedSymbols] — the set comes from [WatchlistCubit] and is passed in
  /// by the UI layer so [MarketsCubit] stays decoupled from [WatchlistCubit].
  void setCategory(int index, {Set<String> watchedSymbols = const {}}) {
    final current = state;
    if (current is! MarketsLoaded) return;

    final filtered = _applyFilter(
      current.allMarkets,
      index,
      current.searchQuery,
      watchedSymbols: watchedSymbols,
    );
    emit(current.copyWith(
      displayedMarkets: filtered,
      categoryIndex: index,
    ));
  }

  /// Filter by search query.
  ///
  /// Re-applies the current category filter so the two filters compose
  /// correctly. When the active tab is Watchlist, [watchedSymbols] is required.
  void setSearchQuery(String query, {Set<String> watchedSymbols = const {}}) {
    final current = state;
    if (current is! MarketsLoaded) return;

    final filtered = _applyFilter(
      current.allMarkets,
      current.categoryIndex,
      query,
      watchedSymbols: watchedSymbols,
    );
    emit(current.copyWith(
      displayedMarkets: filtered,
      searchQuery: query,
    ));
  }

  /// Pull-to-refresh: re-fetches from the network and resets to "All".
  Future<void> refresh() async => loadMarkets();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  List<Market> _applyFilter(
    List<Market> all,
    int index,
    String query, {
    Set<String> watchedSymbols = const {},
  }) {
    var filtered = all;

    if (index == kWatchlistCategoryIndex) {
      // Watchlist tab: show only markets the user has starred.
      filtered = filtered
          .where((m) => watchedSymbols.contains(m.symbol))
          .toList();
    } else if (index != 1) {
      // index 1 = "All" → no category filter.
      // Any other index maps to a real category label.
      final categoryLabel = kMarketCategories[index].toLowerCase();
      filtered = filtered.where((m) => m.category == categoryLabel).toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered
          .where((m) =>
              m.symbol.toLowerCase().contains(q) ||
              m.name.toLowerCase().contains(q) ||
              m.shortName.toLowerCase().contains(q))
          .toList();
    }

    return filtered;
  }
}
