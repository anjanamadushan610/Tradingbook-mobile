import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── State ───────────────────────────────────────────────────────────────────

/// The three choices exposed to the user and stored in SharedPreferences.
enum AppThemeMode { light, dark, system }

extension AppThemeModeX on AppThemeMode {
  /// Converts to Flutter's [ThemeMode] for [MaterialApp].
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Human-readable label for the UI.
  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'Auto';
    }
  }

  /// Persistence key value stored in SharedPreferences.
  String get _key {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  static AppThemeMode fromKey(String? key) {
    switch (key) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
        return AppThemeMode.system;
      default:
        return AppThemeMode.system; // Default: follow OS
    }
  }
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class ThemeCubit extends Cubit<AppThemeMode> {
  static const _prefKey = 'trading_book_theme_mode';

  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_loadSavedMode(_prefs));

  /// Reads persisted theme on cold start — synchronous because
  /// [SharedPreferences] is already initialised before [runApp].
  static AppThemeMode _loadSavedMode(SharedPreferences prefs) {
    final saved = prefs.getString(_prefKey);
    return AppThemeModeX.fromKey(saved);
  }

  /// Switches the theme and persists the choice immediately.
  Future<void> setTheme(AppThemeMode mode) async {
    emit(mode);
    await _prefs.setString(_prefKey, mode._key);
  }
}
