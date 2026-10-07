import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/routes.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/widgets/feedback.dart';
import '../auth/session_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Sign out?',
      message: 'You can sign back in any time.',
      confirmLabel: 'Sign out',
    );
    if (ok && context.mounted) await context.read<SessionCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit s) => s.state.userOrNull);
    final theme = context.watch<ThemeCubit>().state;
    if (user == null) return const Scaffold();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface))),
      body: ListView(
        children: [
          const _Group('Account'),
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: Text('Email', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
            subtitle: Text(user.email ?? '—', style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text('Edit profile', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.editProfile),
          ),
          if (user.hasPassword)
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: Text('Change password', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.changePassword),
            )
          else
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text('Signed in with Google', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
              subtitle: Text('Your password is managed by your Google account.', style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
            ),
          ListTile(
            leading: const Icon(Icons.block_rounded),
            title: Text('Blocked traders', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.blockedUsers),
          ),

          const _Group('Content'),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: Text('Your posts & review status', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.myPosts),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border_rounded),
            title: Text('Saved posts', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.bookmarks),
          ),

          const _Group('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(value: AppThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                ButtonSegment(value: AppThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                ButtonSegment(value: AppThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Auto')),
              ],
              selected: {theme},
              onSelectionChanged: (s) => context.read<ThemeCubit>().setTheme(s.first),
            ),
          ),

          if (user.isModerator) ...[
            const _Group('Moderation'),
            ListTile(
              leading: const Icon(Icons.gavel_rounded),
              title: Text('Review queue', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.moderation),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text('User reports', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.moderationReports),
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text('Audit log', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.moderationAudit),
            ),
          ],

          const _Group('About'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy policy', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => launchUrl(Uri.parse(AppConfig.privacyPolicyUrl), mode: LaunchMode.inAppBrowserView),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text('Terms of service', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => launchUrl(Uri.parse(AppConfig.termsUrl), mode: LaunchMode.inAppBrowserView),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded),
            title: Text('Contact support', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
            subtitle: Text(AppConfig.supportEmail, style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
            onTap: () => launchUrl(Uri.parse('mailto:${AppConfig.supportEmail}?subject=TradingBook%20app%20support')),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text('Open-source licenses', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
              subtitle: snap.hasData ? Text('Version ${snap.data!.version} (${snap.data!.buildNumber})', style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)) : null,
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'TradingBook',
                applicationVersion: snap.data?.version,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ),
          TextButton(
            onPressed: () => context.push(Routes.deleteAccount),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete account'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.labelMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
}
