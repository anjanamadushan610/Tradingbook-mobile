import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TradingBookAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  const TradingBookAppBar({
    super.key,
    this.actions,
    this.showBackButton = false,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0, // Prevents Material 3 tinting on scroll
      titleSpacing: showBackButton ? 0 : 16,
      leading: showBackButton 
          ? IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
              onPressed: onBackTap ?? () => context.pop(),
            )
          : null,
      title: showBackButton 
          ? null 
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 6),
                Text(
                  'TradingBook',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
