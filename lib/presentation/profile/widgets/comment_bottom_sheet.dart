import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trading_book/domain/entities/post.dart';
import 'package:trading_book/domain/repositories/feed_repository.dart';

class CommentBottomSheet extends StatefulWidget {
  final String postId;

  const CommentBottomSheet({super.key, required this.postId});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isLoading = true;
  bool _isPosting = false;
  String? _error;
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final res = await context
          .read<PostsRepository>()
          .getComments(postId: widget.postId);
      if (mounted) {
        setState(() {
          _comments = res.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load comments';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _postComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      final newComment = await context.read<PostsRepository>().postComment(
            postId: widget.postId,
            body: text,
          );
      if (mounted) {
        setState(() {
          // Add the new comment at the top for immediate feedback
          _comments.insert(0, newComment);
          _isPosting = false;
        });
        _controller.clear();
        _focusNode.unfocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      // Take up most of the screen, minus top safe area
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _comments.isEmpty
                        ? const Center(child: Text('No comments yet. Be the first!'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _comments.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: theme.colorScheme.secondaryContainer,
                                    backgroundImage: comment.authorAvatarUrl != null &&
                                            comment.authorAvatarUrl!.isNotEmpty
                                        ? NetworkImage(comment.authorAvatarUrl!)
                                        : null,
                                    child: comment.authorAvatarUrl == null ||
                                            comment.authorAvatarUrl!.isEmpty
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
                                            Text(
                                              comment.authorName ?? 'Unknown User',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment.body,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
          ),
          const Divider(height: 1),
          
          // ── Input Field ───────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _postComment(),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isPosting
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.send, color: theme.colorScheme.primary),
                        onPressed: _postComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
