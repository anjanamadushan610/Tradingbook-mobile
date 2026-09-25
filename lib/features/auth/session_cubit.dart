import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

sealed class SessionState extends Equatable {
  const SessionState();

  UserProfile? get userOrNull =>
      this is Authenticated ? (this as Authenticated).user : null;

  @override
  List<Object?> get props => [];
}

class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class Unauthenticated extends SessionState {
  const Unauthenticated({this.expired = false});

  /// True when we got here because the server rejected the session, so the
  /// login screen can say so instead of silently appearing.
  final bool expired;

  @override
  List<Object?> get props => [expired];
}

class Authenticated extends SessionState {
  const Authenticated(this.user);
  final UserProfile user;

  @override
  List<Object?> get props => [user];
}

/// The single source of truth for "who is signed in". Everything else reads
/// the user from here; nothing else writes tokens except the repositories it
/// drives.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._auth, this._prefs) : super(const SessionUnknown());

  final AuthRepository _auth;
  final SharedPreferences _prefs;

  static const _cachedUserKey = 'tb_cached_user';

  /// Hooks for side effects that follow the session (push registration,
  /// cache resets). Set during bootstrap.
  Future<void> Function(UserProfile user)? onSignedIn;
  Future<void> Function()? onSigningOut;

  UserProfile? get user => state.userOrNull;

  /// Cold start. With stored tokens we show the cached profile immediately
  /// (the app is usable offline) and refresh it in the background.
  Future<void> bootstrap() async {
    if (!await _auth.hasSession()) {
      emit(const Unauthenticated());
      return;
    }
    final cached = _readCachedUser();
    if (cached != null) {
      emit(Authenticated(cached));
      onSignedIn?.call(cached);
      refreshProfile();
      return;
    }
    try {
      await _adopt(await _auth.fetchMe());
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        emit(const Unauthenticated());
      } else {
        // Offline with no cached profile: nothing to show but the login
        // screen; tokens stay, so the next launch can still resume.
        emit(const Unauthenticated());
      }
    }
  }

  Future<void> refreshProfile() async {
    try {
      final me = await _auth.fetchMe();
      if (state is Authenticated) _store(me);
    } catch (_) {}
  }

  Future<void> signedIn(UserProfile user) => _adopt(user);

  /// Local profile edits (the API returns the updated profile).
  void profileUpdated(UserProfile user) {
    if (state is Authenticated) _store(user);
  }

  Future<void> signOut() async {
    try {
      await onSigningOut?.call();
    } catch (_) {}
    await _auth.logout();
    await _prefs.remove(_cachedUserKey);
    emit(const Unauthenticated());
  }

  /// Called by the network layer when the refresh token is rejected.
  void sessionExpired() {
    if (state is! Authenticated) return;
    _auth.logout();
    _prefs.remove(_cachedUserKey);
    emit(const Unauthenticated(expired: true));
  }

  /// After account deletion the tokens are already gone server-side.
  Future<void> accountDeleted() async {
    await _prefs.remove(_cachedUserKey);
    emit(const Unauthenticated());
  }

  Future<void> _adopt(UserProfile user) async {
    _store(user);
    await onSignedIn?.call(user);
  }

  void _store(UserProfile user) {
    emit(Authenticated(user));
    _prefs.setString(_cachedUserKey, jsonEncode(_toJson(user)));
  }

  UserProfile? _readCachedUser() {
    final raw = _prefs.getString(_cachedUserKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toJson(UserProfile u) => {
        'id': u.id,
        'displayName': u.displayName,
        'bio': u.bio,
        'avatarUrl': u.avatarUrl,
        'coverUrl': u.coverUrl,
        'interests': u.interests,
        'languages': u.languages,
        'isPrivate': u.isPrivate,
        'createdAt': u.createdAt.millisecondsSinceEpoch,
        'email': u.email,
        'platformRole': u.platformRole,
        'authProvider': u.authProvider?.name,
      };
}
