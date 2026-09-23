import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_utils.dart';
import '../../../domain/entities/market.dart';
import '../../widgets/trading_book_app_bar.dart';
import '../cubit/markets_cubit.dart';
import '../cubit/markets_state.dart';
import '../cubit/watchlist_cubit.dart';

class MarketsPage extends StatefulWidget {
  const MarketsPage({super.key});

  @override
  State<MarketsPage> createState() => _MarketsPageState();
}

class _MarketsPageState extends State<MarketsPage> {
  /// Must stay in sync with [kMarketCategories] in markets_cubit.dart.
  final _categories = kMarketCategories;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Forwards a category change to [MarketsCubit], supplying the current
  /// watchlist set when the Watchlist tab is tapped.
  void _onCategoryTap(BuildContext context, int index) {
    final watchedSymbols = context.read<WatchlistCubit>().state.watchedSymbols;
    context.read<MarketsCubit>().setCategory(
          index,
          watchedSymbols: watchedSymbols,
        );
  }

  /// Forwards a search query to [MarketsCubit], composing it with any active
  /// watchlist filter.
  void _onSearchChanged(BuildContext context, String val) {
    final watchedSymbols = context.read<WatchlistCubit>().state.watchedSymbols;
    context.read<MarketsCubit>().setSearchQuery(
          val,
          watchedSymbols: watchedSymbols,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TradingBookAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            splashRadius: 24,
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _onSearchChanged(context, '');
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search markets...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) => _onSearchChanged(context, val),
                ),
              ),
            const SizedBox(height: 12),
            BlocBuilder<MarketsCubit, MarketsState>(
              builder: (context, state) {
                final idx = state is MarketsLoaded ? state.categoryIndex : 1;
                return _buildCategoryFilter(idx);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<MarketsCubit>().refresh(),
                child: BlocBuilder<MarketsCubit, MarketsState>(
                  builder: (context, state) {
                    if (state is MarketsLoading || state is MarketsInitial) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 6,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, __) => const _SkeletonTile(),
                      );
                    }

                    if (state is MarketsError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.message,
                                style: AppTextStyles.bodyMedium),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  context.read<MarketsCubit>().refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is MarketsLoaded) {
                      final markets = state.displayedMarkets;

                      // Empty watchlist — show a friendly prompt instead of
                      // a generic "No markets found" text.
                      if (markets.isEmpty &&
                          state.categoryIndex == kWatchlistCategoryIndex) {
                        return _buildEmptyWatchlist(context);
                      }

                      if (markets.isEmpty) {
                        return Center(
                          child: Text('No markets found.',
                              style: AppTextStyles.bodyMedium),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: markets.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final market = markets[index];
                          return _MarketTile(
                            market: market,
                            onTap: () => context.push(
                              '/markets/${Uri.encodeComponent(market.symbol)}',
                              extra: market,
                            ),
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildCategoryFilter(int categoryIndex) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.asMap().entries.map((entry) {
            final isSelected = entry.key == categoryIndex;
            // The Watchlist tab gets a special accent colour when selected
            // so it stands out from the regular category tabs.
            final isWatchlistTab = entry.key == kWatchlistCategoryIndex;
            final activeColor =
                isWatchlistTab ? AppColors.warning : AppColors.primary;

            return GestureDetector(
              onTap: () => _onCategoryTap(context, entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? activeColor : cs.outlineVariant,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: AppTextStyles.labelMedium.copyWith(
                    color:
                        isSelected ? Colors.white : cs.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Shown when the Watchlist tab is active but the user hasn't starred
  /// any markets yet.
  Widget _buildEmptyWatchlist(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_border_rounded,
                  size: 36, color: AppColors.warning),
            ),
            const SizedBox(height: 20),
            Text(
              'Your Watchlist is Empty',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the ⭐ icon on any market detail page to add it here.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loader ──────────────────────────────────────────────────────────

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 80,
                    height: 14,
                    color: cs.surfaceContainerHighest),
                const SizedBox(height: 6),
                Container(
                    width: 120,
                    height: 12,
                    color: cs.surfaceContainerHighest),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                  width: 60, height: 14, color: cs.surfaceContainerHighest),
              const SizedBox(height: 6),
              Container(
                  width: 40, height: 18, color: cs.surfaceContainerHighest),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Market tile ──────────────────────────────────────────────────────────────

class _MarketTile extends StatelessWidget {
  final Market market;
  final VoidCallback onTap;

  const _MarketTile({required this.market, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUp = market.isUp;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Center(
                child: Text(
                  market.shortName,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(market.symbol, style: AppTextStyles.titleMedium),
                  Text(market.name, style: AppTextStyles.caption),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppNumberUtils.formatPrice(market.price),
                  style: AppTextStyles.titleMedium,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isUp
                        ? AppColors.bullishLight
                        : AppColors.bearishLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: isUp ? AppColors.bullish : AppColors.bearish,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        AppNumberUtils.formatPercent(market.change),
                        style: AppTextStyles.caption.copyWith(
                          color: isUp ? AppColors.bullish : AppColors.bearish,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
