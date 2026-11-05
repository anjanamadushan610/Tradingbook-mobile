import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/expandable_text.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/link_text.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/user_builder.dart';
import '../../data/models/comment.dart';
import '../../data/models/moderation.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/engagement_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/user_repository.dart';
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

  // ── Image attachment state ──────────────────────────────────────────────
  XFile? _pickedImage;
  double? _uploadProgress;

  // ── @mention state ──────────────────────────────────────────────────────
  /// The query string currently being typed after '@'. Null = overlay closed.
  String? _mentionQuery;
  List<UserProfile> _mentionResults = const [];
  bool _mentionLoading = false;
  Timer? _mentionDebounce;

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
    _mentionDebounce?.cancel();
    super.dispose();
  }

  // ── Image attachment helpers ────────────────────────────────────────────

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo Library'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        setState(() => _pickedImage = file);
      }
    } catch (e) {
      if (mounted) Toast.error(context, e);
    }
  }

  Future<String?> _uploadCommentImage(XFile xFile) async {
    setState(() => _uploadProgress = 0.0);
    try {
      final file = File(xFile.path);
      File fileToUpload = file;
      try {
        final targetPath = '${file.parent.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: 80,
        );
        if (compressed != null) {
          fileToUpload = File(compressed.path);
        }
      } catch (_) {
        // Fallback to original file if compression fails
      }

      final json = await sl<ApiClient>().uploadFile(
        '/api/media/comment-image/upload',
        file: fileToUpload,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      return (json['imageUrl'] ?? json['url']) as String?;
    } finally {
      if (mounted) setState(() => _uploadProgress = null);
    }
  }

  // ── @mention helpers ────────────────────────────────────────────────────

  /// Called on every keystroke in the comment field.
  /// Scans backwards from the cursor to detect an active `@query` token.
  void _onCommentChanged(String text) {
    final cursor = _input.selection.baseOffset;
    if (cursor < 0) {
      _clearMention();
      return;
    }

    // Everything from start of text to the cursor.
    final before  = text.substring(0, cursor.clamp(0, text.length));
    final atIndex = before.lastIndexOf('@');

    if (atIndex == -1) {
      _clearMention();
      return;
    }

    // The text between '@' and the cursor must contain no spaces/newlines,
    // otherwise the user has moved past the mention token.
    final afterAt = before.substring(atIndex + 1);
    if (afterAt.contains(' ') || afterAt.contains('\n')) {
      _clearMention();
      return;
    }

    final query = afterAt;

    // Nothing changed — avoid redundant searches.
    if (query == _mentionQuery) return;

    setState(() {
      _mentionQuery   = query;
      _mentionResults = const [];
    });

    // Show results only once the user has typed at least one character.
    if (query.isEmpty) return;

    _mentionDebounce?.cancel();
    _mentionDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || _mentionQuery != query) return;
      setState(() => _mentionLoading = true);
      try {
        final page = await sl<UserRepository>().search(query);
        // Guard: user may have typed more while the request was in flight.
        if (mounted && _mentionQuery == query) {
          setState(() => _mentionResults = page.items);
        }
      } catch (_) {
        if (mounted) setState(() => _mentionResults = const []);
      } finally {
        if (mounted) setState(() => _mentionLoading = false);
      }
    });
  }

  /// Closes the mention overlay and cancels any in-flight debounce.
  void _clearMention() {
    if (_mentionQuery == null) return;
    _mentionDebounce?.cancel();
    setState(() {
      _mentionQuery   = null;
      _mentionResults = const [];
      _mentionLoading = false;
    });
  }

  /// Replaces the active `@query` token with `@DisplayName ` and closes overlay.
  void _insertMention(UserProfile user) {
    final text   = _input.text;
    final cursor = _input.selection.baseOffset.clamp(0, text.length);
    final before  = text.substring(0, cursor);
    final atIndex = before.lastIndexOf('@');
    if (atIndex == -1) return;

    final after   = text.substring(cursor);
    final mention = '@${user.displayName} ';
    final newText = '${text.substring(0, atIndex)}$mention$after';

    _input.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: atIndex + mention.length),
    );

    _mentionDebounce?.cancel();
    setState(() {
      _mentionQuery   = null;
      _mentionResults = const [];
      _mentionLoading = false;
    });
  }

  // ── comment submit ───────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _input.text.trim();
    final image = _pickedImage;
    if ((text.isEmpty && image == null) || _sending) return;
    setState(() => _sending = true);
    try {
      String? imageUrl;
      if (image != null) {
        imageUrl = await _uploadCommentImage(image);
      }
      final parent = _replyTo;
      final c = await _engagement.addComment(
        postId: widget.postId,
        body: text,
        parentCommentId: parent == null ? null : (parent.parentCommentId ?? parent.id),
        imageUrl: imageUrl,
      );
      _comments.append(c);
      _input.clear();
      _clearMention();
      setState(() {
        _pickedImage = null;
        _uploadProgress = null;
        _replyTo = null;
      });
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

              // ── Reply-to banner ──────────────────────────────────────────
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

              // ── @mention suggestion overlay ──────────────────────────────
              // Visible whenever _mentionQuery is active (even while loading).
              if (_mentionQuery != null)
                _MentionOverlay(
                  loading: _mentionLoading,
                  results: _mentionResults,
                  onSelect: _insertMention,
                ),

              // ── Picked image thumbnail preview ───────────────────────────
              if (_pickedImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_pickedImage!.path),
                            height: 72,
                            width: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        GestureDetector(
                          onTap: _sending ? null : () => setState(() => _pickedImage = null),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Image upload progress bar ────────────────────────────────
              if (_uploadProgress != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(value: _uploadProgress),
                  ),
                ),

              // ── Input row ───────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppAvatar(url: me?.avatarUrl, name: me?.displayName, size: 34),
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Attach photo',
                    onPressed: _sending ? null : _pickImage,
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      size: 22,
                      color: _pickedImage != null ? AppColors.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: _onCommentChanged,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment… (type @ to mention)',
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
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

// ---------------------------------------------------------------------------
// _MentionOverlay — suggestion list shown above the keyboard while typing @.
// ---------------------------------------------------------------------------

class _MentionOverlay extends StatelessWidget {
  const _MentionOverlay({
    required this.loading,
    required this.results,
    required this.onSelect,
  });

  final bool loading;
  final List<UserProfile> results;
  final ValueChanged<UserProfile> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Nothing to show yet (query is empty or search hasn't returned).
    if (!loading && results.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: loading && results.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: results.length,
              itemBuilder: (context, i) {
                final user = results[i];
                return InkWell(
                  onTap: () => onSelect(user),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        AppAvatar(url: user.avatarUrl, name: user.displayName, size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: AppTextStyles.titleSmall.copyWith(color: cs.onSurface),
                              ),
                              if (user.bio.isNotEmpty)
                                Text(
                                  user.bio,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CommentsSliver — StatefulWidget so it can own per-comment expansion state.
// ---------------------------------------------------------------------------

class _CommentsSliver extends StatefulWidget {
  const _CommentsSliver({required this.cubit, required this.post, required this.onReply});

  final PagedCubit<Comment> cubit;
  final Post post;
  final ValueChanged<Comment> onReply;

  @override
  State<_CommentsSliver> createState() => _CommentsSliverState();
}

class _CommentsSliverState extends State<_CommentsSliver> {
  /// IDs of top-level comments whose reply threads are currently expanded.
  /// Empty by default → all threads start collapsed for a clean view.
  final Set<String> _expandedIds = {};

  void _toggleReplies(String commentId) {
    setState(() {
      if (_expandedIds.contains(commentId)) {
        _expandedIds.remove(commentId);
      } else {
        _expandedIds.add(commentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagedCubit<Comment>, PagedState<Comment>>(
      bloc: widget.cubit,
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        if (state.items.isEmpty) {
          if (state.status == PagedStatus.error) {
            return SliverToBoxAdapter(
              child: ErrorView(error: state.error, onRetry: widget.cubit.load, compact: true),
            );
          }
          if (state.status != PagedStatus.ready) {
            return const SliverToBoxAdapter(child: LoadingView());
          }
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                widget.post.status == PostStatus.live
                    ? 'No comments yet. Start the discussion.'
                    : 'Comments open once the post is live.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          );
        }

        final visible  = state.items.where((c) => !c.isDeleted).toList();
        final topLevel = visible.where((c) => !c.isReply).toList();
        final replies  = <String, List<Comment>>{};
        for (final c in visible.where((c) => c.isReply)) {
          replies.putIfAbsent(c.parentCommentId!, () => []).add(c);
        }
        // Orphan replies: parent not in the loaded page (e.g. paginated away).
        final orphans = visible.where(
          (c) => c.isReply && !topLevel.any((t) => t.id == c.parentCommentId),
        );

        final rows = <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Comments', style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface)),
          ),

          for (final c in topLevel) ...[
            // ── Parent comment tile (always visible) ────────────────────────
            _CommentTile(
              comment: c,
              cubit: widget.cubit,
              onReply: widget.onReply,
              postAuthorId: widget.post.authorId,
            ),

            // ── Reply toggle button (only when replies exist) ───────────────
            if (replies[c.id]?.isNotEmpty == true) ...[
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onPressed: () => _toggleReplies(c.id),
                  icon: Icon(
                    _expandedIds.contains(c.id)
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _expandedIds.contains(c.id)
                        ? 'Hide replies'
                        : () {
                            final count = replies[c.id]!.length;
                            return 'View $count ${count == 1 ? 'reply' : 'replies'}';
                          }(),
                    style: AppTextStyles.labelMedium,
                  ),
                ),
              ),

              // ── Reply tiles (only when thread is expanded) ─────────────────
              if (_expandedIds.contains(c.id))
                for (final r in replies[c.id]!)
                  _CommentTile(
                    comment: r,
                    cubit: widget.cubit,
                    onReply: widget.onReply,
                    postAuthorId: widget.post.authorId,
                    parentCommentAuthorId: c.authorId,
                    indent: true,
                  ),
            ],
          ],

          // Orphan replies: parent unknown / paginated away — always visible.
          for (final r in orphans)
            _CommentTile(
              comment: r,
              cubit: widget.cubit,
              onReply: widget.onReply,
              postAuthorId: widget.post.authorId,
              indent: true,
            ),

          if (state.hasMore)
            TextButton(
              onPressed: widget.cubit.loadMore,
              child: state.loadingMore
                  ? const Text('Loading…')
                  : const Text('Load more comments'),
            ),
        ];

        return SliverList.list(children: rows);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _CommentTile
// ---------------------------------------------------------------------------

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.cubit,
    required this.onReply,
    required this.postAuthorId,
    this.parentCommentAuthorId,
    this.indent = false,
  });

  final Comment comment;
  final PagedCubit<Comment> cubit;
  final ValueChanged<Comment> onReply;

  /// The authorId of the post this comment belongs to.
  /// Grants the post owner delete rights over any comment/reply on their post.
  final String postAuthorId;

  /// The authorId of the parent comment, only set when this tile is a reply.
  /// Grants the parent-comment owner delete rights over replies in their thread.
  /// Null for top-level comment tiles and orphaned reply tiles.
  final String? parentCommentAuthorId;

  final bool indent;

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final me   = context.read<SessionCubit>().user;
    final isMine        = me?.id == comment.authorId;
    final isPostOwner   = me?.id == postAuthorId;
    final isParentOwner = parentCommentAuthorId != null && me?.id == parentCommentAuthorId;
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
                          if (comment.body.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            ExpandableText(
                              text: comment.body,
                              maxLines: 3,
                              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (comment.imageUrl != null && comment.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: CachedNetworkImage(
                            imageUrl: comment.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 140,
                              color: dark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Text(
                          Fmt.relative(comment.createdAt),
                          style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                        ),
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
                          child: Text(
                            'Reply',
                            style: AppTextStyles.labelMedium.copyWith(color: cs.onSurfaceVariant),
                          ),
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
                  // Only the comment/reply author can edit their own text.
                  if (isMine)
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  // The author, the parent-comment owner (for replies),
                  // the post owner, or a platform moderator can delete.
                  if (isMine || isParentOwner || isPostOwner || (me?.isModerator ?? false))
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  // Anyone who didn't write it can report it.
                  if (!isMine)
                    const PopupMenuItem(value: 'report', child: Text('Report')),
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
          // Remove the comment itself AND any replies that belong to it.
          // Guard: only cascade-remove replies when deleting a top-level comment,
          // so that deleting one reply never accidentally removes its siblings.
          cubit.removeWhere((c) {
            if (c.id == comment.id) return true;
            if (!comment.isReply && c.parentCommentId == comment.id) return true;
            return false;
          });
        });
      case 'report':
        await showReportSheet(context, target: ReportTarget.comment, targetId: comment.id);
    }
  }
}
