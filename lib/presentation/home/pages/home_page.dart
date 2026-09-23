import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/repositories/feed_repository.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../widgets/app_avatar.dart';
import '../../profile/models/profile_models.dart';
import '../../profile/widgets/post_card.dart';
import '../../widgets/trading_book_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
  int _filterIndex = 0;
  final _filters = ['All Feed', 'Trade Setups', 'Macro Analysis', 'Verified'];

  List<ValueNotifier<PostModel>> _posts = [];
  bool _isLoadingFeed = true;
  String? _feedError;
  String? _nextCursor;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _fetchFeed() async {
    try {
      final result = await context.read<FeedRepository>().getFeed(limit: 20);
      final parsed = result.items.map((post) {
        return ValueNotifier(PostModel(
          id: post.id,
          authorName: post.authorName ?? 'Unknown',
          authorUsername: 'user', // Need a fallback or from API
          date: DateTime.fromMillisecondsSinceEpoch(post.createdAt * 1000)
              .toLocal()
              .toString()
              .substring(0, 10),
          content: post.caption,
          authorAvatarUrl: post.authorAvatarUrl,
          mediaUrls: post.mediaRefs,
          likes: post.likeCount,
          comments: post.commentCount,
          isLiked: post.hasLiked,
          shares: 0,
          status: post.status.name,
        ));
      }).toList();

      if (!mounted) return;
      setState(() {
        _posts = parsed;
        _nextCursor = result.nextCursor;
        _isLoadingFeed = false;
        _feedError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedError = 'Error loading feed';
        _isLoadingFeed = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _nextCursor == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await context.read<FeedRepository>().getFeed(
            cursor: _nextCursor,
            limit: 20,
          );
      final parsed = result.items.map((post) {
        return ValueNotifier(PostModel(
          id: post.id,
          authorName: post.authorName ?? 'Unknown',
          authorUsername: 'user',
          date: DateTime.fromMillisecondsSinceEpoch(post.createdAt * 1000)
              .toLocal()
              .toString()
              .substring(0, 10),
          content: post.caption,
          authorAvatarUrl: post.authorAvatarUrl,
          mediaUrls: post.mediaRefs,
          likes: post.likeCount,
          comments: post.commentCount,
          isLiked: post.hasLiked,
          shares: 0,
          status: post.status.name,
        ));
      }).toList();

      if (!mounted) return;
      setState(() {
        _posts.addAll(parsed);
        _nextCursor = result.nextCursor;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _isLoadingFeed = true;
      _feedError = null;
    });
    await _fetchFeed();
  }

  Future<void> _handleLikeToggled(String postId) async {
    final index = _posts.indexWhere((p) => p.value.id == postId);
    if (index == -1) return;

    final notifier = _posts[index];
    final post = notifier.value;
    final wasLiked = post.isLiked;

    notifier.value = post.copyWith(
      isLiked: !wasLiked,
      likes: post.likes + (!wasLiked ? 1 : -1),
    );

    try {
      if (!wasLiked) {
        await context.read<PostsRepository>().likePost(postId);
      } else {
        await context.read<PostsRepository>().unlikePost(postId);
      }
    } catch (e) {
      if (!mounted) return;
      notifier.value = post; // revert
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like')),
      );
    }
  }

  Future<void> _handleBookmarkToggled(String postId) async {
    final index = _posts.indexWhere((p) => p.value.id == postId);
    if (index == -1) return;

    final notifier = _posts[index];
    final post = notifier.value;
    final wasSaved = post.isSaved;

    notifier.value = post.copyWith(isSaved: !wasSaved);

    try {
      await context.read<PostsRepository>().toggleBookmark(postId);
    } catch (e) {
      if (!mounted) return;
      notifier.value = post; // revert
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update bookmark')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;

    return Scaffold(
      appBar: TradingBookAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push(AppRoutes.notifications),
            splashRadius: 24,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: AppAvatar(
                imageUrl: user?.avatarUrl,
                name: user?.displayName,
                size: 32,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refreshFeed,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // === Ticker Strip ===
              SliverToBoxAdapter(child: _buildTickerStrip(context)),

              // === Create Post Bar ===
              SliverToBoxAdapter(
                child: _buildCreatePostBar(context, user),
              ),

              // === Feed Filter Tabs ===
              SliverToBoxAdapter(child: _buildFilterTabs(context)),

              // === Feed Content ===
              if (_isLoadingFeed)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => _ShimmerPostCard(),
                    childCount: 3,
                  ),
                )
              else if (_feedError != null)
                SliverToBoxAdapter(
                  child: _buildError(context, _feedError!),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _posts.length) {
                        return _isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.primary),
                                ),
                              )
                            : const SizedBox(height: 100);
                      }

                      final notifier = _posts[index];
                      return PostCard(
                        key: ValueKey(notifier.value.id),
                        postNotifier: notifier,
                        onDelete: () {
                          setState(() {
                            _posts.removeAt(index);
                          });
                        },
                        onLikeToggled: _handleLikeToggled,
                        onBookmarkToggled: _handleBookmarkToggled,
                      );
                    },
                    childCount: _posts.length + 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTickerStrip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tickers = [
      ('BTC/USD', '+2.4%', true),
      ('ETH/USD', '-1.1%', false),
      ('SOL/USD', '+5.1%', true),
      ('XAU/USD', '+0.8%', true),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tickers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (symbol, change, isUp) = tickers[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isUp
                  ? AppColors.bullishLight
                  : AppColors.bearishLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(symbol,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: cs.onSurface)),
                const SizedBox(width: 4),
                Text(
                  change,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isUp ? AppColors.bullish : AppColors.bearish,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreatePostBar(BuildContext context, dynamic user) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>(AppRoutes.createPost);
        if (result == true) {
          _refreshFeed();
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  imageUrl: user?.avatarUrl,
                  name: user?.displayName,
                  size: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Share market analysis or trade idea...',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CreateAction(
                    icon: Icons.show_chart_rounded, label: 'Chart'),
                _CreateAction(
                    icon: Icons.add_photo_alternate_outlined,
                    label: 'Photo'),
                _CreateAction(
                  icon: Icons.trending_up_rounded,
                  label: 'Trade Setup',
                  isActive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.asMap().entries.map((entry) {
            final isSelected = entry.key == _filterIndex;
            return GestureDetector(
              onTap: () => setState(() => _filterIndex = entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : cs.outlineVariant,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : cs.onSurfaceVariant,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Unable to load feed', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 6),
          Text(message,
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => _fetchFeed(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CreateAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _CreateAction({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: isActive ? AppColors.primary : cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isActive ? AppColors.primary : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ShimmerPostCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.outlineVariant,
      highlightColor: cs.surface,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 200,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
