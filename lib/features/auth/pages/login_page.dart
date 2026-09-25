import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/repositories/auth_repository.dart';
import '../session_cubit.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/google_sign_in_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionCubit>().state;
    if (session is Unauthenticated && session.expired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Toast.show(context, 'Your session expired. Please sign in again.');
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final user = await sl<AuthRepository>().login(
        email: _email.text,
        password: _password.text,
      );
      TextInput.finishAutofillContext();
      if (mounted) await context.read<SessionCubit>().signedIn(user);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to follow traders, share setups and track markets.',
      showBack: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Email',
              hint: 'name@example.com',
              controller: _email,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Password',
              hint: 'Your password',
              controller: _password,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
              validator: (v) => Validators.required(v, 'Password'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(Routes.forgotPassword),
                child: Text(
                  'Forgot password?',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AppButton(label: 'Sign in', onPressed: _submit, isLoading: _busy),
            if (GoogleSignInButton.isEnabled) ...[
              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: AppTextStyles.labelMedium.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),
              const GoogleSignInButton(),
            ],
            const SizedBox(height: 16),
            AuthSwitchLink(
              prompt: 'New to TradingBook?',
              action: 'Create account',
              onTap: () => context.push(Routes.signup),
            ),
          ],
        ),
      ),
    );
  }
}
