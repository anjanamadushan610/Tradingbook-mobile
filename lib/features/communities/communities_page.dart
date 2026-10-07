import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/paginated.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/community.dart';
import '../../data/repositories/community_repository.dart';

import 'widgets/community_tiles.dart';

/// Groups (discussion communities with their own moderators) and Pages
/// (brand/creator channels) — "Groups" and "Pages" on the web.
class CommunitiesPage extends StatefulWidget {
  const CommunitiesPage({super.key, this.initialTab});

  final String? initialTab;

  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this, initialIndex: widget.initialTab == 'pages' ? 1 : 0);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Groups'), Tab(text: 'Pages')]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push(_tabs.index == 0 ? Routes.createGroup : Routes.createPage),
        icon: const Icon(Icons.add_rounded),
        label: AnimatedBuilder(
          animation: _tabs,
          builder: (_, _) => Text(_tabs.index == 0 ? 'New group' : 'New page'),
        ),
      ),
      body: TabBarView(controller: _tabs, children: const [_GroupsTab(), _PagesTab()]),
    );
  }
}

class _GroupsTab extends StatefulWidget {
  const _GroupsTab();

  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> with AutomaticKeepAliveClientMixin {
  final _repo = sl<CommunityRepository>();
  late Future<Paginated<Group>> _mine = _repo.myGroups(limit: 50);
  late final _discover = PagedCubit<Group>((c) => _repo.discoverGroups(cursor: c), keyOf: (g) => g.id);

  /// IDs of groups the user joined this session — keeps cards visible in the
  /// discover list even after the API starts excluding already-joined groups.
  final _joinedIds = <String>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _discover.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedListView<Group>(
      cubit: _discover,
      skeletonHeight: 80,
      onRefresh: () async => setState(() => _mine = _repo.myGroups(limit: 50)),
      headerSlivers: [
        SliverToBoxAdapter(
          child: _MineSection<Group>(
            future: _mine,
            title: 'Your groups',
            emptyText: 'You haven\'t joined any groups yet.',
            tile: (g) => GroupTile(group: g),
          ),
        ),
        const SliverToBoxAdapter(child: _Header('Discover groups')),
      ],
      itemBuilder: (_, g, _) => GroupTile(
        group: g,
        trailing: _joinedIds.contains(g.id)
            ? const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary)
            : null,
        onTap: () async {
          await context.push(Routes.group(g.id));
          // After returning from detail, check if user joined this group
          // and mark it locally so it stays visible in the discover list.
          final membership = await _repo.membership(g.id).catchError((_) => GroupMembership.none);
          if (membership != GroupMembership.none && mounted) {
            setState(() => _joinedIds.add(g.id));
          }
        },
      ),
      empty: const EmptyView(
        icon: Icons.groups_outlined,
        title: 'No groups to discover',
        message: 'You\'re in every public group — or create a new one.',
      ),
    );
  }
}

class _PagesTab extends StatefulWidget {
  const _PagesTab();

  @override
  State<_PagesTab> createState() => _PagesTabState();
}

class _PagesTabState extends State<_PagesTab> with AutomaticKeepAliveClientMixin {
  final _repo = sl<CommunityRepository>();
  late Future<Paginated<CommunityPage>> _mine = _repo.myPages();
  late final _discover = PagedCubit<CommunityPage>((c) => _repo.discoverPages(cursor: c), keyOf: (p) => p.id);

  /// IDs of pages the user followed this session — keeps cards visible in the
  /// discover list even after the API starts excluding already-followed pages.
  final _followedIds = <String>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _discover.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedListView<CommunityPage>(
      cubit: _discover,
      skeletonHeight: 80,
      onRefresh: () async => setState(() => _mine = _repo.myPages()),
      headerSlivers: [
        SliverToBoxAdapter(
          child: _MineSection<CommunityPage>(
            future: _mine,
            title: 'Pages you manage',
            emptyText: 'Create a page for your brand, desk or research.',
            tile: (p) => PageTile(page: p),
          ),
        ),
        const SliverToBoxAdapter(child: _Header('Discover pages')),
      ],
      itemBuilder: (_, p, _) => PageTile(
        page: p,
        trailing: _followedIds.contains(p.id)
            ? const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary)
            : null,
        onTap: () async {
          await context.push(Routes.page(p.id));
          // After returning from detail, check if the user followed this page
          // and mark it locally so it stays visible in the discover list.
          final isNowFollowing = await _repo.isFollowingPage(p.id).catchError((_) => false);
          if (isNowFollowing && mounted) {
            setState(() => _followedIds.add(p.id));
          }
        },
      ),
      empty: const EmptyView(
        icon: Icons.flag_outlined,
        title: 'No pages to discover',
        message: 'You follow every page there is — nice.',
      ),
    );
  }
}

class _MineSection<T> extends StatelessWidget {
  const _MineSection({
    required this.future,
    required this.title,
    required this.emptyText,
    required this.tile,
  });

  final Future<Paginated<T>> future;
  final String title;
  final String emptyText;
  final Widget Function(T) tile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<Paginated<T>>(
      future: future,
      builder: (context, snap) {
        return Container(
          color: cs.surface,
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(title),
              if (snap.connectionState != ConnectionState.done)
                const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator())
              else if (snap.hasError)
                ErrorView(error: snap.error, compact: true)
              else if (snap.data!.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(emptyText, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant)),
                )
              else
                ...snap.data!.items.map(tile),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(
          text,
          style: AppTextStyles.headlineSmall.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
}
