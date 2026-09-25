import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/net_image.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';

/// Cover, avatar, name, bio, interests and follower counts — shared by the
/// own-profile tab and other traders' profiles.
class ProfileHeader extends StatefulWidget {
  const ProfileHeader({super.key, required this.user, required this.actions});

  final UserProfile user;
  final Widget actions;

  @override
  State<ProfileHeader> createState() => ProfileHeaderState();
}

class ProfileHeaderState extends State<ProfileHeader> {
  late Future<FollowCounts> _counts = sl<UserRepository>().followCounts(widget.user.id);

  void reloadCounts() => setState(() {
        _counts = sl<UserRepository>().followCounts(widget.user.id);
      });

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: cs.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  bottom: 46,
                  child: u.coverUrl == null
                      ? Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient))
                      : NetImage(url: u.coverUrl!, fit: BoxFit.cover),
                ),
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: AppAvatar(
                    url: u.avatarUrl,
                    name: u.displayName,
                    size: 92,
                    borderColor: dark ? AppColors.darkSurface : Colors.white,
                  ),
                ),
                Positioned(right: 12, bottom: 4, child: widget.actions),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(u.displayName, style: AppTextStyles.headlineLarge.copyWith(color: cs.onSurface)),
                    ),
                    if (u.isPrivate) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.lock_outline_rounded, size: 18, color: cs.onSurfaceVariant),
                    ],
                  ],
                ),
                if (u.bio.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(u.bio, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                ],
                const SizedBox(height: 10),
                FutureBuilder<FollowCounts>(
                  future: _counts,
                  builder: (context, snap) {
                    final c = snap.data;
                    return Row(
                      children: [
                        _Count(
                          value: c?.followers,
                          label: 'Followers',
                          onTap: () => context.push(Routes.followers(u.id)),
                        ),
                        const SizedBox(width: 20),
                        _Count(
                          value: c?.following,
                          label: 'Following',
                          onTap: () => context.push(Routes.following(u.id)),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _Meta(icon: Icons.calendar_month_outlined, text: 'Joined ${Fmt.date(u.createdAt)}'),
                    if (u.languages.isNotEmpty)
                      _Meta(icon: Icons.translate_rounded, text: u.languages.join(', ').toUpperCase()),
                  ],
                ),
                if (u.interests.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final i in u.interests)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: dark ? 0.25 : 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(i,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: dark ? AppColors.primaryLight : AppColors.primary,
                                letterSpacing: 0,
                              )),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label, required this.onTap});

  final int? value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text.rich(TextSpan(children: [
          TextSpan(
            text: value == null ? '–' : Fmt.count(value!),
            style: AppTextStyles.titleLarge.copyWith(color: cs.onSurface),
          ),
          TextSpan(
            text: ' $label',
            style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
          ),
        ])),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}
