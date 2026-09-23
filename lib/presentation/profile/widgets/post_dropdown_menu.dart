import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class PostDropdownMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostDropdownMenu({
    super.key,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreHorizontal, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
      elevation: 4,
      onSelected: (value) {
        if (value == 'edit') {
          onEdit?.call();
        } else if (value == 'delete') {
          onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(LucideIcons.edit3, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Text('Edit Post', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
              const SizedBox(width: 12),
              Text('Delete Post', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}
