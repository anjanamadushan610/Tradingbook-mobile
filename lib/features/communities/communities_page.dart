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
import 'package:shimmer/shimmer.dart';
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => context.push(_tabs.index == 0 ? Routes.createGroup : Routes.createPage),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _tabs,
                    builder: (_, _) => Text(
                      _tabs.index == 0 ? 'New group' : 'New page',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                ...List.generate(3, (index) {
                  final dark = Theme.of(context).brightness == Brightness.dark;
                  final base = dark ? AppColors.darkSurfaceVariant : const Color(0xFFE8ECF0);
                  final highlight = dark ? AppColors.darkCardBorder : const Color(0xFFF6F8FA);
                  return Shimmer.fromColors(
                    baseColor: base,
                    highlightColor: highlight,
                    child: ListTile(
                      leading: Container(width: 48, height: 48, color: Colors.white),
                      title: Container(width: 150, height: 16, color: Colors.white),
                      subtitle: Container(width: 100, height: 12, color: Colors.white),
                    ),
                  );
                })
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
          style: AppTextStyles.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.3,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
