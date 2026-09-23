import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _authRepository;

  // Cached state for a continuous 3-step flow
  String? _email;
  String? _otp;

  ForgotPasswordCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const ForgotPasswordInitial());

  Future<void> sendResetLink(String email) async {
    emit(const ForgotPasswordLoading());
    try {
      await _authRepository.forgotPassword(email);
      _email = email;
      emit(EmailSent(email));
    } catch (e) {
      emit(ForgotPasswordError(_extractMessage(e)));
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (_email == null) {
      emit(const ForgotPasswordError('Email is missing. Please restart the flow.'));
      return;
    }

    emit(const ForgotPasswordLoading());
    try {
      await _authRepository.verifyOtp(_email!, otp);
      _otp = otp;
      emit(OtpVerified(_email!, otp));
    } catch (e) {
      emit(ForgotPasswordError(_extractMessage(e)));
    }
  }

  Future<void> resetPassword(String newPassword) async {
    if (_email == null || _otp == null) {
      emit(const ForgotPasswordError('Email or OTP is missing. Please restart the flow.'));
      return;
    }

    emit(const ForgotPasswordLoading());
    try {
      await _authRepository.resetPassword(_email!, _otp!, newPassword);
      emit(const PasswordResetSuccess());
    } catch (e) {
      emit(ForgotPasswordError(_extractMessage(e)));
    }
  }

  void resetFlow() {
    _email = null;
    _otp = null;
    emit(const ForgotPasswordInitial());
  }

  String _extractMessage(dynamic e) {
    if (e is Exception) {
      final str = e.toString();
      return str.replaceFirst('Exception: ', '');
    }
    return 'An unexpected error occurred';
  }
}
