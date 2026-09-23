import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pinput/pinput.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/app_button.dart';
import '../widgets/auth_header.dart';
import '../cubit/forgot_password/forgot_password_cubit.dart';
import '../cubit/forgot_password/forgot_password_state.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  
  Timer? _timer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _resendOtp(BuildContext context) {
    if (_secondsRemaining == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP Resent!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _startTimer();
    }
  }

  void _verifyOtp(BuildContext context) {
    if (_otpController.text.length != 4) return;
    // Client-side navigation bypass
    context.push(AppRoutes.resetPassword);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    
    if (name.length <= 4) return email;
    
    final maskedName = '${name.substring(0, 4)}***';
    return '$maskedName@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 65,
      height: 65,
      textStyle: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else if (state is OtpVerified) {
            context.push(AppRoutes.resetPassword);
          }
        },
        builder: (context, state) {
          final isLoading = state is ForgotPasswordLoading;
          
          String displayEmail = "email@example.com";
          if (state is EmailSent) {
            displayEmail = state.email;
          } else if (state is ForgotPasswordError && context.read<ForgotPasswordCubit>().state is EmailSent) {
             displayEmail = (context.read<ForgotPasswordCubit>().state as EmailSent).email;
          }
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  title: 'Enter Code',
                  subtitle: 'We\'ve sent a 4-digit verification code to\nyour email address.',
                  onBackPressed: () => context.pop(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // Masked Email Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _maskEmail(displayEmail),
                              style: AppTextStyles.titleSmall.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: const Icon(LucideIcons.edit2, size: 14, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      Pinput(
                        length: 4,
                        controller: _otpController,
                        focusNode: _otpFocusNode,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        onCompleted: (pin) => _verifyOtp(context),
                      ),
                      const SizedBox(height: 48),

                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: AppButton(
                          label: 'Verify & Continue →',
                          onTap: () => _verifyOtp(context),
                          isLoading: isLoading,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                          GestureDetector(
                            onTap: _secondsRemaining == 0 ? () => _resendOtp(context) : null,
                            child: Text(
                              _secondsRemaining > 0
                                  ? 'Resend in ${_formatTime(_secondsRemaining)}'
                                  : 'Resend OTP',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: _secondsRemaining > 0
                                    ? AppColors.textTertiary
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Spam folder check helper card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.alertCircle,
                                size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check your spam folder',
                                    style: AppTextStyles.titleSmall.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "If you don't see the email in your inbox, please check your spam or junk folder.",
                                    style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
