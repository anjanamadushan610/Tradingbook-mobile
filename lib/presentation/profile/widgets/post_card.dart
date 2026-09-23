import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trading_book/domain/repositories/feed_repository.dart';
import 'package:trading_book/presentation/profile/models/profile_models.dart';
import 'package:trading_book/presentation/profile/widgets/comment_bottom_sheet.dart';

class PostCard extends StatefulWidget {
  final ValueNotifier<PostModel> postNotifier;
  final VoidCallback? onDelete;
  final Function(String)? onLikeToggled;
  final Function(String)? onBookmarkToggled;

  const PostCard({
    super.key,
    required this.postNotifier,
    this.onDelete,
    this.onLikeToggled,
    this.onBookmarkToggled,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final GlobalKey _menuKey = GlobalKey();

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _toggleLike() async {
    widget.onLikeToggled?.call(widget.postNotifier.value.id);
  }

  Future<void> _handleShare() async {
    final url = 'https://tradingbooknet.com/post/${widget.postNotifier.value.id}';
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Post link copied to clipboard')),
      );
  }

  Future<void> _toggleBookmark() async {
    widget.onBookmarkToggled?.call(widget.postNotifier.value.id);
  }

  void _handleComment() {
    if (widget.postNotifier.value.status != 'live') {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Cannot comment on draft/unapproved posts')),
        );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentBottomSheet(postId: widget.postNotifier.value.id),
    );
  }

  // ── 3-dots menu ─────────────────────────────────────────────────────────

  void _showPostMenu() async {
    final RenderBox button =
        _menuKey.currentContext!.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final theme = Theme.of(context);
    final String? value = await showMenu<String>(
      context: context,
      position: position,
      color: theme.colorScheme.surfaceContainer,
      items: [
        PopupMenuItem(
          value: 'edit_post',
          child: Row(children: [
            Icon(Icons.edit_outlined,
                size: 20, color: theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Text('Edit Post',
                style: TextStyle(color: theme.colorScheme.onSurface)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete_post',
          child: Row(children: [
            Icon(Icons.delete_outline,
                size: 20, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Text('Delete Post',
                style: TextStyle(color: theme.colorScheme.error)),
          ]),
        ),
      ],
    );

    if (value != null && mounted) {
      await _handleMenuAction(value);
    }
  }

  Future<void> _handleMenuAction(String value) async {
    switch (value) {
      case 'delete_post':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Post?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          try {
            await context.read<PostsRepository>().deletePost(widget.postNotifier.value.id);
            if (mounted) {
              Navigator.pop(context); // pop loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post deleted')),
              );
              widget.onDelete?.call();
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context); // pop loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete: $e')),
              );
            }
          }
        }

      case 'edit_post':
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Navigating to Edit Post...')),
          );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<PostModel>(
      valueListenable: widget.postNotifier,
      builder: (context, post, _) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.secondaryContainer,
                        image: post.authorAvatarUrl != null &&
                                post.authorAvatarUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(post.authorAvatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: post.authorAvatarUrl == null ||
                              post.authorAvatarUrl!.isEmpty
                          ? Icon(Icons.person,
                              size: 16,
                              color: theme.colorScheme.onSecondaryContainer)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.authorName,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  // Derive a clean handle from authorName.
                                  // Falls back gracefully if authorName is empty.
                                  post.authorName.isNotEmpty
                                      ? '@${post.authorName.replaceAll(' ', '').toLowerCase()}'
                                      : '',
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            post.date,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          initialValue: 'Public',
                          padding: EdgeInsets.zero,
                          tooltip: 'Post Visibility',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.public,
                                  size: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                              const SizedBox(width: 4),
                              Text(
                                'Public',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.keyboard_arrow_down,
                                  size: 14, color: theme.colorScheme.onSurfaceVariant),
                            ],
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'Public',
                              child: Row(children: [
                                Icon(Icons.public, size: 18),
                                SizedBox(width: 8),
                                Text('Public'),
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'Followers',
                              child: Row(children: [
                                Icon(Icons.people_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Followers'),
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'Private',
                              child: Row(children: [
                                Icon(Icons.lock_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Private'),
                              ]),
                            ),
                          ],
                          onSelected: (val) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Visibility changed to $val')),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          key: _menuKey,
                          child: IconButton(
                            icon: Icon(Icons.more_vert,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _showPostMenu,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Content ─────────────────────────────────────────────────
                const SizedBox(height: 14),
                Text(
                  post.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),

                // ── Media (conditional) ─────────────────────────────────────
                if (post.mediaUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._buildMediaGrid(post.mediaUrls, theme),
                ],

                // ── Action bar ───────────────────────────────────────────────
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAction(
                      icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                      iconColor: post.isLiked ? Colors.red : theme.colorScheme.onSurfaceVariant,
                      count: post.likes,
                      onTap: _toggleLike,
                      theme: theme,
                    ),
                    const SizedBox(width: 4),
                    _buildAction(
                      icon: Icons.chat_bubble_outline,
                      count: post.comments,
                      onTap: _handleComment,
                      theme: theme,
                    ),
                    const SizedBox(width: 4),
                    _buildAction(
                      icon: Icons.share_outlined,
                      count: post.shares,
                      onTap: _handleShare,
                      theme: theme,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                          post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 20,
                          color: post.isSaved
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _toggleBookmark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<Widget> _buildMediaGrid(List<String> urls, ThemeData theme) {
    return [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            urls.first,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                size: 40,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildAction({
    required IconData icon,
    Color? iconColor,
    required int count,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        debugPrint('Action tapped: $icon');
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
