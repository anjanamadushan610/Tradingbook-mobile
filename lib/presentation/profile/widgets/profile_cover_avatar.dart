import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../widgets/app_avatar.dart';

class ProfileCoverAvatar extends StatelessWidget {
  final String? avatarUrl;

  const ProfileCoverAvatar({
    super.key,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220, // 160 cover + 60 overflow
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover Image / Gradient
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Profile Avatar
          Positioned(
            left: 20,
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: AppAvatar(
                    imageUrl: avatarUrl,
                    size: 100,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
