import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
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

/// The signed-in trader's own profile tab with a premium tabbed layout:
/// "My Posts" (all statuses) and "Bookmarks" shortcut.
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  late final _posts = PagedCubit<Post>(
    (cursor) => sl<PostRepository>().mine(cursor: cursor),
    keyOf: (p) => p.id,
  );
  late final _bookmarks = PagedCubit<Post>(
    (cursor) => sl<PostRepository>().bookmarks(cursor: cursor),
    keyOf: (p) => p.id,
  );
  final _headerKey = GlobalKey<ProfileHeaderState>();

  @override
  void dispose() {
    _tab.dispose();
    _posts.close();
    _bookmarks.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit s) => s.state.userOrNull);
    if (user == null) return const Scaffold(body: LoadingView());

    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ── Transparent AppBar that floats over the cover photo ──
      backgroundColor: dark ? AppColors.darkBackground : AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
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
          _StickyTabBar(controller: _tab, cs: cs),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            // ── Tab 0: My Posts ──────────────────────────────────────────
            RefreshIndicator(
              onRefresh: () async {
                _headerKey.currentState?.reloadCounts();
                await context.read<SessionCubit>().refreshProfile();
                _posts.refresh();
              },
              child: PagedListView<Post>(
                cubit: _posts,
                padding: EdgeInsets.zero,
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
                  message:
                      'Share your first setup — it goes live once a moderator approves it.',
                  actionLabel: 'Create post',
                  onAction: () => context.push(Routes.compose()),
                ),
              ),
            ),

            // ── Tab 1: Bookmarks ─────────────────────────────────────────
            RefreshIndicator(
              onRefresh: () async => _bookmarks.refresh(),
              child: PagedListView<Post>(
                cubit: _bookmarks,
                padding: EdgeInsets.zero,
                itemBuilder: (context, post, _) => PostCard(
                  key: ValueKey(post.id),
                  post: post,
                  contextType: 'profile',
                  onDeleted: () =>
                      _bookmarks.removeWhere((p) => p.id == post.id),
                ),
                empty: const EmptyView(
                  icon: Icons.bookmark_border_rounded,
                  title: 'No bookmarks yet',
                  message: 'Save posts you want to revisit.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky tab bar (Project A style: primary indicator, no background)
// ─────────────────────────────────────────────────────────────────────────────

class _StickyTabBar extends StatelessWidget {
  const _StickyTabBar({required this.controller, required this.cs});

  final TabController controller;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = dark ? AppColors.darkDivider : AppColors.divider;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: controller,
          labelColor: dark ? AppColors.primaryLight : AppColors.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: dark ? AppColors.primaryLight : AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: dividerColor,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Bookmarks'),
          ],
        ),
        cs.surface,
        dividerColor,
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar, this.bgColor, this.borderColor);

  final TabBar tabBar;
  final Color bgColor;
  final Color borderColor;

  @override
  double get minExtent => 48.0;
  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.tabBar != tabBar || old.bgColor != bgColor;
}
