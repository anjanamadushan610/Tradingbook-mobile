import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/theme_cubit.dart';
import 'wavy_header_clipper.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBackPressed;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WavyHeaderClipper(),
      child: Container(
        width: double.infinity,
        color: const Color(0xFF00647C),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Top-Left: Medium circle
              Positioned(
                top: 30,
                left: 30,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Mid-Left (Below top-left): Small circle
              Positioned(
                top: 130,
                left: 30,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Top-Right-Center: Medium circle
              Positioned(
                top: 40,
                right: 120,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Far-Right edge: HUGE circle, partially cut off
              Positioned(
                top: 60,
                right: -150,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Inside the Far-Right huge circle (lower part): Small circle
              Positioned(
                bottom: 100,
                right: 40,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Bottom-Center: Medium circle, sitting right above the wave curve
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ),

              // Foreground Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Header Row (Back button / Theme Toggle)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (onBackPressed != null) {
                              onBackPressed!();
                            } else if (context.canPop()) {
                              context.pop();
                            }
                          },
                          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 24),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final themeCubit = context.read<ThemeCubit>();
                            if (themeCubit.state == AppThemeMode.light) {
                              themeCubit.setTheme(AppThemeMode.dark);
                            } else {
                              themeCubit.setTheme(AppThemeMode.light);
                            }
                          },
                          icon: const Icon(LucideIcons.sun, color: Colors.white, size: 24),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // === Headline ===
                    Text(
                      title,
                      style: AppTextStyles.displayMedium.copyWith(color: Colors.white),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 80), // Extra space for the wave
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
