import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../domain/entities/post.dart';
import '../../widgets/app_avatar.dart';

/// A full feed post card matching the Nexus Trader home feed design.
/// Handles text posts, image posts, and trade setup cards.
class FeedPostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onAuthorTap;

  const FeedPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                _buildCaption(),
                if (post.mediaRefs.isNotEmpty) _buildMedia(),
                const SizedBox(height: 12),
                _buildActions(context),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAuthorTap,
            child: AppAvatar(
              imageUrl: post.authorAvatarUrl,
              name: post.authorName,
              size: 42,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onAuthorTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.authorName ?? 'Trader',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      _ProBadge(),
                    ],
                  ),
                  Text(
                    '@${(post.authorName ?? 'trader').toLowerCase().replaceAll(' ', '_')} • ${AppDateUtils.timeAgo(post.createdAt)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
        ],
      ),
    );
  }

  Widget _buildCaption() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        post.caption,
        style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
      ),
    );
  }

  Widget _buildMedia() {
    if (post.mediaRefs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: post.mediaRefs.first,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 180,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 180,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(Icons.image_not_supported_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        _ActionButton(
          icon: post.hasLiked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: AppNumberUtils.compact(post.likeCount),
          color: post.hasLiked ? AppColors.error : cs.onSurfaceVariant,
          onTap: onLike,
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: AppNumberUtils.compact(post.commentCount),
          onTap: onComment,
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.repeat_rounded,
          label: '12',
          onTap: () {},
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {},
          child: Icon(Icons.bookmark_border_rounded,
              size: 20, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// A specialized card for LONG/SHORT trade setups (Home feed)
class TradeSetupCard extends StatelessWidget {
  final String symbol;
  final bool isLong;
  final double entry;
  final double takeProfit;
  final double stopLoss;
  final String rrRatio;

  const TradeSetupCard({
    super.key,
    required this.symbol,
    required this.isLong,
    required this.entry,
    required this.takeProfit,
    required this.stopLoss,
    this.rrRatio = '1:2.3',
  });

  @override
  Widget build(BuildContext context) {
    final color = isLong ? AppColors.longBadge : AppColors.shortBadge;
    // bgColor not used here — bullish/bearish bg handled by header badge decoration
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLong
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLong ? 'LONG' : 'SHORT',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(symbol, style: AppTextStyles.headlineSmall),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'R:R $rrRatio',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Entry / TP / SL
          Row(
            children: [
              _TradeMetric(
                label: 'ENTRY',
                value: AppNumberUtils.formatPrice(entry),
                color: AppColors.textPrimary,
              ),
              _TradeMetric(
                label: 'TAKE PROFIT',
                value: AppNumberUtils.formatPrice(takeProfit),
                color: AppColors.bullish,
              ),
              _TradeMetric(
                label: 'STOP LOSS',
                value: AppNumberUtils.formatPrice(stopLoss),
                color: AppColors.bearish,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // SL — TP Progress Bar
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.bullish,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Positioned(
                left: 0,
                child: Container(
                  width: 40,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.bearish,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SL', style: AppTextStyles.labelSmall),
                    Text('TP', style: AppTextStyles.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Copy Button
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copy_outlined,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Copy Setup to Terminal',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TradeMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // color is intentionally passed (primary, bullish, bearish) — no change needed
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'PRO',
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontSize: 9,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Theme.of(context).colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? fallback),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                color: color ?? fallback,
              )),
        ],
      ),
    );
  }
}
