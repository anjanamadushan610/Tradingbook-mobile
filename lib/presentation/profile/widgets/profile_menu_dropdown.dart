import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';

class ProfileMenuDropdown extends StatelessWidget {
  const ProfileMenuDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.menu, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
      elevation: 4,
      onSelected: (value) {
        if (value == 'edit_profile') {
          context.push(AppRoutes.editProfile);
        } else if (value == 'edit_privacy') {
          // Future feature
        } else if (value == 'settings') {
          context.push(AppRoutes.settings);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit_profile',
          child: Row(
            children: [
              const Icon(LucideIcons.user, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Text('Edit Profile', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit_privacy',
          child: Row(
            children: [
              const Icon(LucideIcons.shield, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Text('Edit Privacy', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(LucideIcons.settings, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Text('Settings', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
