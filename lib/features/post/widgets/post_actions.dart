import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/models/post.dart';
import '../../../data/repositories/engagement_repository.dart';

/// Like · comment · share · save, bound to the shared per-post stats so
/// every copy of the post on screen stays in sync.
class PostActions extends StatelessWidget {
  const PostActions({super.key, required this.post, this.onComment});

  final Post post;
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context) {
    final repo = sl<EngagementRepository>();
    final seed = post.likeCount == null
        ? null
        : PostStats(
            likeCount: post.likeCount!,
            commentCount: post.commentCount,
            hasLiked: false,
            bookmarked: false,
          );
    return ValueListenableBuilder<PostStats?>(
      valueListenable: repo.statsFor(post.id, seed: seed),
      builder: (context, stats, _) {
        final s = stats ?? PostStats.empty;
        final cs = Theme.of(context).colorScheme;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final accent = dark ? AppColors.primaryLight : AppColors.primary;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              _Action(
                icon: s.hasLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                label: s.likeCount > 0 ? Fmt.count(s.likeCount) : 'Like',
                color: s.hasLiked ? accent : cs.onSurfaceVariant,
                semantics: s.hasLiked ? 'Unlike' : 'Like',
                onTap: () async {
                  try {
                    await repo.toggleLike(post.id);
                  } catch (e) {
                    if (context.mounted) Toast.error(context, e);
                  }
                },
              ),
              _Action(
                icon: Icons.mode_comment_outlined,
                label: (s.commentCount ?? 0) > 0 ? Fmt.count(s.commentCount!) : 'Comment',
                color: cs.onSurfaceVariant,
                semantics: 'Comments',
                onTap: onComment,
              ),
              _Action(
                icon: Icons.share_outlined,
                label: 'Share',
                color: cs.onSurfaceVariant,
                semantics: 'Share',
                onTap: () => SharePlus.instance.share(ShareParams(
                  text: post.caption.isEmpty
                      ? AppConfig.postUrl(post.id)
                      : '${_excerpt(post.caption)}\n\n${AppConfig.postUrl(post.id)}',
                  subject: 'TradingBook post',
                )),
              ),
              const Spacer(),
              IconButton(
                tooltip: s.bookmarked ? 'Remove from saved' : 'Save',
                onPressed: () async {
                  try {
                    final saved = await repo.toggleBookmark(post.id);
                    if (context.mounted) {
                      Toast.show(context, saved ? 'Saved to bookmarks' : 'Removed from bookmarks');
                    }
                  } catch (e) {
                    if (context.mounted) Toast.error(context, e);
                  }
                },
                icon: Icon(
                  s.bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: s.bookmarked ? accent : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _excerpt(String text) =>
      text.length <= 140 ? text : '${text.substring(0, 140).trimRight()}…';
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.semantics,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String semantics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.titleSmall.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
