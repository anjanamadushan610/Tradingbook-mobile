import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../auth/session_cubit.dart';
import '../post/widgets/post_card.dart';
import 'widgets/profile_header.dart';

/// The signed-in trader's own profile tab: every post they've written, with
/// its review status (drafts, in review, rejected with reason, live).
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  late final _posts = PagedCubit<Post>(
    (cursor) => sl<PostRepository>().mine(cursor: cursor),
    keyOf: (p) => p.id,
  );
  final _headerKey = GlobalKey<ProfileHeaderState>();

  @override
  void dispose() {
    _posts.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit s) => s.state.userOrNull);
    if (user == null) return const Scaffold(body: LoadingView());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Saved posts',
            onPressed: () => context.push(Routes.bookmarks),
            icon: const Icon(Icons.bookmark_border_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: PagedListView<Post>(
        cubit: _posts,
        onRefresh: () async {
          _headerKey.currentState?.reloadCounts();
          await context.read<SessionCubit>().refreshProfile();
        },
        headerSlivers: [
          SliverToBoxAdapter(
            child: ProfileHeader(
              key: _headerKey,
              user: user,
              actions: AppButton.small(
                label: 'Edit profile',
                icon: Icons.edit_outlined,
                style: AppButtonStyle.outlined,
                onPressed: () => context.push(Routes.editProfile),
              ),
            ),
          ),
        ],
        itemBuilder: (context, post, _) => PostCard(
          key: ValueKey(post.id),
          post: post,
          showStatus: true,
          contextType: 'profile',
          onDeleted: () => _posts.removeWhere((p) => p.id == post.id),
        ),
        empty: EmptyView(
          icon: Icons.edit_note_rounded,
          title: 'No posts yet',
          message: 'Share your first setup — it goes live once a moderator approves it.',
          actionLabel: 'Create post',
          onAction: () => context.push(Routes.compose()),
        ),
      ),
    );
  }
}
