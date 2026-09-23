import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';

class ProfileStatsRow extends StatelessWidget {
  final int followers;
  final int following;

  const ProfileStatsRow({
    super.key,
    required this.followers,
    required this.following,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStat(followers, 'Followers'),
        const SizedBox(width: 24),
        _buildStat(following, 'Following'),
      ],
    );
  }

  Widget _buildStat(int count, String label) {
    return Row(
      children: [
        Text(
          '$count',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
