import 'package:equatable/equatable.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

class EmailSent extends ForgotPasswordState {
  final String email;

  const EmailSent(this.email);

  @override
  List<Object?> get props => [email];
}

class OtpVerified extends ForgotPasswordState {
  final String email;
  final String otp;

  const OtpVerified(this.email, this.otp);

  @override
  List<Object?> get props => [email, otp];
}

class PasswordResetSuccess extends ForgotPasswordState {
  const PasswordResetSuccess();
}

class ForgotPasswordError extends ForgotPasswordState {
  final String message;

  const ForgotPasswordError(this.message);

  @override
  List<Object?> get props => [message];
}
