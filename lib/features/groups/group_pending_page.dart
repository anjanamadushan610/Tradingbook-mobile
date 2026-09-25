import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/post.dart';
import '../../data/repositories/community_repository.dart';
import '../post/widgets/post_card.dart';

/// Stage 1 of group moderation: the group's own moderators approve a post
/// (it then goes to platform review) or reject it with a reason.
class GroupPendingPage extends StatefulWidget {
  const GroupPendingPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupPendingPage> createState() => _GroupPendingPageState();
}

class _GroupPendingPageState extends State<GroupPendingPage> {
  final _repo = sl<CommunityRepository>();
  late final _pending = PagedCubit<Post>(
    (c) => _repo.pendingGroupPosts(widget.groupId, cursor: c),
    keyOf: (p) => p.id,
  );

  @override
  void dispose() {
    _pending.close();
    super.dispose();
  }

  Future<void> _approve(Post p) async {
    final ok = await guard(context, () => _repo.approveGroupPost(widget.groupId, p.id),
        success: 'Approved — sent to platform review');
    if (ok) _pending.removeWhere((x) => x.id == p.id);
  }

  Future<void> _reject(Post p) async {
    final reason = await promptDialog(
      context,
      title: 'Reject post',
      hint: 'Reason shown to the author (optional)',
      confirmLabel: 'Reject',
      maxLines: 3,
      maxLength: 500,
      allowEmpty: true,
    );
    if (reason == null || !mounted) return;
    final ok = await guard(context, () => _repo.rejectGroupPost(widget.groupId, p.id, reason), success: 'Rejected');
    if (ok) _pending.removeWhere((x) => x.id == p.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts awaiting approval')),
      body: PagedListView<Post>(
        cubit: _pending,
        itemBuilder: (_, p, _) => Column(
          children: [
            PostCard(key: ValueKey(p.id), post: p, tapToOpen: false),
            Transform.translate(
              offset: const Offset(0, -8),
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _reject(p),
                        icon: const Icon(Icons.close_rounded, color: AppColors.error),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                        onPressed: () => _approve(p),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        empty: const EmptyView(
          icon: Icons.fact_check_outlined,
          title: 'All caught up',
          message: 'No member posts are waiting for approval.',
        ),
      ),
    );
  }
}
