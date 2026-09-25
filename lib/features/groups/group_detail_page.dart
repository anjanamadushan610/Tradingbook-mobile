import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/api_exception.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/net_image.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/community.dart';
import '../../data/models/moderation.dart';
import '../../data/models/post.dart';
import '../../data/repositories/community_repository.dart';
import '../post/widgets/post_card.dart';
import '../report/report_sheet.dart';

class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final _repo = sl<CommunityRepository>();
  late Future<(Group, GroupMembership)> _load = _fetch();
  late final _feed = PagedCubit<Post>(
    (c) => _repo.groupFeed(widget.groupId, cursor: c),
    keyOf: (p) => p.id,
  );
  bool _busy = false;
  bool _requested = false;

  Future<(Group, GroupMembership)> _fetch() =>
      (_repo.group(widget.groupId), _repo.membership(widget.groupId).catchError((_) => GroupMembership.none)).wait;

  void _reload() {
    setState(() => _load = _fetch());
    _feed.load();
  }

  @override
  void dispose() {
    _feed.close();
    super.dispose();
  }

  Future<void> _join(Group g) async {
    setState(() => _busy = true);
    try {
      await _repo.joinGroup(g.id);
      if (!mounted) return;
      if (g.isPrivate) {
        setState(() => _requested = true);
        Toast.show(context, 'Request sent. An admin will review it.');
      } else {
        Toast.show(context, 'You joined ${g.name}');
        _reload();
      }
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(Group g) async {
    final ok = await confirmDialog(
      context,
      title: 'Leave ${g.name}?',
      message: g.isPrivate ? 'You\'ll need an admin to let you back in.' : 'You can rejoin any time.',
      confirmLabel: 'Leave',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await guard(context, () => _repo.leaveGroup(g.id), success: 'You left the group');
    if (done) _reload();
  }

  Future<void> _menu(String action, Group g) async {
    switch (action) {
      case 'share':
        await SharePlus.instance.share(ShareParams(text: '${g.name} on TradingBook\n${AppConfig.groupUrl(g.id)}'));
      case 'report':
        await showReportSheet(context, target: ReportTarget.group, targetId: g.id);
      case 'leave':
        await _leave(g);
      case 'delete':
        final ok = await confirmDialog(
          context,
          title: 'Delete ${g.name}?',
          message: 'This permanently removes the group and its memberships. This can\'t be undone.',
          confirmLabel: 'Delete group',
          destructive: true,
        );
        if (!ok || !mounted) return;
        final done = await guard(context, () => _repo.deleteGroup(g.id), success: 'Group deleted');
        if (done && mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Group, GroupMembership)>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(appBar: AppBar(), body: const LoadingView());
        }
        if (snap.hasError) {
          final e = snap.error;
          return Scaffold(
            appBar: AppBar(),
            body: e is ApiException && e.isNotFound
                ? _PrivateGroup(onRequest: () async {
                    await guard(context, () => _repo.joinGroup(widget.groupId),
                        success: 'Request sent. An admin will review it.');
                  })
                : ErrorView(error: e, onRetry: _reload),
          );
        }
        final (group, membership) = snap.data!;
        final role = membership.role;
        final canManage = role?.canManage ?? false;
        final canModerate = role != null && role.rank >= GroupRole.moderator.rank;

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (a) => _menu(a, group),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'share', child: Text('Share group')),
                  if (membership.isMember && role != GroupRole.owner)
                    const PopupMenuItem(value: 'leave', child: Text('Leave group')),
                  if (role != GroupRole.owner) const PopupMenuItem(value: 'report', child: Text('Report group')),
                  if (role == GroupRole.owner) const PopupMenuItem(value: 'delete', child: Text('Delete group')),
                ],
              ),
            ],
          ),
          floatingActionButton: membership.isMember
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: () async {
                    final posted = await context.push<bool>(Routes.compose(groupId: group.id));
                    if (posted == true) _feed.refresh();
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Post'),
                )
              : null,
          body: PagedListView<Post>(
            cubit: _feed,
            onRefresh: () async => setState(() => _load = _fetch()),
            headerSlivers: [
              SliverToBoxAdapter(
                child: _GroupHeader(
                  group: group,
                  actions: [
                    if (!membership.isMember)
                      AppButton.small(
                        label: _requested || group.isPrivate ? (_requested ? 'Requested' : 'Request to join') : 'Join',
                        icon: Icons.group_add_rounded,
                        isLoading: _busy,
                        onPressed: _requested ? null : () => _join(group),
                      )
                    else ...[
                      AppButton.small(
                        label: 'Members',
                        icon: Icons.people_alt_outlined,
                        style: AppButtonStyle.subtle,
                        onPressed: () => context.push(Routes.groupMembers(group.id)),
                      ),
                      if (canModerate)
                        AppButton.small(
                          label: 'Approvals',
                          icon: Icons.fact_check_outlined,
                          style: AppButtonStyle.subtle,
                          onPressed: () => context.push(Routes.groupPending(group.id)),
                        ),
                      if (canManage)
                        AppButton.small(
                          label: 'Edit',
                          icon: Icons.settings_outlined,
                          style: AppButtonStyle.subtle,
                          onPressed: () async {
                            await context.push(Routes.editGroup(group.id));
                            _reload();
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ],
            itemBuilder: (_, p, _) => PostCard(
              key: ValueKey(p.id),
              post: p,
              contextType: 'group',
              onDeleted: () => _feed.removeWhere((x) => x.id == p.id),
            ),
            empty: EmptyView(
              icon: Icons.forum_outlined,
              title: 'No posts yet',
              message: membership.isMember
                  ? 'Be the first to share a setup with the group.'
                  : 'Join to see and share posts.',
            ),
          ),
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group, required this.actions});

  final Group group;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: cs.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  bottom: 36,
                  child: group.coverUrl == null
                      ? Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient))
                      : NetImage(url: group.coverUrl!),
                ),
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: AppAvatar(
                    url: group.avatarUrl,
                    name: group.name,
                    size: 76,
                    square: true,
                    borderColor: dark ? AppColors.darkSurface : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: AppTextStyles.headlineLarge.copyWith(color: cs.onSurface)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(group.isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded,
                        size: 15, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${group.isPrivate ? 'Private' : 'Public'} group · ${Fmt.count(group.memberCount)} members',
                      style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                if (group.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(group.description, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                ],
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateGroup extends StatelessWidget {
  const _PrivateGroup({required this.onRequest});

  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      icon: Icons.lock_outline_rounded,
      title: 'This group is private',
      message: 'Only members can see it. Ask to join and an admin will review your request.',
      actionLabel: 'Request to join',
      onAction: onRequest,
    );
  }
}
