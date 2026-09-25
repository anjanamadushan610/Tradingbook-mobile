import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
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

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<UserProfile> _profile = sl<UserRepository>().fetchProfile(widget.userId);
  late final _posts = PagedCubit<Post>(
    (cursor) => sl<PostRepository>().byAuthor(widget.userId, cursor: cursor),
    keyOf: (p) => p.id,
  );
  final _headerKey = GlobalKey<ProfileHeaderState>();

  @override
  void initState() {
    super.initState();
    // Your own profile lives in the Profile tab.
    final me = context.read<SessionCubit>().user;
    if (me?.id == widget.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.me);
      });
    }
  }

  @override
  void dispose() {
    _posts.close();
    super.dispose();
  }

  Future<void> _menu(String action, UserProfile user) async {
    switch (action) {
      case 'share':
        await SharePlus.instance.share(ShareParams(
          text: '${user.displayName} on TradingBook\n${AppConfig.profileUrl(user.id)}',
        ));
      case 'report':
        await showReportSheet(context, target: ReportTarget.user, targetId: user.id);
      case 'block':
        final ok = await confirmDialog(
          context,
          title: 'Block ${user.displayName}?',
          message: 'They won\'t be able to follow you or see your posts, and you won\'t see theirs. '
              'You can unblock them in Settings.',
          confirmLabel: 'Block',
          destructive: true,
        );
        if (!ok || !mounted) return;
        final done = await guard(context, () => sl<UserRepository>().block(user.id), success: 'Blocked');
        if (done && mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profile,
      builder: (context, snap) {
        final user = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(user?.displayName ?? ''),
            actions: [
              if (user != null)
                PopupMenuButton<String>(
                  onSelected: (a) => _menu(a, user),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'share', child: Text('Share profile')),
                    PopupMenuItem(value: 'report', child: Text('Report')),
                    PopupMenuItem(value: 'block', child: Text('Block')),
                  ],
                ),
            ],
          ),
          body: switch (snap.connectionState) {
            ConnectionState.done when snap.hasError => _error(snap.error),
            ConnectionState.done => PagedListView<Post>(
                cubit: _posts,
                onRefresh: () async => _headerKey.currentState?.reloadCounts(),
                headerSlivers: [
                  SliverToBoxAdapter(
                    child: ProfileHeader(
                      key: _headerKey,
                      user: user!,
                      actions: FollowButton(
                        userId: user.id,
                        onChanged: (_) => _headerKey.currentState?.reloadCounts(),
                      ),
                    ),
                  ),
                ],
                itemBuilder: (context, post, _) => PostCard(
                  key: ValueKey(post.id),
                  post: post,
                  contextType: 'profile',
                  onDeleted: () => _posts.removeWhere((p) => p.id == post.id),
                ),
                empty: const EmptyView(
                  icon: Icons.article_outlined,
                  title: 'No posts to show',
                  message: 'Posts this trader shares with you will appear here.',
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
      onRetry: () => setState(() => _profile = sl<UserRepository>().fetchProfile(widget.userId)),
    );
  }
}
