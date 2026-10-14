import 'dart:async';

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
import '../../data/models/user.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../profile/widgets/user_tile.dart';

import 'widgets/community_actions.dart';
import 'widgets/community_tiles.dart';

/// Groups (discussion communities with their own moderators), Pages
/// (brand/creator channels) and Traders — each searchable, and each joinable
/// or followable straight from the list.
class CommunitiesPage extends StatefulWidget {
  const CommunitiesPage({super.key, this.initialTab});

  final String? initialTab;

  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: switch (widget.initialTab) {
      'pages' => 1,
      'traders' => 2,
      _ => 0,
    },
  );

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
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Groups'), Tab(text: 'Pages'), Tab(text: 'Traders')],
        ),
      ),
      // Say exactly what gets created (QA mobile BUG 10); traders aren't created.
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (context, _) => _tabs.index == 2
            ? const SizedBox.shrink()
            : _CreateButton(
                label: _tabs.index == 0 ? 'Create Group' : 'Create Page',
                onTap: () => context.push(_tabs.index == 0 ? Routes.createGroup : Routes.createPage),
              ),
      ),
      body: TabBarView(controller: _tabs, children: const [_GroupsTab(), _PagesTab(), _TradersTab()]),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
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
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// A tab with a search box over a paged list: the tab's own list (discover,
/// suggestions) while the box is empty, matches by name while it isn't.
class _SearchableList<T> extends StatefulWidget {
  const _SearchableList({
    required this.hint,
    required this.browse,
    required this.search,
    required this.keyOf,
    required this.itemBuilder,
    required this.browseEmpty,
    this.browseHeader = const [],
    this.onRefresh,
  });

  final String hint;
  final Future<Paginated<T>> Function(String? cursor) browse;
  final Future<Paginated<T>> Function(String query, String? cursor) search;
  final Object Function(T) keyOf;
  final Widget Function(BuildContext context, T item, {required bool searching}) itemBuilder;
  final Widget browseEmpty;
  final List<Widget> browseHeader;
  final Future<void> Function()? onRefresh;

  @override
  State<_SearchableList<T>> createState() => _SearchableListState<T>();
}

class _SearchableListState<T> extends State<_SearchableList<T>> {
  final _field = TextEditingController();
  late final PagedCubit<T> _browse = PagedCubit<T>(widget.browse, keyOf: widget.keyOf);
  PagedCubit<T>? _results;
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    _browse.close();
    _results?.close();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = text.trim();
      if (q == _query) return;
      final old = _results;
      setState(() {
        _query = q;
        _results = q.isEmpty ? null : PagedCubit<T>((c) => widget.search(q, c), keyOf: widget.keyOf);
      });
      old?.close();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final searching = _results != null;
    final box = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: TextField(
          controller: _field,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _field.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _field.clear();
                      _onChanged('');
                    },
                  ),
            isDense: true,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          ),
        ),
      ),
    );
    return PagedListView<T>(
      // A new query is a new list: its own cubit, its own first load.
      key: ValueKey(_query),
      cubit: _results ?? _browse,
      skeletonHeight: 80,
      onRefresh: searching ? null : widget.onRefresh,
      headerSlivers: [box, if (!searching) ...widget.browseHeader],
      itemBuilder: (context, item, _) => widget.itemBuilder(context, item, searching: searching),
      empty: searching
          ? EmptyView(icon: Icons.search_off_rounded, title: 'No matches', message: 'Nothing called "$_query".')
          : widget.browseEmpty,
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

  @override
  bool get wantKeepAlive => true;

  void _reloadMine() => setState(() => _mine = _repo.myGroups(limit: 50));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _SearchableList<Group>(
      hint: 'Search groups',
      browse: (c) => _repo.discoverGroups(cursor: c),
      search: (q, c) => _repo.searchGroups(q, cursor: c),
      keyOf: (g) => g.id,
      onRefresh: () async => _reloadMine(),
      browseHeader: [
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
      // Discover only lists groups the user isn't in; search results may be either.
      itemBuilder: (context, g, {required searching}) => GroupTile(
        group: g,
        trailing: GroupJoinButton(group: g, joined: searching ? null : false, onJoined: _reloadMine),
      ),
      browseEmpty: const EmptyView(
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

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _SearchableList<CommunityPage>(
      hint: 'Search pages',
      browse: (c) => _repo.discoverPages(cursor: c),
      search: (q, c) => _repo.searchPages(q, cursor: c),
      keyOf: (p) => p.id,
      onRefresh: () async => setState(() => _mine = _repo.myPages()),
      browseHeader: [
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
      // Discover only lists pages the user doesn't follow; search results may be either.
      itemBuilder: (context, p, {required searching}) => PageTile(
        page: p,
        trailing: PageFollowButton(page: p, following: searching ? null : false),
      ),
      browseEmpty: const EmptyView(
        icon: Icons.flag_outlined,
        title: 'No pages to discover',
        message: 'You follow every page there is — nice.',
      ),
    );
  }
}

/// Traders to find and follow without opening their profiles (QA mobile BUG 09).
class _TradersTab extends StatefulWidget {
  const _TradersTab();

  @override
  State<_TradersTab> createState() => _TradersTabState();
}

class _TradersTabState extends State<_TradersTab> with AutomaticKeepAliveClientMixin {
  final _repo = sl<UserRepository>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _SearchableList<UserProfile>(
      hint: 'Search traders',
      browse: (c) => _repo.suggestedTraders(cursor: c),
      search: (q, c) => _repo.search(q, cursor: c),
      keyOf: (u) => u.id,
      browseHeader: const [SliverToBoxAdapter(child: _Header('Suggested traders'))],
      // The follow button checks each trader's state itself.
      itemBuilder: (context, u, {required searching}) => UserTile(user: u),
      browseEmpty: const EmptyView(
        icon: Icons.person_search_outlined,
        title: 'No suggestions right now',
        message: 'Search for a trader by name above.',
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
