import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/paginated.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/community.dart';
import '../../data/repositories/community_repository.dart';
import '../auth/session_cubit.dart';
import '../profile/widgets/user_picker_sheet.dart';
import '../profile/widgets/user_tile.dart';

/// Member list with role management for admins: promote/demote, remove,
/// invite, and approve requests to join a private group.
class GroupMembersPage extends StatefulWidget {
  const GroupMembersPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  final _repo = sl<CommunityRepository>();
  late final _members = PagedCubit<GroupMember>(
    (c) => _repo.members(widget.groupId, cursor: c),
    keyOf: (m) => m.userId,
  );
  GroupRole? _myRole;
  Future<Paginated<PageFollower>>? _requests;

  @override
  void initState() {
    super.initState();
    _repo.membership(widget.groupId).then((m) {
      if (!mounted) return;
      setState(() {
        _myRole = m.role;
        if (m.role?.canManage ?? false) _requests = _repo.joinRequests(widget.groupId);
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _members.close();
    super.dispose();
  }

  bool get _canManage => _myRole?.canManage ?? false;

  Future<void> _invite() async {
    final user = await pickUser(context, title: 'Add a member');
    if (user == null || !mounted) return;
    final ok = await guard(context, () => _repo.inviteMember(widget.groupId, user.id),
        success: '${user.displayName} added');
    if (ok) _members.refresh();
  }

  Future<void> _manage(GroupMember m) async {
    final myRank = _myRole?.rank ?? 0;
    // Mirrors the GroupDO rule: act only on lower ranks, promote below yourself.
    if (m.role.rank >= myRank) return;
    final choices = GroupRole.values.where((r) => r != GroupRole.owner && r.rank < myRank && r != m.role);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in choices)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: Text('Make ${r.label.toLowerCase()}'),
                onTap: () => Navigator.pop(ctx, r.name),
              ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.error),
              title: const Text('Remove from group', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'remove') {
      final ok = await confirmDialog(context,
          title: 'Remove member?', message: 'They can rejoin a public group, or be re-added.',
          confirmLabel: 'Remove', destructive: true);
      if (!ok || !mounted) return;
      final done = await guard(context, () => _repo.removeMember(widget.groupId, m.userId), success: 'Removed');
      if (done) _members.removeWhere((x) => x.userId == m.userId);
    } else {
      final role = GroupRole.fromWire(action)!;
      final done = await guard(context, () => _repo.setMemberRole(widget.groupId, m.userId, role),
          success: 'Role updated');
      if (done) {
        _members.replaceWhere((x) => x.userId == m.userId,
            (x) => GroupMember(userId: x.userId, role: role, joinedAt: x.joinedAt));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<SessionCubit>().user?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          if (_canManage)
            IconButton(tooltip: 'Add member', onPressed: _invite, icon: const Icon(Icons.person_add_alt_1_rounded)),
        ],
      ),
      body: PagedListView<GroupMember>(
        cubit: _members,
        skeletonHeight: 70,
        headerSlivers: [
          if (_requests != null) SliverToBoxAdapter(child: _requestsSection()),
        ],
        itemBuilder: (_, m, _) => UserTile(
          userId: m.userId,
          subtitle: m.role == GroupRole.member ? null : m.role.label,
          trailing: _canManage && m.userId != me && m.role.rank < (_myRole?.rank ?? 0)
              ? IconButton(
                  tooltip: 'Manage member',
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () => _manage(m),
                )
              : (m.role != GroupRole.member ? _RoleBadge(m.role) : const SizedBox.shrink()),
        ),
        empty: const EmptyView(icon: Icons.people_outline_rounded, title: 'No members'),
      ),
    );
  }

  Widget _requestsSection() {
    return FutureBuilder<Paginated<PageFollower>>(
      future: _requests,
      builder: (context, snap) {
        final items = snap.data?.items ?? const <PageFollower>[];
        if (items.isEmpty) return const SizedBox.shrink();
        final cs = Theme.of(context).colorScheme;
        return Container(
          color: AppColors.warning.withValues(alpha: 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('Requests to join (${items.length})',
                    style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
              ),
              for (final r in items)
                UserTile(
                  userId: r.userId,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Decline',
                        icon: const Icon(Icons.close_rounded, color: AppColors.error),
                        onPressed: () async {
                          final ok = await guard(context, () => _repo.declineJoinRequest(widget.groupId, r.userId));
                          if (ok) setState(() => _requests = _repo.joinRequests(widget.groupId));
                        },
                      ),
                      IconButton(
                        tooltip: 'Approve',
                        icon: const Icon(Icons.check_rounded, color: AppColors.success),
                        onPressed: () async {
                          final ok = await guard(context, () => _repo.inviteMember(widget.groupId, r.userId),
                              success: 'Approved');
                          if (ok) {
                            setState(() => _requests = _repo.joinRequests(widget.groupId));
                            _members.refresh();
                          }
                        },
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

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.role);
  final GroupRole role;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(role.label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
      );
}
