import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/api_exception.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/moderation.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../auth/session_cubit.dart';
import '../post/widgets/post_card.dart';
import '../report/report_sheet.dart';
import 'widgets/follow_button.dart';
import 'widgets/profile_header.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late Future<UserProfile> _profile =
      sl<UserRepository>().fetchProfile(widget.userId);
  late final TabController _tab = TabController(length: 2, vsync: this);
  late final _posts = PagedCubit<Post>(
    (cursor) =>
        sl<PostRepository>().byAuthor(widget.userId, cursor: cursor),
    keyOf: (p) => p.id,
  );
  final _headerKey = GlobalKey<ProfileHeaderState>();

  @override
  void initState() {
    super.initState();
    // If navigating to own profile, redirect to the profile tab.
    final me = context.read<SessionCubit>().user;
    if (me?.id == widget.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.me);
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _posts.close();
    super.dispose();
  }

  Future<void> _menu(String action, UserProfile user) async {
    switch (action) {
      case 'share':
        await SharePlus.instance.share(ShareParams(
          text:
              '${user.displayName} on TradingBook\n${AppConfig.profileUrl(user.id)}',
        ));
      case 'report':
        await showReportSheet(context,
            target: ReportTarget.user, targetId: user.id);
      case 'block':
        final ok = await confirmDialog(
          context,
          title: 'Block ${user.displayName}?',
          message: 'They won\'t be able to follow you or see your posts, and '
              'you won\'t see theirs. You can unblock them in Settings.',
          confirmLabel: 'Block',
          destructive: true,
        );
        if (!ok || !mounted) return;
        final done = await guard(context,
            () => sl<UserRepository>().block(user.id),
            success: 'Blocked');
        if (done && mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profile,
      builder: (context, snap) {
        final user = snap.data;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final cs = Theme.of(context).colorScheme;

        return Scaffold(
          backgroundColor:
              dark ? AppColors.darkBackground : AppColors.background,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            // Show user name in AppBar only when profile has loaded
            title: snap.connectionState == ConnectionState.done && user != null
                ? Text(
                    user.displayName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  )
                : null,
            actions: [
              if (user != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.white),
                  onSelected: (a) => _menu(a, user),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'share', child: Text('Share profile')),
                    PopupMenuItem(value: 'report', child: Text('Report')),
                    PopupMenuItem(value: 'block', child: Text('Block')),
                  ],
                ),
            ],
          ),
          body: switch (snap.connectionState) {
            ConnectionState.done when snap.hasError => _error(snap.error),
            ConnectionState.done when user != null => NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(
                    child: ProfileHeader(
                      key: _headerKey,
                      user: user,
                      actions: FollowButton(
                        userId: user.id,
                        onChanged: (_) =>
                            _headerKey.currentState?.reloadCounts(),
                      ),
                    ),
                  ),
                  _StickyTabBar(controller: _tab, cs: cs),
                ],
                body: TabBarView(
                  controller: _tab,
                  children: [
                    // ── Tab 0: Posts ───────────────────────────────────
                    RefreshIndicator(
                      onRefresh: () async {
                        _headerKey.currentState?.reloadCounts();
                        _posts.refresh();
                      },
                      child: PagedListView<Post>(
                        cubit: _posts,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, post, _) => PostCard(
                          key: ValueKey(post.id),
                          post: post,
                          contextType: 'profile',
                          onDeleted: () =>
                              _posts.removeWhere((p) => p.id == post.id),
                        ),
                        empty: const EmptyView(
                          icon: Icons.article_outlined,
                          title: 'No posts to show',
                          message:
                              'Posts this trader shares with you will appear here.',
                        ),
                      ),
                    ),

                    // ── Tab 1: About ───────────────────────────────────
                    _AboutTab(user: user),
                  ],
                ),
              ),
            _ => const LoadingView(),
          },
        );
      },
    );
  }

  Widget _error(Object? e) {
    if (e is ApiException && e.isNotFound) {
      return const EmptyView(
        icon: Icons.lock_outline_rounded,
        title: 'Profile unavailable',
        message: 'This account is private or no longer exists.',
      );
    }
    return ErrorView(
      error: e,
      onRetry: () => setState(
        () => _profile = sl<UserRepository>().fetchProfile(widget.userId),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About tab — interests, join date, language details
// ─────────────────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (user.interests.isEmpty && user.languages.isEmpty) {
      return const EmptyView(
        icon: Icons.person_outline_rounded,
        title: 'Nothing to show',
        message: 'This trader hasn\'t added interests or languages yet.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user.interests.isNotEmpty) ...[
          Text('Interests',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.4,
              )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final i in user.interests)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: dark ? 0.20 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    i,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: dark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (user.languages.isNotEmpty) ...[
          Text('Languages',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.4,
              )),
          const SizedBox(height: 8),
          Text(
            user.languages.join(' · ').toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky tab bar (Project A style: primary indicator, surface background)
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
            Tab(text: 'About'),
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
