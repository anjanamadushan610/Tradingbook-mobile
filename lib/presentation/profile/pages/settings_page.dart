import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../widgets/app_avatar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  OwnUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final cubitUser = context.read<AuthCubit>().currentUser;
    if (cubitUser != null) {
      if (mounted) {
        setState(() {
          _user = cubitUser;
          _isLoading = false;
        });
      }
      _refreshUser();
    } else {
      await _refreshUser();
    }
  }

  Future<void> _refreshUser() async {
    try {
      final user = await context.read<AuthRepository>().getMe();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar(context)),
              SliverToBoxAdapter(child: _buildProfileCard(context)),
              SliverToBoxAdapter(
                  child: _buildSection(context, 'ACCOUNT & SECURITY', _buildAccountSection())),
              SliverToBoxAdapter(
                  child: _buildSection(context, 'PREFERENCES', _buildPreferencesSection(context))),
              SliverToBoxAdapter(
                  child: _buildSection(context, 'SUPPORT & LEGAL', _buildSupportSection())),
              SliverToBoxAdapter(
                  child: _buildSection(context, 'ACCOUNT ACTIONS', _buildActionsSection(context))),
              SliverToBoxAdapter(child: _buildVersionFooter()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          const SizedBox(width: 4),
          Text('Settings', style: AppTextStyles.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync_rounded,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text('Synced',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                _isLoading 
                    ? const SizedBox(
                        width: 50, 
                        height: 50, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : AppAvatar(
                        imageUrl: _user?.avatarUrl,
                        name: _user?.displayName ?? 'User',
                        size: 50,
                      ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isLoading 
                  ? const Text('Loading...')
                  : Text(
                      _user?.displayName ?? 'Alex Trader',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded,
                        size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('Edit', style: AppTextStyles.titleSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(title,
                style: AppTextStyles.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      children: [
        _SettingsTile(
          icon: Icons.email_outlined,
          title: 'Primary Email',
          subtitle: _isLoading ? 'Loading...' : (_user?.email ?? 'alex.trader@nexus.app'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00647C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Verified',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ),
        const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
        const _SettingsTile(
          icon: Icons.security_outlined,
          title: 'Password & Security',
          subtitle: '2FA enabled, last changed 32d ago',
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (context, currentMode) {
            final cubit = context.read<ThemeCubit>();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Interface Theme', style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${currentMode.label} Active',
                          style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ThemeChip(
                            label: 'Light',
                            icon: Icons.wb_sunny_outlined,
                            isSelected: currentMode == AppThemeMode.light,
                            onTap: () => cubit.setTheme(AppThemeMode.light),
                          ),
                        ),
                        Container(width: 1, height: 24, color: Theme.of(context).colorScheme.outlineVariant),
                        Expanded(
                          child: _ThemeChip(
                            label: 'Dark',
                            icon: Icons.bedtime_outlined,
                            isSelected: currentMode == AppThemeMode.dark,
                            onTap: () => cubit.setTheme(AppThemeMode.dark),
                          ),
                        ),
                        Container(width: 1, height: 24, color: Theme.of(context).colorScheme.outlineVariant),
                        Expanded(
                          child: _ThemeChip(
                            label: 'Auto',
                            icon: Icons.brightness_auto_outlined,
                            isSelected: currentMode == AppThemeMode.system,
                            onTap: () => cubit.setTheme(AppThemeMode.system),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Push Notifications',
          subtitle: 'Direct mentions & copy-trade triggers',
          trailingSwitch: true,
          switchValue: _pushNotifications,
          onSwitchChanged: (v) => setState(() => _pushNotifications = v),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return const Column(
      children: [
        _SettingsTile(
          icon: Icons.description_outlined,
          title: 'Privacy Policy',
        ),
        Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
        _SettingsTile(
          icon: Icons.menu_book_outlined,
          title: 'Terms of Service',
        ),
        Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
        _SettingsTile(
          icon: Icons.people_outline_rounded,
          title: 'Community Conduct Guidelines',
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showLogoutDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.logout_rounded,
                      size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Log Out', style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                      const SizedBox(height: 2),
                      Text('End current session across this device',
                          style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.outline, size: 20),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
        GestureDetector(
          onTap: () {
            // Handle delete account
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.error),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delete Account',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                          'Irreversible. Liquidates active social badges',
                          style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.error, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersionFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.show_chart_rounded,
                    color: Colors.white, size: 10),
              ),
              const SizedBox(width: 6),
              Text('Nexus Trading Terminal Mobile',
                  style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Version 4.18.2 (Build 9042) • Production Core',
              style: AppTextStyles.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out?'),
        content: const Text(
            'You will need to sign back in to access your trading terminal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthCubit>().logout();
            },
            child: const Text('Log Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool trailingSwitch;
  final bool? switchValue;
  final void Function(bool)? onSwitchChanged;
  final String? trailingLabel;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingSwitch = false,
    this.switchValue,
    this.onSwitchChanged,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          if (trailingSwitch && switchValue != null)
            Switch(
              value: switchValue!,
              onChanged: onSwitchChanged,
              activeColor: Colors.white,
              activeTrackColor: Theme.of(context).colorScheme.primary,
            )
          else if (trailing != null)
            trailing!
          else if (trailingLabel != null)
            Text(trailingLabel!, style: AppTextStyles.caption)
          else
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.outline, size: 20),
        ],
      ),
    );
  }
}
