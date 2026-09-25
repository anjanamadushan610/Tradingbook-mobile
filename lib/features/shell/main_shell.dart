import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Bottom navigation around the five tab branches. Each branch keeps its own
/// navigation stack and scroll position (StatefulShellRoute.indexedStack).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Discover'),
    (Icons.candlestick_chart_outlined, Icons.candlestick_chart_rounded, 'Markets'),
    (Icons.groups_outlined, Icons.groups_rounded, 'Communities'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  void _onTap(int index) {
    // Re-tapping the current tab pops it back to its root.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: dark ? AppColors.darkDivider : AppColors.divider),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _items[i].$1,
                      activeIcon: _items[i].$2,
                      label: _items[i].$3,
                      active: shell.currentIndex == i,
                      onTap: () => _onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = dark ? AppColors.primaryLight : AppColors.primary;
    final color = active ? activeColor : (dark ? AppColors.darkTextTertiary : AppColors.textTertiary);
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: active ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(active ? activeIcon : icon, size: 24, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
