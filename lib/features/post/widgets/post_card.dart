import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/user_builder.dart';
import '../../../data/models/post.dart';
import '../../../data/repositories/engagement_repository.dart';
import '../../auth/session_cubit.dart';
import 'post_actions.dart';
import 'post_caption.dart';
import 'post_media.dart';
import 'post_menu.dart';

/// A post in any list. Author and engagement are hydrated lazily (batched)
/// so a page of cards costs three requests, not three per card.
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onDeleted,
    this.onChanged,
    this.contextType = 'feed',
    this.showStatus = false,
    this.tapToOpen = true,
  });

  final Post post;
  final VoidCallback? onDeleted;
  final ValueChanged<Post>? onChanged;

  /// Telemetry context: feed | group | page | profile.
  final String contextType;

  /// Show the moderation status chip (own posts lists).
  final bool showStatus;

  final bool tapToOpen;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Post _post = widget.post;
  DateTime? _visibleSince;

  @override
  void initState() {
    super.initState();
    _visibleSince = DateTime.now();
    if (_post.status == PostStatus.live) {
      sl<EngagementRepository>().track(
        eventType: 'view',
        postId: _post.id,
        value: 1,
        contextType: widget.contextType,
      );
    }
  }

  @override
  void didUpdateWidget(PostCard old) {
    super.didUpdateWidget(old);
    if (old.post != widget.post) _post = widget.post;
  }

  @override
  void dispose() {
    final since = _visibleSince;
    if (since != null && _post.status == PostStatus.live) {
      final seconds = DateTime.now().difference(since).inMilliseconds / 1000;
      if (seconds >= 1.5) {
        sl<EngagementRepository>().track(
          eventType: 'dwell',
          postId: _post.id,
          value: double.parse(seconds.toStringAsFixed(1)),
          contextType: widget.contextType,
        );
      }
    }
    super.dispose();
  }

  void _changed(Post p) {
    setState(() => _post = p);
    widget.onChanged?.call(p);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final me = context.select((SessionCubit s) => s.state.userOrNull);
    final isMine = me?.id == _post.authorId;
    final open = widget.tapToOpen ? () => context.push(Routes.post(_post.id)) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.symmetric(
          horizontal: BorderSide(color: dark ? AppColors.darkCardBorder : AppColors.cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
            child: Row(
              children: [
                Expanded(child: _AuthorHeader(post: _post)),
                PostMenuButton(
                  post: _post,
                  isMine: isMine,
                  isModerator: me?.isModerator ?? false,
                  onChanged: _changed,
                  onDeleted: widget.onDeleted,
                ),
              ],
            ),
          ),
          if (widget.showStatus && _post.status != PostStatus.live)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: PostStatusChip(post: _post),
            ),
          if (_post.caption.isNotEmpty)
            InkWell(
              onTap: open,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: PostCaption(text: _post.caption),
              ),
            ),
          PostMedia(post: _post),
          if (_post.status == PostStatus.live)
            PostActions(post: _post, onComment: () => context.push(Routes.post(_post.id, focusComment: true))),
          if (_post.status != PostStatus.live) const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return UserBuilder(
      userId: post.authorId,
      builder: (context, user) {
        final name = user?.displayName ?? post.authorName ?? 'Trader';
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push(Routes.user(post.authorId)),
          child: Row(
            children: [
              AppAvatar(url: user?.avatarUrl, name: name, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Text(
                          Fmt.relative(post.createdAt),
                          style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          switch (post.visibility) {
                            PostVisibility.public => Icons.public_rounded,
                            PostVisibility.followersOnly => Icons.group_outlined,
                            PostVisibility.private => Icons.lock_outline_rounded,
                          },
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        if (post.groupId != null || post.pageId != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            post.groupId != null ? Icons.groups_2_outlined : Icons.flag_outlined,
                            size: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PostStatusChip extends StatelessWidget {
  const PostStatusChip({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (post.status) {
      PostStatus.rejected || PostStatus.failed => (AppColors.error, Icons.block_rounded),
      PostStatus.draft => (AppColors.textSecondary, Icons.edit_note_rounded),
      _ => (AppColors.warning, Icons.hourglass_top_rounded),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(post.status.label, style: AppTextStyles.labelMedium.copyWith(color: color)),
            ],
          ),
        ),
        if (post.status == PostStatus.rejected && post.rejectedReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Reason: ${post.rejectedReason}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
