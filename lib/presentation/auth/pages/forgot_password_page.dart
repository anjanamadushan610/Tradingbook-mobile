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

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your registered email'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    // Client-side navigation bypass
    context.push(AppRoutes.otp);
  }

  @override
  Widget build(BuildContext context) {
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else if (state is EmailSent) {
            context.push(AppRoutes.otp);
          }
        },
        builder: (context, state) {
          final isLoading = state is ForgotPasswordLoading;
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  title: 'Forgot Password',
                  subtitle: 'Enter your registered email address to receive\na secure verification code.',
                  onBackPressed: () {
                    context.read<ForgotPasswordCubit>().resetFlow();
                    context.go(AppRoutes.login);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Email Field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Registered Email Address',
                              style: AppTextStyles.titleSmall
                                  .copyWith(color: AppColors.textSecondary)),
                          Text('Required',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _sendResetLink(),
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'trader@nexustrader.com',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textTertiary),
                          prefixIcon: const Icon(LucideIcons.mail,
                              color: AppColors.textTertiary, size: 18),
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
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        height: 50,
                        child: AppButton(
                          label: 'Send Reset Link →',
                          onTap: _sendResetLink,
                          isLoading: isLoading,
                        ),
                      ),
                      const SizedBox(height: 40),

                      GestureDetector(
                        onTap: () {
                          context.read<ForgotPasswordCubit>().resetFlow();
                          context.go(AppRoutes.login);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.arrowLeft,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Back to Sign In',
                              style: AppTextStyles.titleSmall
                                  .copyWith(color: AppColors.primary),
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
