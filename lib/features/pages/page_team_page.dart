import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/community.dart';
import '../../data/repositories/community_repository.dart';
import '../auth/session_cubit.dart';
import '../profile/widgets/user_picker_sheet.dart';
import '../profile/widgets/user_tile.dart';

/// A page's team (owner / admins / editors) and its followers.
class PageTeamPage extends StatefulWidget {
  const PageTeamPage({super.key, required this.pageId});

  final String pageId;

  @override
  State<PageTeamPage> createState() => _PageTeamPageState();
}

class _PageTeamPageState extends State<PageTeamPage> {
  final _repo = sl<CommunityRepository>();
  late Future<List<PageRoleEntry>> _roles = _repo.pageRoles(widget.pageId);
  late final _followers = PagedCubit<PageFollower>(
    (c) => _repo.pageFollowers(widget.pageId, cursor: c),
    keyOf: (f) => f.userId,
  );

  @override
  void dispose() {
    _followers.close();
    super.dispose();
  }

  void _reload() => setState(() => _roles = _repo.pageRoles(widget.pageId));

  Future<void> _add() async {
    final user = await pickUser(context, title: 'Add to page team');
    if (user == null || !mounted) return;
    final role = await _pickRole(null);
    if (role == null || !mounted) return;
    final ok = await guard(context, () => _repo.setPageRole(widget.pageId, user.id, role),
        success: '${user.displayName} added as ${role.label.toLowerCase()}');
    if (ok) _reload();
  }

  Future<PageRole?> _pickRole(PageRole? current) => showModalBottomSheet<PageRole>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in [PageRole.admin, PageRole.editor])
                ListTile(
                  title: Text(r.label),
                  subtitle: Text(r == PageRole.admin
                      ? 'Edit the page, manage the team and post'
                      : 'Post as the page'),
                  trailing: r == current ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                  onTap: () => Navigator.pop(ctx, r),
                ),
            ],
          ),
        ),
      );

  Future<void> _manage(PageRoleEntry entry) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Change role'),
              onTap: () => Navigator.pop(ctx, 'role'),
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.error),
              title: const Text('Remove from team', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'role') {
      final role = await _pickRole(entry.role);
      if (role == null || role == entry.role || !mounted) return;
      final ok = await guard(context, () => _repo.setPageRole(widget.pageId, entry.userId, role), success: 'Role updated');
      if (ok) _reload();
    } else {
      final ok = await guard(context, () => _repo.removePageRole(widget.pageId, entry.userId), success: 'Removed');
      if (ok) _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<SessionCubit>().user?.id;
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Page team'),
          bottom: const TabBar(tabs: [Tab(text: 'Team'), Tab(text: 'Followers')]),
        ),
        body: TabBarView(
          children: [
            FutureBuilder<List<PageRoleEntry>>(
              future: _roles,
              builder: (context, snap) {
                if (snap.hasError) return ErrorView(error: snap.error, onRetry: _reload);
                if (!snap.hasData) return const LoadingView();
                final roles = snap.data!;
                final myRole = roles.where((r) => r.userId == me).firstOrNull?.role;
                final canManage = myRole == PageRole.owner || myRole == PageRole.admin;
                return ListView(
                  children: [
                    for (final r in roles)
                      UserTile(
                        userId: r.userId,
                        subtitle: r.role.label,
                        trailing: canManage && r.role != PageRole.owner && r.userId != me
                            ? IconButton(
                                tooltip: 'Manage',
                                icon: const Icon(Icons.more_vert_rounded),
                                onPressed: () => _manage(r),
                              )
                            : const SizedBox.shrink(),
                      ),
                    if (canManage)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton.icon(
                          onPressed: _add,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Add team member'),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Admins can edit the page and its team. Editors can publish as the page.',
                        style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                );
              },
            ),
            PagedListView<PageFollower>(
              cubit: _followers,
              skeletonHeight: 70,
              itemBuilder: (_, f, _) => UserTile(userId: f.userId),
              empty: const EmptyView(icon: Icons.people_outline_rounded, title: 'No followers yet'),
            ),
          ],
        ),
      ),
    );
  }
}
