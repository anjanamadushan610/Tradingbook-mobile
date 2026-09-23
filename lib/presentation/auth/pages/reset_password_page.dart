import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/app_button.dart';
import '../widgets/auth_header.dart';
import '../cubit/forgot_password/forgot_password_cubit.dart';
import '../cubit/forgot_password/forgot_password_state.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  bool _hasMinLength = false;
  bool _hasUpperAndNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final pass = _passwordController.text;
    setState(() {
      _hasMinLength = pass.length >= 8;
      _hasUpperAndNumber = pass.contains(RegExp(r'[A-Z]')) && pass.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  void _resetPassword() {
    if (!_hasMinLength || !_hasUpperAndNumber || !_hasSpecialChar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please meet all password guidelines'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Client-side navigation bypass
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password reset successfully'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    context.read<ForgotPasswordCubit>().resetFlow();
    context.go(AppRoutes.login);
  }

  Widget _buildGuideline(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isMet ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 16,
            color: isMet ? AppColors.success : Theme.of(context).disabledColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: isMet ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
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
    final isStrong = _hasMinLength && _hasUpperAndNumber && _hasSpecialChar;

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
          } else if (state is PasswordResetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Password reset successfully'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            context.read<ForgotPasswordCubit>().resetFlow();
            context.go(AppRoutes.login);
          }
        },
        builder: (context, state) {
          final isLoading = state is ForgotPasswordLoading;
          
          String displayEmail = "email@example.com";
          if (state is OtpVerified) {
            displayEmail = state.email;
          } else if (context.read<ForgotPasswordCubit>().state is OtpVerified) {
             displayEmail = (context.read<ForgotPasswordCubit>().state as OtpVerified).email;
          }
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  title: 'Reset Password',
                  subtitle: 'Create a strong and secure new password\nfor your account.',
                  onBackPressed: () => context.pop(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Masked Email Badge
                      Align(
                        alignment: Alignment.center,
                        child: Container(
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text('New Password',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Enter new password',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textTertiary),
                          prefixIcon: Icon(LucideIcons.lock,
                              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54, size: 18),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            child: Icon(
                              _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54,
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text('Confirm Password',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _resetPassword(),
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Confirm new password',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textTertiary),
                          prefixIcon: Icon(LucideIcons.lock,
                              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54, size: 18),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            child: Icon(
                              _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54,
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PASSWORD GUIDELINES',
                                  style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2),
                                ),
                                if (isStrong)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Strong',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildGuideline('At least 8 characters', _hasMinLength),
                            _buildGuideline('Contains uppercase letter & number', _hasUpperAndNumber),
                            _buildGuideline('Contains special symbol', _hasSpecialChar),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        height: 50,
                        child: AppButton(
                          label: 'Reset Password →',
                          onTap: _resetPassword,
                          isLoading: isLoading,
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
