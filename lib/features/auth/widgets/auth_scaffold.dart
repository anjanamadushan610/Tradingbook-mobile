import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Shared frame for the auth screens: the brand's wavy teal header with the
/// title, then the form on the surface below.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            _WavyHeader(title: title, subtitle: subtitle, showBack: showBack),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: AutofillGroup(child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavyHeader extends StatelessWidget {
  const _WavyHeader({required this.title, required this.subtitle, required this.showBack});

  final String title;
  final String subtitle;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    Widget bubble(double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        );
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        color: AppColors.primary,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned(top: 24, left: 24, child: bubble(70)),
              Positioned(top: 40, right: 110, child: bubble(64)),
              Positioned(top: 60, right: -150, child: bubble(340)),
              Positioned(bottom: 90, right: 40, child: bubble(48)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: showBack && context.canPop()
                          ? IconButton(
                              tooltip: 'Back',
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.15),
                              ),
                            )
                          : Row(children: [
                              Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Image.asset('assets/images/logo.png'),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'TradingBook',
                                style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                              ),
                            ]),
                    ),
                    const SizedBox(height: 32),
                    Text(title, style: AppTextStyles.displayMedium.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 76),
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

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height * 0.85)
    ..cubicTo(
      size.width * 0.35, size.height,
      size.width * 0.70, size.height * 0.72,
      size.width, size.height * 0.80,
    )
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// "Don't have an account? Sign up" style footer link.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({super.key, required this.prompt, required this.action, required this.onTap});

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant)),
        TextButton(
          onPressed: onTap,
          child: Text(action, style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }
}
