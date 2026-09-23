import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';

import '../widgets/profile_cover_avatar.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/interests_chips.dart';
import '../widgets/profile_menu_dropdown.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          backgroundColor: AppColors.profileFeedBackground,
          body: SafeArea(
            top: true,
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(child: _buildAppBar(context)),
                SliverToBoxAdapter(child: ProfileCoverAvatar(avatarUrl: user?.avatarUrl)),
                SliverToBoxAdapter(child: _buildProfileInfo(user)),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: ProfileStatsRow(followers: 18500, following: 1240),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: InterestsChips(
                      interests: const ['btc', 'volatility', 'macro', 'options'],
                      onEdit: () => context.push(AppRoutes.editProfile),
                    ),
                  ),
                ),
                SliverPersistentHeader(
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
                  pinned: true,
                ),
              ],
              body: Container(
                color: AppColors.profileFeedBackground,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEmptyTab(context, 'No posts yet'),
                    _buildEmptyTab(context, 'No trade ideas yet'),
                    _buildEmptyTab(context, 'No media yet'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.show_chart_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Text('Profile', style: AppTextStyles.headlineSmall),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.surface,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(Icons.search_rounded,
                  size: 20, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push(AppRoutes.notifications),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.surface,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(Icons.notifications_outlined,
                  size: 20, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          const ProfileMenuDropdown(),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(dynamic user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user?.displayName ?? 'Trader',
            style: AppTextStyles.headlineMedium,
          ),
          Text(
            '@${(user?.displayName ?? 'trader').toLowerCase().replaceAll(' ', '_')}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            user?.bio ?? 'Crypto enthusiast. Always looking for the next big volatility spike.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
