import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_avatar.dart';
import '../auth/session_cubit.dart';

/// Bottom navigation around the five tab branches. Each branch keeps its own
/// navigation stack and scroll position (StatefulShellRoute.indexedStack).
///
/// Visual tab order (company spec) vs. GoRouter branch indices:
///
///   Visual 0 → Branch 0  (Home / Feed)
///   Visual 1 → Branch 3  (Communities)
///   Visual 2 → Branch 2  (Markets)
///   Visual 3 → Branch 1  (Notifications)   ← branch promoted from full-screen route
///   Visual 4 → Branch 4  (Profile)
///
/// DiscoverPage is still accessible via context.push(Routes.discover) from the
/// Feed search button and all deep-links — it is no longer a tab root.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Maps visual tab position → GoRouter branch index.
  /// Changing the visual order here is the ONLY thing needed to reorder tabs.
  static const _branchForPos = [0, 3, 2, 1, 4];

  /// Icon spec per visual position (inactive, active, semanticLabel).
  /// Position 4 (Profile) is rendered separately with AppAvatar.
  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.people_outline_rounded, Icons.people_rounded, 'Communities'),
    (Icons.bar_chart_rounded, Icons.bar_chart_rounded, 'Markets'),
    (Icons.notifications_none_rounded, Icons.notifications_rounded, 'Notifications'),
  ];

  /// Visual position of the currently active branch.
  int _activeVisualPos() => _branchForPos.indexOf(shell.currentIndex);

  void _onTap(int visualPos) {
    final branchIdx = _branchForPos[visualPos];
    // Re-tapping the current tab pops it back to its root.
    shell.goBranch(branchIdx, initialLocation: branchIdx == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final activeVisual = _activeVisualPos();

    // Pull session user for the profile avatar tab.
    final user = context.select((SessionCubit s) => s.state.userOrNull);

    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.22 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // ── Icon tabs (visual positions 0–3) ──
                for (var i = 0; i < _items.length; i++)
                  _IconNavItem(
                    icon: _items[i].$1,
                    activeIcon: _items[i].$2,
                    label: _items[i].$3,
                    active: activeVisual == i,
                    dark: dark,
                    onTap: () => _onTap(i),
                  ),

                // ── Profile tab (visual position 4) ──
                _AvatarNavItem(
                  active: activeVisual == 4,
                  dark: dark,
                  avatarUrl: user?.avatarUrl,
                  displayName: user?.displayName,
                  onTap: () => _onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon nav item (visual positions 0–3) — minimalist, no pill background.
// ─────────────────────────────────────────────────────────────────────────────

class _IconNavItem extends StatelessWidget {
  const _IconNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.dark,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = dark ? AppColors.primaryLight : AppColors.primary;
    final inactiveColor = dark ? AppColors.darkTextTertiary : AppColors.textTertiary;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          // Generous tap target that fills the available space.
          height: 60,
          width: 56,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Icon(
                active ? activeIcon : icon,
                // ValueKey drives AnimatedSwitcher to cross-fade when active flips.
                key: ValueKey(active),
                size: 26,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar nav item (visual position 4 — Profile)
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarNavItem extends StatelessWidget {
  const _AvatarNavItem({
    required this.active,
    required this.dark,
    required this.onTap,
    this.avatarUrl,
    this.displayName,
  });

  final bool active;
  final bool dark;
  final VoidCallback onTap;
  final String? avatarUrl;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final activeColor = dark ? AppColors.primaryLight : AppColors.primary;

    return Semantics(
      button: true,
      selected: active,
      label: 'Profile',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 60,
          width: 56,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Active: 2px solid brand ring. Inactive: transparent — no background.
                border: Border.all(
                  color: active ? activeColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: AppAvatar(
                url: avatarUrl,
                name: displayName,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
