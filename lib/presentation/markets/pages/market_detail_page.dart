import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_utils.dart';
import '../../widgets/app_button.dart';
import '../cubit/watchlist_cubit.dart';
import '../cubit/watchlist_state.dart';

class MarketDetailPage extends StatefulWidget {
  final String symbol;
  const MarketDetailPage({super.key, required this.symbol});

  @override
  State<MarketDetailPage> createState() => _MarketDetailPageState();
}

class _MarketDetailPageState extends State<MarketDetailPage> {
  int _selectedRange = 0;
  final _ranges = ['1D', '1W', '1M', '1Y', 'ALL'];
  int _sentimentUp = 74; // % bullish (mock)

  // ── Mock data used for the share sheet text ──────────────────────────────
  static const double _price = 2345.80;
  static const double _change = 0.85;

  // Generate mock chart data
  List<FlSpot> _generateSpots() {
    final base = [
      2320.0, 2330.0, 2325.0, 2340.0, 2335.0, 2338.0, 2345.8,
    ];
    return base.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
  }

  // ── Share ─────────────────────────────────────────────────────────────────
  void _onShare() {
    const changeSign = _change >= 0 ? '+' : '';
    // ignore: deprecated_member_use
    Share.share(
      'Check out ${widget.symbol} trading at '
      '\$${AppNumberUtils.formatPrice(_price)} '
      '($changeSign${_change.toStringAsFixed(2)}%) on TradingBook App! 📈',
      subject: '${widget.symbol} on TradingBook',
    );
  }

  // ── Coming-soon SnackBar ─────────────────────────────────────────────────
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          content: Row(
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 10),
              Text(
                'Feature coming soon!',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // WatchlistCubit is provided globally in main.dart — no local BlocProvider
    // needed. State persists across navigation events.
    return Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar(context)),
              SliverToBoxAdapter(
                  child: _buildPriceCard(true, _price, _change, 19.80)),
              SliverToBoxAdapter(child: _buildChart()),
              SliverToBoxAdapter(child: _buildSentiment()),
              SliverToBoxAdapter(child: _buildActions()),
              SliverToBoxAdapter(child: _buildCommunityInsights()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      );
  }

  Widget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(widget.symbol, style: AppTextStyles.headlineSmall),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('COMMODITY',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
              Text('Gold / US Dollar', style: AppTextStyles.caption),
            ],
          ),
          const Spacer(),

          // ── Favourite (Watchlist) toggle ──────────────────────────────────
          BlocSelector<WatchlistCubit, WatchlistState, bool>(
            selector: (state) => state.isWatched(widget.symbol),
            builder: (context, isWatched) {
              return GestureDetector(
                onTap: () =>
                    context.read<WatchlistCubit>().toggleWatchlist(widget.symbol),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    isWatched ? Icons.star_rounded : Icons.star_border_rounded,
                    key: ValueKey(isWatched),
                    color: isWatched ? AppColors.warning : cs.onSurfaceVariant,
                    size: 22,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          // ── Share ─────────────────────────────────────────────────────────
          GestureDetector(
            onTap: _onShare,
            child: Icon(Icons.ios_share_outlined,
                color: cs.onSurfaceVariant, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(
      bool isUp, double price, double change, double changeAbs) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SPOT PRICE',
                style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '\$${AppNumberUtils.formatPrice(price)}',
                    style: AppTextStyles.monoLarge,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text('24h H', style: AppTextStyles.labelSmall),
                        const SizedBox(width: 6),
                        Text('\$2,352.10',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('24h L', style: AppTextStyles.labelSmall),
                        const SizedBox(width: 6),
                        Text('\$2,328.40',
                             style: AppTextStyles.labelMedium
                                .copyWith(color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bullishLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          size: 14, color: AppColors.bullish),
                      const SizedBox(width: 4),
                      Text(
                        '+${change.toStringAsFixed(2)}% (+\$${changeAbs.toStringAsFixed(2)})',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.bullish),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('Today', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            // Range selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _ranges.asMap().entries.map((entry) {
                final isSelected = entry.key == _selectedRange;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRange = entry.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.value,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected
                            ? Colors.white
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Price label
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('\$2,345.80',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 4),

            // Line Chart
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateSpots(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentiment() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Community Sentiment',
                    style: AppTextStyles.titleMedium),
                const Spacer(),
                Text('1,420 votes', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    Expanded(
                      flex: _sentimentUp,
                      child: Container(color: AppColors.bullish),
                    ),
                    Expanded(
                      flex: 100 - _sentimentUp,
                      child: Container(color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.bullish, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('$_sentimentUp% Bullish',
                        style: AppTextStyles.titleSmall
                            .copyWith(color: AppColors.bullish)),
                  ],
                ),
                Row(
                  children: [
                    Text('${100 - _sentimentUp}% Bearish',
                        style: AppTextStyles.titleSmall
                            .copyWith(color: AppColors.warning)),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.warning, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Vote Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _sentimentUp = (_sentimentUp + 1).clamp(0, 100)),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: const Center(child: Icon(Icons.arrow_upward_rounded)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _sentimentUp = (_sentimentUp - 1).clamp(0, 100)),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: const Center(
                          child: Icon(Icons.arrow_downward_rounded)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Where is ${widget.symbol} heading next? Tap to cast your sentiment vote',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Discuss',
              isOutlined: true,
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () => _showComingSoon(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
              label: 'Share Trade Idea',
              icon: Icons.bar_chart_rounded,
              onTap: () => _showComingSoon(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityInsights() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Community Insights', style: AppTextStyles.headlineMedium),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Hot',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.error)),
              ),
              const Spacer(),
              Text('Filter ≡',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          // Placeholder insight cards
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Center(
              child: Text('Community posts loading…',
                  style: AppTextStyles.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}
