import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's starred symbols, kept on-device (the backend has no watchlist
/// API — the web app keeps it client-side too).
class WatchlistCubit extends Cubit<List<String>> {
  WatchlistCubit(this._prefs) : super(_prefs.getStringList(_key) ?? defaults);

  final SharedPreferences _prefs;
  static const _key = 'tb_watchlist';

  /// The platform's default watchlist (same as `GET /api/markets/details`
  /// with no symbols).
  static const defaults = ['BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'XRPUSDT', 'DOGEUSDT'];

  bool contains(String symbol) => state.contains(symbol);

  void toggle(String symbol) {
    final next = contains(symbol)
        ? state.where((s) => s != symbol).toList()
        : [...state, symbol].take(25).toList();
    emit(next);
    _prefs.setStringList(_key, next);
  }
}
