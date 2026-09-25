import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/auth_repository.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final revoked = await sl<AuthRepository>().changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (!mounted) return;
      final others = revoked - 1;
      Toast.show(
        context,
        others > 0
            ? 'Password changed. Signed out of $others other device${others == 1 ? '' : 's'}.'
            : 'Password changed.',
      );
      context.pop();
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              label: 'Current password',
              controller: _current,
              isPassword: true,
              autofillHints: const [AutofillHints.password],
              validator: (v) => Validators.required(v, 'Current password'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'New password',
              controller: _next,
              isPassword: true,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) {
                final err = Validators.newPassword(v);
                if (err != null) return err;
                return v == _current.text ? 'New password must be different' : null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirm new password',
              controller: _confirm,
              isPassword: true,
              validator: (v) => v == _next.text ? null : 'Passwords don\'t match',
            ),
            const SizedBox(height: 12),
            Text(
              'Changing your password signs you out everywhere else.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Update password', onPressed: _submit, isLoading: _busy),
          ],
        ),
      ),
    );
  }
}
