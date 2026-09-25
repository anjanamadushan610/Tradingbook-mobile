import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
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

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _accepted = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_accepted) {
      Toast.show(context, 'Please accept the Terms and Privacy Policy.', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final result = await sl<AuthRepository>().signup(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
      );
      if (!mounted) return;
      switch (result) {
        case SignupSignedIn(:final user):
          await context.read<SessionCubit>().signedIn(user);
        case SignupVerificationPending():
          context.go(Routes.verifyEmail(_email.text.trim()));
      }
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final linkStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );
    return AuthScaffold(
      title: 'Create account',
      subtitle: 'Join traders sharing setups, ideas and market calls.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Display name',
              hint: 'How traders will see you',
              controller: _name,
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              maxLength: 80,
              validator: Validators.displayName,
            ),
            const SizedBox(height: 8),
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
              hint: 'At least 8 characters',
              controller: _password,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: Validators.newPassword,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _accepted,
                  onChanged: (v) => setState(() => _accepted = v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: linkStyle,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrl(Uri.parse(AppConfig.termsUrl)),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: linkStyle,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrl(Uri.parse(AppConfig.privacyPolicyUrl)),
                          ),
                          const TextSpan(
                            text: '. Posts are about markets, not financial advice.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(label: 'Create account', onPressed: _submit, isLoading: _busy),
            if (GoogleSignInButton.isEnabled) ...[
              const SizedBox(height: 12),
              const GoogleSignInButton(),
            ],
            const SizedBox(height: 12),
            AuthSwitchLink(
              prompt: 'Already have an account?',
              action: 'Sign in',
              onTap: () => context.canPop() ? context.pop() : context.go(Routes.login),
            ),
          ],
        ),
      ),
    );
  }
}
