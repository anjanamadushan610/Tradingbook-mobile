import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/push/push_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/auth_repository.dart';
import '../auth/session_cubit.dart';

/// In-app account deletion (a Google Play requirement for any app with
/// accounts). Password accounts re-enter their password; social accounts
/// type DELETE.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete(bool hasPassword) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete your account?',
      message: 'This is permanent. Your profile, posts, comments and follows will be removed.',
      confirmLabel: 'Delete forever',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await sl<PushService>().unregister();
      await sl<AuthRepository>().deleteAccount(password: hasPassword ? _confirm.text : null);
      if (!mounted) return;
      Toast.show(context, 'Your account has been deleted.');
      await context.read<SessionCubit>().accountDeleted();
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit s) => s.state.userOrNull);
    final hasPassword = user?.hasPassword ?? true;
    final cs = Theme.of(context).colorScheme;
    final ready = hasPassword ? _confirm.text.isNotEmpty : _confirm.text.trim() == 'DELETE';
    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 32),
                const SizedBox(height: 8),
                Text('This can\'t be undone', style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface)),
                const SizedBox(height: 8),
                Text(
                  '• Your profile, posts and comments are permanently removed.\n'
                  '• Your followers, follows, likes and saved posts are deleted.\n'
                  '• Groups and pages you own should be deleted or handed over first.\n'
                  '• You\'ll be signed out on every device.',
                  style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: hasPassword ? 'Enter your password to confirm' : 'Type DELETE to confirm',
            controller: _confirm,
            isPassword: hasPassword,
            textCapitalization: hasPassword ? TextCapitalization.none : TextCapitalization.characters,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Delete my account',
            style: AppButtonStyle.danger,
            isLoading: _busy,
            onPressed: ready ? () => _delete(hasPassword) : null,
          ),
        ],
      ),
    );
  }
}
