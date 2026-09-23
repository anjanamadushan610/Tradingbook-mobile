import 'package:equatable/equatable.dart';

/// Immutable state for the [WatchlistCubit].
///
/// [watchedSymbols] is the canonical set of market symbols the user has
/// added to their watchlist (e.g. {"XAU/USD", "BTC/USD"}).
/// Using a [Set] guarantees O(1) lookup for `isWatched` checks and prevents
/// accidental duplicates.
class WatchlistState extends Equatable {
  final Set<String> watchedSymbols;

  const WatchlistState({this.watchedSymbols = const {}});

  /// Returns `true` if [symbol] is currently in the watchlist.
  bool isWatched(String symbol) => watchedSymbols.contains(symbol);

  /// Returns a new [WatchlistState] with [symbol] toggled in or out.
  WatchlistState copyWithToggled(String symbol) {
    final updated = Set<String>.from(watchedSymbols);
    if (updated.contains(symbol)) {
      updated.remove(symbol);
    } else {
      updated.add(symbol);
    }
    return WatchlistState(watchedSymbols: updated);
  }

  @override
  List<Object?> get props => [watchedSymbols];
}
