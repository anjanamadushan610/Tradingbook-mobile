import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import '../profile/widgets/user_tile.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final _repo = sl<UserRepository>();
  late final _blocked = PagedCubit<FollowEdge>((c) => _repo.blocked(cursor: c), keyOf: (e) => e.userId);

  @override
  void dispose() {
    _blocked.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked traders')),
      body: PagedListView<FollowEdge>(
        cubit: _blocked,
        skeletonHeight: 70,
        itemBuilder: (_, e, _) => UserTile(
          userId: e.userId,
          trailing: TextButton(
            onPressed: () async {
              final ok = await guard(context, () => _repo.unblock(e.userId), success: 'Unblocked');
              if (ok) _blocked.removeWhere((x) => x.userId == e.userId);
            },
            child: const Text('Unblock'),
          ),
        ),
        empty: const EmptyView(
          icon: Icons.block_rounded,
          title: 'No one blocked',
          message: 'Block a trader from their profile or a post\'s ⋯ menu.',
        ),
      ),
    );
  }
}
