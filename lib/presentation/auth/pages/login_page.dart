import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../widgets/app_button.dart';
import '../widgets/auth_header.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }



  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.home);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SingleChildScrollView(
          child: Column(
            children: [
              AuthHeader(
                title: 'Welcome Back',
                subtitle: 'Sign in to dive into your account',
                onBackPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    SystemNavigator.pop();
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // === Form Fields ===
                          Text(
                            'Email Address',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                        decoration: _inputDecoration(
                          context: context,
                          hint: 'name@company.com',
                          icon: LucideIcons.mail,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Password',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.forgotPassword),
                            child: Text(
                              'Forgot password?',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _PasswordField(controller: _passwordController),
                      const SizedBox(height: 32),

                      // === Sign In Button ===
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          return SizedBox(
                            height: 50,
                            child: AppButton(
                              label: 'Sign In to Terminal →',
                              onTap: _onLogin,
                              isLoading: state is AuthLoading,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // === Social Login ===
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(color: AppColors.divider),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR CONTINUE WITH',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8A9AAB),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: AppColors.divider),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: () => _showComingSoon(context, 'Google SSO'),
                                icon: Image.asset('assets/icons/google.png', height: 24, errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, color: Colors.blue, size: 32)),
                                label: const Text('Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: () => _showComingSoon(context, 'Apple SSO'),
                                icon: const Icon(Icons.apple, size: 24, color: Colors.black87),
                                label: const Text('Apple', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // === Active Traders Banner ===
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 32,
                              child: Stack(
                                children: [
                                  for (var i = 0; i < 3; i++)
                                    Positioned(
                                      left: i * 20.0,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: NetworkImage('https://i.pravatar.cc/100?img=${i + 11}'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '14,820 Active Traders Online',
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Connect with top traders, analyze markets.',
                                    style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // === Register Link ===
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.register),
                            child: Text(
                              'Create Account',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required BuildContext context, required String hint, required IconData icon}) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: theme.textTheme.bodySmall?.color ?? Colors.black54),
      prefixIcon: Icon(icon, color: theme.iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54, size: 18),
      filled: true,
      fillColor: theme.colorScheme.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  void _showComingSoon(BuildContext ctx, String feature) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordField({required this.controller});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      style: AppTextStyles.bodyMedium.copyWith(color: theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password required';
        if (v.length < 8) return 'Min 8 characters';
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Enter your password',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: theme.textTheme.bodySmall?.color ?? Colors.black54,
        ),
        prefixIcon: Icon(LucideIcons.lock,
            color: theme.iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54, size: 18),
        filled: true,
        fillColor: theme.colorScheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
            color: theme.iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54,
            size: 18,
          ),
        ),
      ),
    );
  }
}


