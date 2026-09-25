import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/repositories/auth_repository.dart';
import '../widgets/auth_scaffold.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.email = ''});

  final String email;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await sl<AuthRepository>().resetPassword(
        email: _email.text,
        code: _code.text,
        newPassword: _password.text,
      );
      if (!mounted) return;
      Toast.show(context, 'Password updated. Sign in with your new password.');
      context.go(Routes.login);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: AppTextStyles.headlineLarge.copyWith(color: cs.onSurface),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
    );
    return AuthScaffold(
      title: 'Enter code',
      subtitle: 'Use the 6-digit code from the email we sent, then choose a new password.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.email.isEmpty) ...[
              AppTextField(
                label: 'Email',
                controller: _email,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 18),
            ],
            Text('Verification code', style: AppTextStyles.titleSmall.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Pinput(
              length: 6,
              controller: _code,
              defaultPinTheme: pinTheme,
              focusedPinTheme: pinTheme.copyDecorationWith(
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              validator: (v) => (v ?? '').length == 6 ? null : 'Enter the 6-digit code',
              autofillHints: const [AutofillHints.oneTimeCode],
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'New password',
              controller: _password,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              autofillHints: const [AutofillHints.newPassword],
              validator: Validators.newPassword,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Confirm new password',
              controller: _confirm,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (v) => v == _password.text ? null : 'Passwords don\'t match',
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Update password', onPressed: _submit, isLoading: _busy),
          ],
        ),
      ),
    );
  }
}
