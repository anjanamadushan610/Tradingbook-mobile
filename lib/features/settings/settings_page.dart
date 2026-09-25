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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Group('Account'),
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: const Text('Email'),
            subtitle: Text(user.email ?? '—'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Edit profile'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.editProfile),
          ),
          if (user.hasPassword)
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: const Text('Change password'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.changePassword),
            )
          else
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Signed in with Google'),
              subtitle: const Text('Your password is managed by your Google account.'),
            ),
          ListTile(
            leading: const Icon(Icons.block_rounded),
            title: const Text('Blocked traders'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.blockedUsers),
          ),

          const _Group('Content'),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Your posts & review status'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.myPosts),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border_rounded),
            title: const Text('Saved posts'),
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
              title: const Text('Review queue'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.moderation),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('User reports'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.moderationReports),
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Audit log'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.moderationAudit),
            ),
          ],

          const _Group('About'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => launchUrl(Uri.parse(AppConfig.privacyPolicyUrl), mode: LaunchMode.inAppBrowserView),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of service'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => launchUrl(Uri.parse(AppConfig.termsUrl), mode: LaunchMode.inAppBrowserView),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded),
            title: const Text('Contact support'),
            subtitle: const Text(AppConfig.supportEmail),
            onTap: () => launchUrl(Uri.parse('mailto:${AppConfig.supportEmail}?subject=TradingBook%20app%20support')),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Open-source licenses'),
              subtitle: snap.hasData ? Text('Version ${snap.data!.version} (${snap.data!.buildNumber})') : null,
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
