import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/paginated.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/community.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../communities/widgets/community_tiles.dart';
import '../notifications/notification_bell.dart';
import '../post/widgets/post_card.dart';
import '../profile/widgets/follow_button.dart';

/// Trending topics, who to follow, communities, and trending posts — the
/// same rails as the web /discover page.
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late final _trending = PagedCubit<Post>(
    (cursor) => sl<PostRepository>().trending(cursor: cursor),
    keyOf: (p) => p.id,
  );
  late Future<Paginated<TrendingTopic>> _topics;
  late Future<Paginated<UserProfile>> _traders;
  late Future<(Paginated<Group>, Paginated<CommunityPage>)> _communities;

  @override
  void initState() {
    super.initState();
    _loadRails();
  }

  void _loadRails() {
    _topics = sl<PostRepository>().trendingTopics();
    _traders = sl<UserRepository>().suggestedTraders(limit: 12);
    final c = sl<CommunityRepository>();
    _communities = (c.discoverGroups(limit: 10), c.discoverPages(limit: 10)).wait;
  }

  @override
  void dispose() {
    _trending.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: PagedListView<Post>(
        cubit: _trending,
        onRefresh: () async => setState(_loadRails),
        headerSlivers: [
          SliverToBoxAdapter(child: _SearchField()),
          SliverToBoxAdapter(child: _TopicsRail(future: _topics)),
          SliverToBoxAdapter(child: _TradersRail(future: _traders)),
          SliverToBoxAdapter(child: _CommunitiesRail(future: _communities)),
          const SliverToBoxAdapter(child: _SectionTitle('Trending posts', icon: Icons.local_fire_department_rounded)),
        ],
        itemBuilder: (context, post, _) => PostCard(
          key: ValueKey(post.id),
          post: post,
          onDeleted: () => _trending.removeWhere((p) => p.id == post.id),
        ),
        empty: const EmptyView(
          icon: Icons.trending_up_rounded,
          title: 'Nothing trending yet',
          message: 'Posts with the most discussion in the last week show up here.',
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(Routes.search()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Text('Search traders, posts and #tags',
                  style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.icon, this.action});

  final String title;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface))),
          ?action,
        ],
      ),
    );
  }
}

class _TopicsRail extends StatelessWidget {
  const _TopicsRail({required this.future});

  final Future<Paginated<TrendingTopic>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Paginated<TrendingTopic>>(
      future: future,
      builder: (context, snap) {
        final topics = snap.data?.items ?? const [];
        if (topics.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Trending topics', icon: Icons.tag_rounded),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: topics.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ActionChip(
                  label: Text('${topics[i].label} · ${Fmt.count(topics[i].postCount)}'),
                  onPressed: () => context.push(Routes.search('#${topics[i].tag}')),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TradersRail extends StatelessWidget {
  const _TradersRail({required this.future});

  final Future<Paginated<UserProfile>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Paginated<UserProfile>>(
      future: future,
      builder: (context, snap) {
        final traders = snap.data?.items ?? const [];
        if (snap.connectionState == ConnectionState.done && traders.isEmpty) {
          return const SizedBox.shrink();
        }
        final cs = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Traders to follow', icon: Icons.person_search_rounded),
            SizedBox(
              height: 196,
              child: traders.isEmpty
                  ? const LoadingView()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: traders.length,
                      itemBuilder: (context, i) {
                        final t = traders[i];
                        return SizedBox(
                          width: 150,
                          child: Card(
                            margin: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => context.push(Routes.user(t.id)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    AppAvatar(url: t.avatarUrl, name: t.displayName, size: 56),
                                    const SizedBox(height: 8),
                                    Text(t.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
                                    Text(
                                      '${Fmt.count(t.followerCount ?? 0)} followers',
                                      style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                    const Spacer(),
                                    FollowButton(userId: t.id, initial: false),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CommunitiesRail extends StatelessWidget {
  const _CommunitiesRail({required this.future});

  final Future<(Paginated<Group>, Paginated<CommunityPage>)> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Paginated<Group>, Paginated<CommunityPage>)>(
      future: future,
      builder: (context, snap) {
        final groups = snap.data?.$1.items ?? const <Group>[];
        final pages = snap.data?.$2.items ?? const <CommunityPage>[];
        if (groups.isEmpty && pages.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              'Communities',
              icon: Icons.groups_rounded,
              action: TextButton(
                onPressed: () => context.go(Routes.communities),
                child: const Text('See all'),
              ),
            ),
            SizedBox(
              height: 162,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final g in groups)
                    CommunityCard(
                      name: g.name,
                      subtitle: '${Fmt.count(g.memberCount)} members',
                      icon: Icons.groups_2_outlined,
                      avatarUrl: g.avatarUrl,
                      coverUrl: g.coverUrl,
                      onTap: () => context.push(Routes.group(g.id)),
                    ),
                  for (final p in pages)
                    CommunityCard(
                      name: p.name,
                      subtitle: '${Fmt.count(p.followerCount)} followers',
                      icon: Icons.flag_outlined,
                      avatarUrl: p.avatarUrl,
                      coverUrl: p.coverUrl,
                      onTap: () => context.push(Routes.page(p.id)),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
