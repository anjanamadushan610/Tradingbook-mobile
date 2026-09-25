import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../post/widgets/post_card.dart';

/// Saved posts — private to you; authors are never told.
class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  late final _saved = PagedCubit<Post>((c) => sl<PostRepository>().bookmarks(cursor: c), keyOf: (p) => p.id);

  @override
  void dispose() {
    _saved.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved posts')),
      body: PagedListView<Post>(
        cubit: _saved,
        itemBuilder: (_, p, _) => PostCard(
          key: ValueKey(p.id),
          post: p,
          onDeleted: () => _saved.removeWhere((x) => x.id == p.id),
        ),
        empty: const EmptyView(
          icon: Icons.bookmark_border_rounded,
          title: 'Nothing saved yet',
          message: 'Tap the bookmark on any post to read it later. Only you can see your saved posts.',
        ),
      ),
    );
  }
}
