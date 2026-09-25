import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/post.dart';
import '../../data/repositories/moderation_repository.dart';
import '../auth/session_cubit.dart';
import '../post/widgets/post_card.dart';

/// Platform review queue (moderators/admins). Approve or reject one post, or
/// select several for a bulk action.
class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  final _repo = sl<ModerationRepository>();
  String _status = 'all';
  late PagedCubit<Post> _queue = _build();
  final Set<String> _selected = {};

  PagedCubit<Post> _build() =>
      PagedCubit<Post>((c) => _repo.queue(status: _status, cursor: c), keyOf: (p) => p.id);

  @override
  void dispose() {
    _queue.close();
    super.dispose();
  }

  void _setStatus(String s) {
    if (s == _status) return;
    _queue.close();
    setState(() {
      _status = s;
      _selected.clear();
      _queue = _build();
    });
  }

  Future<String?> _askReason() => promptDialog(
        context,
        title: 'Reason for rejection',
        hint: 'Shown to the author',
        confirmLabel: 'Reject',
        maxLines: 3,
        maxLength: 500,
      );

  Future<void> _approve(Post p) async {
    final ok = await guard(context, () => _repo.approve(p.id), success: 'Approved — now live');
    if (ok) _queue.removeWhere((x) => x.id == p.id);
  }

  Future<void> _reject(Post p) async {
    final reason = await _askReason();
    if (reason == null || !mounted) return;
    final ok = await guard(context, () => _repo.reject(p.id, reason), success: 'Rejected');
    if (ok) _queue.removeWhere((x) => x.id == p.id);
  }

  Future<void> _bulk(bool approve) async {
    final ids = _selected.toList();
    String? reason;
    if (!approve) {
      reason = await _askReason();
      if (reason == null) return;
    }
    if (!mounted) return;
    try {
      final result = approve ? await _repo.bulkApprove(ids) : await _repo.bulkReject(ids, reason!);
      if (!mounted) return;
      Toast.show(context, '${result.succeeded} of ${result.total} ${approve ? 'approved' : 'rejected'}'
          '${result.failed > 0 ? ' · ${result.failed} failed' : ''}');
      setState(_selected.clear);
      _queue.refresh();
    } catch (e) {
      if (mounted) Toast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMod = context.select((SessionCubit s) => s.state.userOrNull?.isModerator ?? false);
    if (!isMod) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyView(icon: Icons.lock_outline_rounded, title: 'Moderators only'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_selected.isEmpty ? 'Review queue' : '${_selected.length} selected'),
        actions: [
          if (_selected.isNotEmpty) ...[
            IconButton(
              tooltip: 'Reject selected',
              onPressed: () => _bulk(false),
              icon: const Icon(Icons.close_rounded, color: AppColors.error),
            ),
            IconButton(
              tooltip: 'Approve selected',
              onPressed: () => _bulk(true),
              icon: const Icon(Icons.done_all_rounded, color: AppColors.success),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Reports',
              onPressed: () => context.push(Routes.moderationReports),
              icon: const Icon(Icons.flag_outlined),
            ),
            IconButton(
              tooltip: 'Audit log',
              onPressed: () => context.push(Routes.moderationAudit),
              icon: const Icon(Icons.history_rounded),
            ),
          ],
        ],
      ),
      body: PagedListView<Post>(
        key: ValueKey(_status),
        cubit: _queue,
        headerSlivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All')),
                  ButtonSegment(value: 'pending', label: Text('Personal')),
                  ButtonSegment(value: 'pending_platform', label: Text('Groups/Pages')),
                ],
                selected: {_status},
                onSelectionChanged: (s) => _setStatus(s.first),
              ),
            ),
          ),
        ],
        itemBuilder: (_, p, _) {
          final selected = _selected.contains(p.id);
          return Column(
            children: [
              Container(
                color: selected ? AppColors.primary.withValues(alpha: 0.08) : null,
                child: CheckboxListTile(
                  value: selected,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(p.status.label),
                  onChanged: (v) => setState(() => v == true ? _selected.add(p.id) : _selected.remove(p.id)),
                ),
              ),
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
          );
        },
        empty: const EmptyView(icon: Icons.task_alt_rounded, title: 'Queue is clear', message: 'Nothing waiting for review.'),
      ),
    );
  }
}
