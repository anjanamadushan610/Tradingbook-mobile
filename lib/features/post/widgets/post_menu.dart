import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/models/moderation.dart';
import '../../../data/models/post.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../report/report_sheet.dart';

/// The ⋯ menu on a post. Authors edit/re-audience/delete; everyone else can
/// follow, report or block; moderators can remove.
class PostMenuButton extends StatelessWidget {
  const PostMenuButton({
    super.key,
    required this.post,
    required this.isMine,
    required this.isModerator,
    required this.onChanged,
    this.onDeleted,
  });

  final Post post;
  final bool isMine;
  final bool isModerator;
  final ValueChanged<Post> onChanged;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'More',
      icon: const Icon(Icons.more_horiz_rounded),
      onPressed: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _MenuSheet(post: post, isMine: isMine, isModerator: isModerator),
    );
    if (action == null || !context.mounted) return;
    final posts = sl<PostRepository>();
    switch (action) {
      case 'edit':
        final caption = await promptDialog(
          context,
          title: 'Edit caption',
          initial: post.caption,
          maxLines: 8,
          maxLength: 5000,
        );
        if (caption == null || caption == post.caption || !context.mounted) return;
        await guard(context, () async {
          final updated = await posts.updateCaption(post.id, caption);
          onChanged(post.copyWith(caption: updated.caption.isEmpty ? caption : updated.caption));
        }, success: 'Post updated');
      case 'visibility':
        final v = await _pickVisibility(context, post.visibility);
        if (v == null || v == post.visibility || !context.mounted) return;
        await guard(context, () async {
          final applied = await posts.updateVisibility(post.id, v);
          onChanged(post.copyWith(visibility: applied));
        }, success: 'Audience set to ${v.label}');
      case 'delete':
      case 'remove':
        final ok = await confirmDialog(
          context,
          title: action == 'delete' ? 'Delete post?' : 'Remove this post?',
          message: 'This permanently deletes the post and its comments.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        final done = await guard(context, () => posts.delete(post.id), success: 'Post deleted');
        if (done) onDeleted?.call();
      case 'copy':
        await Clipboard.setData(ClipboardData(text: AppConfig.postUrl(post.id)));
        if (context.mounted) Toast.show(context, 'Link copied');
      case 'follow':
        await guard(context, () => sl<UserRepository>().follow(post.authorId), success: 'Following');
      case 'unfollow':
        await guard(context, () => sl<UserRepository>().unfollow(post.authorId), success: 'Unfollowed');
      case 'report':
        await showReportSheet(context, target: ReportTarget.post, targetId: post.id);
      case 'block':
        final ok = await confirmDialog(
          context,
          title: 'Block this trader?',
          message: 'You won\'t see each other\'s posts, and any follows between you are removed. '
              'You can unblock from Settings.',
          confirmLabel: 'Block',
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        final done = await guard(context, () => sl<UserRepository>().block(post.authorId), success: 'Blocked');
        if (done) onDeleted?.call();
    }
  }

  Future<PostVisibility?> _pickVisibility(BuildContext context, PostVisibility current) {
    return showModalBottomSheet<PostVisibility>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in PostVisibility.values)
              ListTile(
                leading: Icon(visibilityIcon(v)),
                title: Text(v.label),
                subtitle: Text(visibilityHint(v)),
                trailing: v == current ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(ctx, v),
              ),
          ],
        ),
      ),
    );
  }
}

IconData visibilityIcon(PostVisibility v) => switch (v) {
      PostVisibility.public => Icons.public_rounded,
      PostVisibility.followersOnly => Icons.group_outlined,
      PostVisibility.private => Icons.lock_outline_rounded,
    };

String visibilityHint(PostVisibility v) => switch (v) {
      PostVisibility.public => 'Anyone on TradingBook',
      PostVisibility.followersOnly => 'Only people who follow you',
      PostVisibility.private => 'Only you',
    };

class _MenuSheet extends StatefulWidget {
  const _MenuSheet({required this.post, required this.isMine, required this.isModerator});

  final Post post;
  final bool isMine;
  final bool isModerator;

  @override
  State<_MenuSheet> createState() => _MenuSheetState();
}

class _MenuSheetState extends State<_MenuSheet> {
  bool? _following;

  @override
  void initState() {
    super.initState();
    if (!widget.isMine) {
      sl<UserRepository>().isFollowing(widget.post.authorId).then((f) {
        if (mounted) setState(() => _following = f);
      }).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    Widget item(String id, IconData icon, String label, {bool danger = false}) => ListTile(
          leading: Icon(icon, color: danger ? AppColors.error : null),
          title: Text(label, style: danger ? const TextStyle(color: AppColors.error) : null),
          onTap: () => Navigator.pop(context, id),
        );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isMine) ...[
            item('edit', Icons.edit_outlined, 'Edit caption'),
            if (!post.isCommunityPost)
              item('visibility', visibilityIcon(post.visibility), 'Change audience (${post.visibility.label})'),
          ] else ...[
            if (_following != null)
              _following!
                  ? item('unfollow', Icons.person_remove_outlined, 'Unfollow author')
                  : item('follow', Icons.person_add_alt_1_outlined, 'Follow author'),
          ],
          item('copy', Icons.link_rounded, 'Copy link'),
          if (!widget.isMine) ...[
            item('report', Icons.flag_outlined, 'Report post', danger: true),
            item('block', Icons.block_rounded, 'Block author', danger: true),
          ],
          if (widget.isMine) item('delete', Icons.delete_outline_rounded, 'Delete post', danger: true),
          if (!widget.isMine && widget.isModerator)
            item('remove', Icons.gavel_rounded, 'Remove post (moderator)', danger: true),
        ],
      ),
    );
  }
}
