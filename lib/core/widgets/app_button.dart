import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

enum AppButtonStyle { primary, outlined, subtle, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.style = AppButtonStyle.primary,
    this.icon,
    this.expand = true,
    this.height = 52,
    this.compact = false,
  });

  /// Small pill button (Follow / Join) used inline in rows and headers.
  const AppButton.small({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.style = AppButtonStyle.primary,
    this.icon,
  })  : expand = false,
        height = 34,
        compact = true;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonStyle style;
  final IconData? icon;
  final bool expand;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color fg, BorderSide? side) = switch (style) {
      AppButtonStyle.primary => (AppColors.primary, Colors.white, null),
      AppButtonStyle.outlined => (
          Colors.transparent,
          dark ? AppColors.primaryLight : AppColors.primary,
          BorderSide(color: dark ? AppColors.primaryLight : AppColors.primary, width: 1.3),
        ),
      AppButtonStyle.subtle => (
          dark ? AppColors.darkSurfaceVariant : AppColors.primarySurface,
          dark ? AppColors.darkTextPrimary : AppColors.primary,
          null,
        ),
      AppButtonStyle.danger => (AppColors.error, Colors.white, null),
    };
    final disabled = onPressed == null || isLoading;

    final child = isLoading
        ? SizedBox(
            width: compact ? 16 : 22,
            height: compact ? 16 : 22,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: compact ? 16 : 18, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: (compact ? AppTextStyles.titleSmall : AppTextStyles.labelLarge)
                      .copyWith(color: fg),
                ),
              ),
            ],
          );

    final button = TextButton(
      onPressed: disabled ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: disabled && style != AppButtonStyle.outlined
            ? bg.withValues(alpha: isLoading ? 1 : 0.45)
            : bg,
        foregroundColor: fg,
        disabledForegroundColor: fg.withValues(alpha: 0.7),
        minimumSize: Size(compact ? 72 : 0, height),
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 20 : 12),
          side: side ?? BorderSide.none,
        ),
        overlayColor: cs.onPrimary.withValues(alpha: 0.08),
      ),
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
