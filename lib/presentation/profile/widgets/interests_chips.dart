import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';

class InterestsChips extends StatelessWidget {
  final List<String> interests;
  final VoidCallback? onEdit;

  const InterestsChips({
    super.key,
    required this.interests,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (interests.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'INTERESTS',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            if (onEdit != null)
              GestureDetector(
                onTap: onEdit,
                child: const Icon(
                  LucideIcons.edit2,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interests.map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                interest,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
