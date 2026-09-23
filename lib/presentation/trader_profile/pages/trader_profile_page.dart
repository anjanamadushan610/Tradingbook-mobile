import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

import '../../widgets/app_avatar.dart';

class TraderProfilePage extends StatefulWidget {
  final String userId;
  const TraderProfilePage({super.key, required this.userId});

  @override
  State<TraderProfilePage> createState() => _TraderProfilePageState();
}

class _TraderProfilePageState extends State<TraderProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _buildCoverAndActions(context)),
            SliverToBoxAdapter(child: _buildProfileInfo()),
            SliverToBoxAdapter(child: _buildStats()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  labelStyle: AppTextStyles.titleSmall,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Trade Ideas'),
                    Tab(text: 'Media'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(),
              _buildEmptyTab('No trade ideas'),
              _buildEmptyTab('No media'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverAndActions(BuildContext context) {
    return Stack(
      children: [
        // Cover
        Container(
          height: 130,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
          child: const Center(
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.show_chart_rounded,
                  size: 80, color: Colors.white),
            ),
          ),
        ),
        // Back button
        Positioned(
          top: 12,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Colors.white),
            ),
          ),
        ),
        // Search button
        Positioned(
          top: 12,
          right: 16,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hub_outlined, size: 18, color: Colors.white),
          ),
        ),
        // Avatar + action buttons
        const Positioned(
          bottom: -32,
          left: 16,
          child: AppAvatar(name: 'Elena Rostova', size: 72, hasBorder: true),
        ),
        Positioned(
          bottom: -20,
          right: 16,
          child: Row(
            children: [
              _ActionBtn(
                label: 'Message',
                isOutlined: true,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: _isFollowing ? 'Following' : 'Follow',
                isOutlined: _isFollowing,
                onTap: () => setState(() => _isFollowing = !_isFollowing),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 46, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Elena Rostova', style: AppTextStyles.headlineMedium),
          Text('@elena_trades', style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(
            'Macro analyst & quantitative strategist. Focused on FX and global indices. Not financial advice.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('London, UK', style: AppTextStyles.caption),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('Joined Jan 2021', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          _StatTap(value: '1,240', label: 'Following', onTap: () {}),
          const SizedBox(width: 24),
          _StatTap(value: '18.5k', label: 'Followers', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    final cs = Theme.of(context).colorScheme;
    // Mock single post
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                const AppAvatar(name: 'Elena Rostova', size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Elena Rostova', style: AppTextStyles.titleSmall),
                      Text('2h ago', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('\$EURUSD',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Breaking out of the descending channel on the 4H timeframe. DXY showing weakness. Looking for a retest of support before continuing higher.',
            ),
            const SizedBox(height: 12),
            // Mini trade levels
            ...[
              ('Target', '1.0950', AppColors.primary),
              ('Entry', '1.0820', AppColors.textSecondary),
              ('Stop', '1.0780', AppColors.error),
            ].map((item) {
              final (label, value, color) = item;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(label, style: AppTextStyles.bodySmall),
                    const Spacer(),
                    Text(value,
                        style: AppTextStyles.titleSmall.copyWith(color: color)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 140,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.candlestick_chart_outlined,
                      size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Builder(builder: (ctx) => Icon(Icons.favorite_border_rounded,
                    size: 16, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                const SizedBox(width: 4),
                Builder(builder: (ctx) => Text('245', style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurfaceVariant))),
                const SizedBox(width: 16),
                Builder(builder: (ctx) => Icon(Icons.chat_bubble_outline_rounded,
                    size: 16, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                const SizedBox(width: 4),
                Builder(builder: (ctx) => Text('42', style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurfaceVariant))),
                const SizedBox(width: 16),
                Builder(builder: (ctx) => Icon(Icons.repeat_rounded,
                    size: 16, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                const SizedBox(width: 4),
                Builder(builder: (ctx) => Text('12', style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurfaceVariant))),
                const Spacer(),
                Builder(builder: (ctx) => Icon(Icons.ios_share_outlined,
                    size: 16, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTab(String message) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final bool isOutlined;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.isOutlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isOutlined ? cs.surface : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOutlined ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isOutlined ? AppColors.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _StatTap extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatTap({
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(value, style: AppTextStyles.titleMedium),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_SliverTabBarDelegate old) => false;
}
