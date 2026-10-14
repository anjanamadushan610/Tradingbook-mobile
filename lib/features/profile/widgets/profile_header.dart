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

// ─── constants ───────────────────────────────────────────────────────────────
const _kCoverHeight = 220.0;
const _kAvatarSize = 88.0;
const _kAvatarBorder = 4.0;
// How far the avatar overlaps below the cover.
const _kAvatarOverlap = (_kAvatarSize / 2) + _kAvatarBorder;

/// Cover, avatar, name, bio, follow counts — shared by MyProfilePage and
/// UserProfilePage. Pass [actions] to inject "Edit Profile" or "Follow".
class ProfileHeader extends StatefulWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.actions,
  });

  final UserProfile user;

  /// Action button placed at the bottom-right of the cover (Edit / Follow).
  final Widget actions;

  @override
  State<ProfileHeader> createState() => ProfileHeaderState();
}

class ProfileHeaderState extends State<ProfileHeader> {
  late Future<FollowCounts> _counts =
      sl<UserRepository>().followCounts(widget.user.id);

  void reloadCounts() => setState(() {
        _counts = sl<UserRepository>().followCounts(widget.user.id);
      });

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = dark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      color: cs.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover + Avatar stack ──────────────────────────────────────────
          SizedBox(
            height: _kCoverHeight + _kAvatarOverlap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover photo
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _kCoverHeight,
                  child: _CoverPhoto(url: u.coverUrl),
                ),

                // Dark gradient at the bottom of the cover so action button
                // icons remain legible on any photo.
                Positioned(
                  left: 0,
                  right: 0,
                  top: _kCoverHeight - 80,
                  height: 80,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: dark ? 0.55 : 0.35),
                        ],
                      ),
                    ),
                  ),
                ),

                // Action button (Edit / Follow) — sits on the gradient
                Positioned(
                  right: 16,
                  top: _kCoverHeight - 52,
                  child: widget.actions,
                ),

                // Avatar — overlaps bottom edge of the cover
                Positioned(
                  left: 16,
                  top: _kCoverHeight - _kAvatarOverlap,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: borderColor,
                    ),
                    padding: const EdgeInsets.all(_kAvatarBorder),
                    child: AppAvatar(
                      url: u.avatarUrl,
                      name: u.displayName,
                      size: _kAvatarSize,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Name, handle, badges ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display name row with badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        u.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (u.isModerator) ...[
                      const SizedBox(width: 6),
                      _Badge(
                        label: u.platformRole == 'admin' ? 'ADMIN' : 'MOD',
                        color: AppColors.warning,
                      ),
                    ],
                    if (u.isPrivate) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),

                // Bio
                if (u.bio.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    u.bio,
                    style:
                        AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                  ),
                ],

                const SizedBox(height: 14),

                // ── Follow stat row ───────────────────────────────────────
                FutureBuilder<FollowCounts>(
                  future: _counts,
                  builder: (context, snap) {
                    final c = snap.data;
                    return Row(
                      children: [
                        _StatPill(
                          value: c?.followers,
                          label: 'Followers',
                          onTap: () => context.push(Routes.followers(u.id)),
                        ),
                        const SizedBox(width: 24),
                        _StatPill(
                          value: c?.following,
                          label: 'Following',
                          onTap: () => context.push(Routes.following(u.id)),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ── Meta row (join date, languages) ──────────────────────
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _MetaChip(
                      icon: Icons.calendar_month_outlined,
                      text: 'Joined ${Fmt.date(u.createdAt)}',
                    ),
                    if (u.languages.isNotEmpty)
                      _MetaChip(
                        icon: Icons.translate_rounded,
                        text: u.languages.join(', ').toUpperCase(),
                      ),
                  ],
                ),

                // ── Interest chips ────────────────────────────────────────
                if (u.interests.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final i in u.interests)
                        _InterestChip(label: i, dark: dark),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover photo — gradient fallback when no coverUrl
// ─────────────────────────────────────────────────────────────────────────────

class _CoverPhoto extends StatelessWidget {
  const _CoverPhoto({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return NetImage(url: url!, fit: BoxFit.cover);
    }
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact badge pill (MOD / ADMIN)
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium stat pill — tappable follower / following count
// ─────────────────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final int? value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loading = value == null;
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: loading
                  ? Container(
                      key: const ValueKey('loading'),
                      width: 40,
                      height: 18,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : Text(
                      key: const ValueKey('value'),
                      Fmt.count(value!),
                      style: AppTextStyles.headlineSmall
                          .copyWith(color: cs.onSurface),
                    ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: AppTextStyles.caption
                  .copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta chip (join date, language)
// ─────────────────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style:
              AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interest chip
// ─────────────────────────────────────────────────────────────────────────────

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.label, required this.dark});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.5),
        border: Border.all(
          color: (dark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: dark ? AppColors.primaryLight : AppColors.primary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
