import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import 'widgets/user_tile.dart';

/// Followers / Following for any trader.
class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key, required this.userId, this.initialTab = 0});

  final String userId;
  final int initialTab;

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final _repo = sl<UserRepository>();
  late final _followers = PagedCubit<FollowEdge>(
    (c) => _repo.followers(widget.userId, cursor: c),
    keyOf: (e) => e.userId,
  );
  late final _following = PagedCubit<FollowEdge>(
    (c) => _repo.following(widget.userId, cursor: c),
    keyOf: (e) => e.userId,
  );

  @override
  void dispose() {
    _followers.close();
    _following.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _repo.cached(widget.userId)?.displayName;
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name ?? 'Connections'),
          bottom: const TabBar(tabs: [Tab(text: 'Followers'), Tab(text: 'Following')]),
        ),
        body: TabBarView(
          children: [
            PagedListView<FollowEdge>(
              cubit: _followers,
              skeletonHeight: 70,
              itemBuilder: (_, e, _) => UserTile(userId: e.userId),
              empty: const EmptyView(icon: Icons.people_outline_rounded, title: 'No followers yet'),
            ),
            PagedListView<FollowEdge>(
              cubit: _following,
              skeletonHeight: 70,
              itemBuilder: (_, e, _) => UserTile(userId: e.userId),
              empty: const EmptyView(icon: Icons.people_outline_rounded, title: 'Not following anyone yet'),
            ),
          ],
        ),
      ),
    );
  }
}
