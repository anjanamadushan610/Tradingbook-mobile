import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  OwnUser? _currentUser;
  OwnUser? get currentUser => _currentUser;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial());

  /// Called on app startup to check if user is already authenticated
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());
    try {
      final hasSession = await _authRepository.hasValidSession();
      if (hasSession) {
        final user = await _authRepository.getMe();
        _currentUser = user;
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } on NetworkException catch (e) {
      // Don't clear session on network failures. Show error and stay on current state.
      emit(AuthError(e.message));
    } catch (_) {
      await _authRepository.logout();
      _currentUser = null;
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final session = await _authRepository.login(
        email: email,
        password: password,
      );
      _currentUser = session.user;
      emit(AuthAuthenticated(session.user));
    } catch (e) {
      emit(AuthError(_extractMessage(e)));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    emit(const AuthLoading());
    try {
      final session = await _authRepository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _currentUser = session.user;
      emit(AuthAuthenticated(session.user));
    } catch (e) {
      emit(AuthError(_extractMessage(e)));
    }
  }

  Future<void> refreshCurrentUser() async {
    try {
      final user = await _authRepository.getMe();
      _currentUser = user;
      emit(AuthAuthenticated(user));
    } catch (_) {
      // Silently fail — don't disrupt UX
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    emit(const AuthUnauthenticated());
  }

  String _extractMessage(dynamic e) {
    if (e is Exception) {
      final str = e.toString();
      // Strip 'Exception: ' prefix
      return str.replaceFirst('Exception: ', '');
    }
    return 'An unexpected error occurred';
  }
}
