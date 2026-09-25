import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/api_exception.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/user_builder.dart';
import '../../data/models/comment.dart';
import '../../data/models/moderation.dart';
import '../../data/models/post.dart';
import '../../data/repositories/engagement_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../auth/session_cubit.dart';
import '../report/report_sheet.dart';
import 'widgets/post_card.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId, this.focusComment = false});

  final String postId;
  final bool focusComment;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _engagement = sl<EngagementRepository>();
  late final _comments = PagedCubit<Comment>(
    (cursor) => _engagement.comments(widget.postId, cursor: cursor),
    keyOf: (c) => c.id,
  );
  late Future<Post> _post = sl<PostRepository>().byId(widget.postId);
  final _input = TextEditingController();
  final _focus = FocusNode();
  Comment? _replyTo;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _comments.load();
    if (widget.focusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    }
  }

  @override
  void dispose() {
    _comments.close();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final parent = _replyTo;
      final c = await _engagement.addComment(
        postId: widget.postId,
        body: text,
        parentCommentId: parent == null ? null : (parent.parentCommentId ?? parent.id),
      );
      _comments.append(c);
      _input.clear();
      setState(() => _replyTo = null);
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _reply(Comment c) {
    setState(() => _replyTo = c);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: FutureBuilder<Post>(
        future: _post,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) {
            final e = snap.error;
            if (e is ApiException && e.isNotFound) {
              return const EmptyView(
                icon: Icons.lock_outline_rounded,
                title: 'Post unavailable',
                message: 'It may have been deleted, or it\'s only visible to certain people.',
              );
            }
            return ErrorView(
              error: e,
              onRetry: () => setState(() => _post = sl<PostRepository>().byId(widget.postId)),
            );
          }
          final post = snap.data!;
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _engagement.refreshStats(post.id);
                    await _comments.refresh();
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: PostCard(
                          post: post,
                          tapToOpen: false,
                          showStatus: true,
                          onDeleted: () => context.pop(),
                        ),
                      ),
                      _CommentsSliver(cubit: _comments, post: post, onReply: _reply),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                    ],
                  ),
                ),
              ),
              if (post.status == PostStatus.live) _composer(),
            ],
          );
        },
      ),
    );
  }

  Widget _composer() {
    final cs = Theme.of(context).colorScheme;
    final me = context.read<SessionCubit>().user;
    return Material(
      color: cs.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_replyTo != null)
                Row(
                  children: [
                    Icon(Icons.reply_rounded, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: UserBuilder(
                        userId: _replyTo!.authorId,
                        builder: (_, u) => Text(
                          'Replying to ${u?.displayName ?? 'comment'}',
                          style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Cancel reply',
                      onPressed: () => setState(() => _replyTo = null),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppAvatar(url: me?.avatarUrl, name: me?.displayName, size: 34),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment…',
                        counterText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsSliver extends StatelessWidget {
  const _CommentsSliver({required this.cubit, required this.post, required this.onReply});

  final PagedCubit<Comment> cubit;
  final Post post;
  final ValueChanged<Comment> onReply;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagedCubit<Comment>, PagedState<Comment>>(
      bloc: cubit,
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        if (state.items.isEmpty) {
          if (state.status == PagedStatus.error) {
            return SliverToBoxAdapter(child: ErrorView(error: state.error, onRetry: cubit.load, compact: true));
          }
          if (state.status != PagedStatus.ready) {
            return const SliverToBoxAdapter(child: LoadingView());
          }
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                post.status == PostStatus.live ? 'No comments yet. Start the discussion.' : 'Comments open once the post is live.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          );
        }
        final visible = state.items.where((c) => !c.isDeleted).toList();
        final topLevel = visible.where((c) => !c.isReply).toList();
        final replies = <String, List<Comment>>{};
        for (final c in visible.where((c) => c.isReply)) {
          replies.putIfAbsent(c.parentCommentId!, () => []).add(c);
        }
        // Replies whose parent isn't loaded (or was deleted) still show.
        final orphans = visible.where((c) => c.isReply && !topLevel.any((t) => t.id == c.parentCommentId));
        final rows = <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Comments', style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface)),
          ),
          for (final c in topLevel) ...[
            _CommentTile(comment: c, cubit: cubit, onReply: onReply),
            for (final r in replies[c.id] ?? const <Comment>[])
              _CommentTile(comment: r, cubit: cubit, onReply: onReply, indent: true),
          ],
          for (final r in orphans) _CommentTile(comment: r, cubit: cubit, onReply: onReply, indent: true),
          if (state.hasMore)
            TextButton(
              onPressed: cubit.loadMore,
              child: state.loadingMore ? const Text('Loading…') : const Text('Load more comments'),
            ),
        ];
        return SliverList.list(children: rows);
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.cubit, required this.onReply, this.indent = false});

  final Comment comment;
  final PagedCubit<Comment> cubit;
  final ValueChanged<Comment> onReply;
  final bool indent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final me = context.read<SessionCubit>().user;
    final isMine = me?.id == comment.authorId;
    final repo = sl<EngagementRepository>();

    return UserBuilder(
      userId: comment.authorId,
      builder: (context, user) {
        final name = user?.displayName ?? 'Trader';
        return Padding(
          padding: EdgeInsets.fromLTRB(indent ? 56 : 16, 10, 8, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.push(Routes.user(comment.authorId)),
                child: AppAvatar(url: user?.avatarUrl, name: name, size: indent ? 28 : 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      decoration: BoxDecoration(
                        color: dark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.titleSmall.copyWith(color: cs.onSurface)),
                          const SizedBox(height: 2),
                          Text(comment.body, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(Fmt.relative(comment.createdAt), style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
                        TextButton(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          onPressed: () async {
                            try {
                              final updated = await repo.toggleCommentLike(comment);
                              cubit.replaceWhere((c) => c.id == comment.id, (_) => updated);
                            } catch (e) {
                              if (context.mounted) Toast.error(context, e);
                            }
                          },
                          child: Text(
                            comment.likeCount > 0 ? 'Like · ${comment.likeCount}' : 'Like',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: comment.hasLiked ? AppColors.primary : cs.onSurfaceVariant,
                              fontWeight: comment.hasLiked ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          onPressed: () => onReply(comment),
                          child: Text('Reply', style: AppTextStyles.labelMedium.copyWith(color: cs.onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Comment options',
                icon: Icon(Icons.more_vert_rounded, size: 18, color: cs.onSurfaceVariant),
                onSelected: (action) => _onAction(context, action),
                itemBuilder: (_) => [
                  if (isMine) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (isMine || (me?.isModerator ?? false))
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  if (!isMine) const PopupMenuItem(value: 'report', child: Text('Report')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onAction(BuildContext context, String action) async {
    final repo = sl<EngagementRepository>();
    switch (action) {
      case 'edit':
        final body = await promptDialog(
          context,
          title: 'Edit comment',
          initial: comment.body,
          maxLines: 5,
          maxLength: 2000,
        );
        if (body == null || body == comment.body || !context.mounted) return;
        await guard(context, () async {
          final updated = await repo.editComment(comment, body);
          cubit.replaceWhere((c) => c.id == comment.id, (_) => updated);
        });
      case 'delete':
        final ok = await confirmDialog(
          context,
          title: 'Delete comment?',
          message: 'This can\'t be undone.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        await guard(context, () async {
          await repo.deleteComment(comment);
          cubit.removeWhere((c) => c.id == comment.id);
        });
      case 'report':
        await showReportSheet(context, target: ReportTarget.comment, targetId: comment.id);
    }
  }
}
