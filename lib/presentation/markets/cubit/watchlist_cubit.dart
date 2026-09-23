import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'watchlist_state.dart';

/// SharedPreferences key under which the watchlist is persisted.
const _kWatchlistKey = 'watchlist_symbols';

/// Cubit responsible for managing the user's persistent watchlist.
///
/// On construction it accepts a [SharedPreferences] instance (already
/// initialised in main.dart) so it can restore the previous session's
/// watchlist synchronously in the initialiser list.
///
/// Every [toggleWatchlist] call:
///   1. Emits a new immutable [WatchlistState] so the UI rebuilds instantly.
///   2. Persists the updated set to [SharedPreferences] in the background.
class WatchlistCubit extends Cubit<WatchlistState> {
  final SharedPreferences _prefs;

  WatchlistCubit(this._prefs)
      : super(
          WatchlistState(
            watchedSymbols: Set<String>.from(
              _prefs.getStringList(_kWatchlistKey) ?? [],
            ),
          ),
        );

  /// Adds [symbol] to the watchlist if absent, removes it if present.
  /// Persists the result to [SharedPreferences] asynchronously.
  void toggleWatchlist(String symbol) {
    final next = state.copyWithToggled(symbol);
    emit(next);
    // Fire-and-forget persistence — no await needed; failure is non-critical.
    _prefs.setStringList(_kWatchlistKey, next.watchedSymbols.toList());
  }
}
