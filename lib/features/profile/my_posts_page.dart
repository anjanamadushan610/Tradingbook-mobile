import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../post/widgets/post_card.dart';

/// Your posts with their moderation status — where "post approved/rejected"
/// notifications land.
class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  late final _posts = PagedCubit<Post>(
    (c) => sl<PostRepository>().mine(cursor: c),
    keyOf: (p) => p.id,
  );

  @override
  void dispose() {
    _posts.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your posts')),
      body: PagedListView<Post>(
        cubit: _posts,
        itemBuilder: (_, p, _) => PostCard(
          key: ValueKey(p.id),
          post: p,
          showStatus: true,
          onDeleted: () => _posts.removeWhere((x) => x.id == p.id),
        ),
        empty: const EmptyView(icon: Icons.edit_note_rounded, title: 'No posts yet'),
      ),
    );
  }
}
