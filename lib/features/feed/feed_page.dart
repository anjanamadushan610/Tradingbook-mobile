import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/paging/paged_cubit.dart';
import '../../core/paging/paged_list_view.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/post.dart';
import '../../data/repositories/engagement_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../auth/session_cubit.dart';
import '../notifications/notification_bell.dart';
import '../post/widgets/post_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late final _feed = PagedCubit<Post>(
    (cursor) => sl<PostRepository>().feed(cursor: cursor),
    keyOf: (p) => p.id,
  );
  final _scroll = ScrollController();

  @override
  void dispose() {
    _feed.close();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: GestureDetector(
          onTap: () => _scroll.hasClients
              ? _scroll.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut)
              : null,
          child: Row(
            children: [
              Image.asset('assets/images/logo.png', width: 30, height: 30),
              const SizedBox(width: 8),
              Text(
                'TradingBook',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => context.push(Routes.search()),
            icon: const Icon(Icons.search_rounded),
          ),
          const NotificationBell(),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New post',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push(Routes.compose()),
        child: const Icon(Icons.edit_rounded),
      ),
      body: PagedListView<Post>(
        cubit: _feed,
        controller: _scroll,
        onRefresh: () async => sl<EngagementRepository>().resetStats(),
        headerSlivers: const [SliverToBoxAdapter(child: _ComposePrompt())],
        itemBuilder: (context, post, _) => PostCard(
          key: ValueKey(post.id),
          post: post,
          onDeleted: () => _feed.removeWhere((p) => p.id == post.id),
        ),
        empty: EmptyView(
          icon: Icons.dynamic_feed_rounded,
          title: 'Your feed is quiet',
          message: 'Follow traders, pages and groups to fill it with setups and ideas.',
          actionLabel: 'Discover traders',
          onAction: () => context.go(Routes.discover),
        ),
      ),
    );
  }
}

class _ComposePrompt extends StatelessWidget {
  const _ComposePrompt();

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionCubit s) => s.state.userOrNull);
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          AppAvatar(url: user?.avatarUrl, name: user?.displayName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => context.push(Routes.compose()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: dark ? AppColors.darkCardBorder : AppColors.cardBorder),
                ),
                child: Text(
                  'Share a setup or market idea…',
                  style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Add photos',
            onPressed: () => context.push(Routes.compose()),
            icon: const Icon(Icons.image_outlined, color: AppColors.bullish),
          ),
        ],
      ),
    );
  }
}
