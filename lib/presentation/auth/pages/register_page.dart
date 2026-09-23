import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
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

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the terms to continue'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    context.read<AuthCubit>().register(
          displayName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _showComingSoon(BuildContext context, String providerName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coming soon: $providerName'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                  borderRadius: BorderRadius.circular(10)),
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
                title: 'Create Account',
                subtitle: 'Sign up to get started with your trading journey',
                onBackPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.login);
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
                      _buildField(
                        context: context,
                        label: 'Full Name',
                        controller: _nameController,
                        hint: 'Alex Vance',
                        icon: LucideIcons.user,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Name required' : null,
                      ),
                      const SizedBox(height: 20),
                      
                      _buildField(
                        context: context,
                        label: 'Email Address',
                        controller: _emailController,
                        hint: 'name@company.com',
                        icon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password with strength meter
                          Text('Password',
                              style: AppTextStyles.titleSmall
                                  .copyWith(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password required';
                          if (v.length < 8) return 'Min 8 chars, 1 number & symbol';
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Create a strong password',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54,
                          ),
                          prefixIcon: Icon(LucideIcons.lock,
                              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54, size: 18),
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
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure
                                  ? LucideIcons.eye
                                  : LucideIcons.eyeOff,
                              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Confirm Password
                      Text('Confirm Password',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm password';
                          if (v != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Re-enter your password',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54),
                          prefixIcon: Icon(LucideIcons.lock,
                              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54, size: 18),
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
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            child: Icon(
                              _obscureConfirm
                                  ? LucideIcons.eye
                                  : LucideIcons.eyeOff,
                              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6) ?? Colors.black54,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Terms
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (v) =>
                                  setState(() => _agreedToTerms = v ?? false),
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary, fontWeight: FontWeight.w600),
                                    recognizer: TapGestureRecognizer()..onTap = () {},
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary, fontWeight: FontWeight.w600),
                                    recognizer: TapGestureRecognizer()..onTap = () {},
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          return SizedBox(
                            height: 50,
                            child: AppButton(
                              label: 'Create Free Account →',
                              onTap: _onRegister,
                              isLoading: state is AuthLoading,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.divider)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR CONTINUE WITH',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8A9AAB),
                                )),
                          ),
                          Expanded(child: Divider(color: AppColors.divider)),
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
                              )),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: Text(
                              'Log In',
                              style: AppTextStyles.titleSmall
                                  .copyWith(color: AppColors.primary),
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

  Widget _buildField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.titleSmall
                .copyWith(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
          validator: validator,
          decoration: _inputDecoration(context: context, hint: hint, icon: icon),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      {required BuildContext context, required String hint, required IconData icon}) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium
          .copyWith(color: theme.textTheme.bodySmall?.color ?? Colors.black54),
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
}
