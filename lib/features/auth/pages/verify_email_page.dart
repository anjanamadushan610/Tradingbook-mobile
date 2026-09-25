import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/app_button.dart';
import '../widgets/auth_scaffold.dart';

/// Shown after sign-up in production: the account only exists once the
/// emailed link is opened (it expires after 24 hours).
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AuthScaffold(
      title: 'Check your inbox',
      subtitle: 'One more step to activate your account.',
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'We sent a verification link to',
                  style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(email, style: AppTextStyles.titleLarge.copyWith(color: cs.onSurface)),
                const SizedBox(height: 12),
                Text(
                  'Open it on this phone or any device, then come back and sign in. '
                  'The link expires in 24 hours. Check spam if you don\'t see it.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(label: 'I\'ve verified — sign in', onPressed: () => context.go(Routes.login)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go(Routes.signup),
            child: const Text('Use a different email'),
          ),
        ],
      ),
    );
  }
}
