import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../post/widgets/post_card.dart';
import '../profile/widgets/user_tile.dart';

/// Search traders (by name) and public posts (by caption / #tag).
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late final _tabs = TabController(
    length: 2,
    vsync: this,
    // A #tag search is about posts.
    initialIndex: widget.initialQuery.startsWith('#') ? 1 : 0,
  );
  String _query = '';
  Timer? _debounce;
  PagedCubit<UserProfile>? _people;
  PagedCubit<Post>? _posts;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) _run(widget.initialQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _tabs.dispose();
    _people?.close();
    _posts?.close();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _run(value));
  }

  void _run(String raw) {
    final q = raw.trim();
    if (q == _query) return;
    _people?.close();
    _posts?.close();
    setState(() {
      _query = q;
      if (q.isEmpty) {
        _people = null;
        _posts = null;
        return;
      }
      // People search matches names; strip a leading '#'/'@'.
      final nameQuery = q.replaceFirst(RegExp(r'^[#@]'), '');
      _people = nameQuery.isEmpty
          ? null
          : PagedCubit<UserProfile>(
              (c) => sl<UserRepository>().search(nameQuery, cursor: c),
              keyOf: (u) => u.id,
            );
      _posts = PagedCubit<Post>((c) => sl<PostRepository>().search(q, cursor: c), keyOf: (p) => p.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery.isEmpty,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _run,
          decoration: InputDecoration(
            hintText: 'Search TradingBook',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _controller.clear();
                      _run('');
                    },
                  ),
          ),
        ),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Traders'), Tab(text: 'Posts')]),
      ),
      body: _query.isEmpty
          ? const EmptyView(
              icon: Icons.search_rounded,
              title: 'Search TradingBook',
              message: 'Find traders by name, or posts by keyword and #tag.',
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _people == null
                    ? const SizedBox.shrink()
                    : PagedListView<UserProfile>(
                        key: ValueKey('people-$_query'),
                        cubit: _people!,
                        skeletonHeight: 70,
                        itemBuilder: (_, u, _) => UserTile(user: u),
                        empty: EmptyView(
                          icon: Icons.person_search_rounded,
                          title: 'No traders found',
                          message: 'Nobody matches "$_query". Private profiles don\'t appear in search.',
                        ),
                      ),
                PagedListView<Post>(
                  key: ValueKey('posts-$_query'),
                  cubit: _posts!,
                  itemBuilder: (_, p, _) => PostCard(key: ValueKey(p.id), post: p),
                  empty: EmptyView(
                    icon: Icons.article_outlined,
                    title: 'No posts found',
                    message: 'No public posts mention "$_query" yet.',
                  ),
                ),
              ],
            ),
    );
  }
}
