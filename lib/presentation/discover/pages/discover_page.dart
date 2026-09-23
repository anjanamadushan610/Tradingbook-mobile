import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_utils.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/trading_book_app_bar.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TradingBookAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
            splashRadius: 24,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTrendingMarkets(context)),
            SliverToBoxAdapter(child: _buildPopularTraders(context)),
            SliverToBoxAdapter(child: _buildTrendingDiscussions(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingMarkets(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final markets = [
      ('BTC/USD', 'Bitcoin', 64230.50, 2.4),
      ('ETH/USD', 'Ethereum', 3450.20, -1.2),
      ('XAU/USD', 'Gold', 2345.80, 0.85),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trending Markets', style: AppTextStyles.headlineMedium),
              Text('View All →',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: markets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final (symbol, name, price, change) = markets[i];
                return Container(
                  width: 150,
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
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                symbol.split('/')[0].substring(0, 3),
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary, fontSize: 9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(symbol, style: AppTextStyles.titleSmall),
                                Text(name, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '\$${AppNumberUtils.formatPrice(price)}',
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        AppNumberUtils.formatPercent(change),
                        style: AppTextStyles.caption.copyWith(
                          color: change >= 0 ? AppColors.bullish : AppColors.bearish,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTraders(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final traders = [
      ('Alex Mercer', '@alextrades', '68%', null, false),
      ('Sarah Lin', '@lin_invest', '72%', null, true),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popular Traders', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          Row(
            children: traders.map((t) {
              final (name, handle, rate, avatar, following) = t;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                      right: traders.indexOf(t) < traders.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      AppAvatar(
                        name: name,
                        size: 64,
                        hasBorder: following,
                      ),
                      const SizedBox(height: 10),
                      Text(name,
                          style: AppTextStyles.titleMedium,
                          textAlign: TextAlign.center),
                      Text(handle, style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bullishLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up_rounded,
                                size: 12, color: AppColors.bullish),
                            const SizedBox(width: 4),
                            Text('$rate Win Rate',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.bullish)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: following
                                ? cs.surface
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: following
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              following ? 'Following' : 'Follow',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: following
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingDiscussions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final discussions = [
      (
        'Crypto Whales',
        '@cryptowhales_official',
        '2h ago',
        'Massive liquidations on the short side for \$BTC in the last 4 hours. Is this the squeeze we\'ve been waiting for? Looking',
        124, 45, '3.2k',
      ),
      (
        'Macro Timer',
        '@macrotimer',
        '5h ago',
        'DXY is looking incredibly weak right now. If it loses the 104 support level, we could see a massive rally across risk assets.',
        89, 22, '1.1k',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trending Discussions', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          ...discussions.map((d) {
            final (name, handle, time, text, comments, reposts, likes) = d;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                      AppAvatar(name: name, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppTextStyles.titleMedium),
                            Text(handle,
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Text(time, style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(text,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _DiscussionStat(
                          icon: Icons.chat_bubble_outline_rounded,
                          value: comments.toString()),
                      const SizedBox(width: 20),
                      _DiscussionStat(
                          icon: Icons.repeat_rounded,
                          value: reposts.toString()),
                      const SizedBox(width: 20),
                      _DiscussionStat(
                          icon: Icons.favorite_rounded,
                          value: likes,
                          color: AppColors.error),
                      const Spacer(),
                      Icon(Icons.ios_share_outlined,
                          size: 16, color: cs.onSurfaceVariant),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DiscussionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;

  const _DiscussionStat({
    required this.icon,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon,
            size: 16, color: color ?? cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(value,
            style: AppTextStyles.caption
                .copyWith(color: color ?? cs.onSurfaceVariant)),
      ],
    );
  }
}
