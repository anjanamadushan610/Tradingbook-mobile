import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/market.dart';
import '../../data/repositories/market_repository.dart';
import 'watchlist_cubit.dart';

class MarketDetailPage extends StatefulWidget {
  const MarketDetailPage({super.key, required this.symbol});

  final String symbol;

  @override
  State<MarketDetailPage> createState() => _MarketDetailPageState();
}

class _MarketDetailPageState extends State<MarketDetailPage> {
  final _repo = sl<MarketRepository>();
  CandleInterval _interval = CandleInterval.h1;
  MarketEnvelope<List<Quote>>? _quote;
  MarketEnvelope<List<Candle>>? _candles;
  Object? _error;
  bool _loadingCandles = true;
  int? _touched;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadQuote();
    _loadCandles();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadQuote();
      _loadCandles(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    try {
      final q = await _repo.quotes([widget.symbol]);
      if (mounted) setState(() => _quote = q);
    } catch (e) {
      if (mounted && _quote == null) setState(() => _error = e);
    }
  }

  Future<void> _loadCandles({bool silent = false}) async {
    if (!silent) setState(() => _loadingCandles = true);
    try {
      final c = await _repo.candles(
        widget.symbol,
        interval: _interval,
        limit: 90,
      );
      if (mounted) {
        setState(() {
          _candles = c;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loadingCandles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final starred = context.watch<WatchlistCubit>().state.contains(
      widget.symbol,
    );
    final quote = _quote?.items
        .where((q) => q.symbol == widget.symbol)
        .firstOrNull;
    final candles = _candles?.items ?? const <Candle>[];
    final touched = _touched != null && _touched! < candles.length
        ? candles[_touched!]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symbol.replaceFirst('USDT', '/USDT')),
        actions: [
          IconButton(
            tooltip: starred ? 'Remove from watchlist' : 'Add to watchlist',
            onPressed: () =>
                context.read<WatchlistCubit>().toggle(widget.symbol),
            icon: Icon(
              starred ? Icons.star_rounded : Icons.star_border_rounded,
              color: starred ? AppColors.warning : null,
            ),
          ),
        ],
      ),
      body: _error != null && quote == null
          ? ErrorView(
              error: _error,
              onRetry: () {
                _loadQuote();
                _loadCandles();
              },
            )
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([_loadQuote(), _loadCandles(silent: true)]);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  if (quote != null)
                    _PriceHeader(quote: quote, fetchedAt: _quote!.fetchedAt),
                  if (touched != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${Fmt.date(touched.time)} ${Fmt.clock(touched.time)}  '
                        'O ${Fmt.price(touched.open)}  H ${Fmt.price(touched.high)}  '
                        'L ${Fmt.price(touched.low)}  C ${Fmt.price(touched.close)}',
                        style: AppTextStyles.caption.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: _loadingCandles && candles.isEmpty
                        ? const LoadingView()
                        : candles.isEmpty
                        ? Center(
                            child: Text(
                              'No chart data',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                            child: _CandleChart(
                              candles: candles,
                              onTouch: (i) => setState(() => _touched = i),
                            ),
                          ),
                  ),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final i in CandleInterval.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ChoiceChip(
                              label: Text(i.label),
                              selected: i == _interval,
                              onSelected: (_) {
                                setState(() {
                                  _interval = i;
                                  _touched = null;
                                });
                                _loadCandles();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (quote != null) _Stats(quote: quote),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        Routes.search(
                          '#${widget.symbol.replaceFirst('USDT', '')}',
                        ),
                      ),
                      icon: const Icon(Icons.forum_outlined),
                      label: Text(
                        'See posts about #${widget.symbol.replaceFirst('USDT', '')}',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Prices from ${_quote?.provider ?? 'the exchange'}. The last candle is still forming. '
                      'For information only — not investment advice.',
                      style: AppTextStyles.caption.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PriceHeader extends StatelessWidget {
  const _PriceHeader({required this.quote, required this.fetchedAt});

  final Quote quote;
  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = quote.isUp ? AppColors.bullish : AppColors.bearish;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Fmt.price(quote.price),
            style: AppTextStyles.monoLarge.copyWith(
              fontSize: 30,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                quote.isUp
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color: color,
              ),
              Text(
                '${Fmt.priceChange(quote.change24h, quote.price)} (${Fmt.percent(quote.changePercent24h)}) 24h',
                style: AppTextStyles.titleSmall.copyWith(color: color),
              ),
            ],
          ),
          Text(
            'Updated ${Fmt.age(fetchedAt)}',
            style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.quote});
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget cell(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.mono.copyWith(
              color: cs.onSurface,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                cell('24h high', Fmt.price(quote.high24h)),
                cell('24h low', Fmt.price(quote.low24h)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                cell('24h volume', Fmt.volume(quote.volume24h)),
                cell('24h turnover', Fmt.volume(quote.quoteVolume24h)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CandleChart extends StatelessWidget {
  const _CandleChart({required this.candles, required this.onTouch});

  final List<Candle> candles;
  final ValueChanged<int?> onTouch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lo = candles.map((c) => c.low).reduce(min);
    final hi = candles.map((c) => c.high).reduce(max);
    final pad = (hi - lo) * 0.06;
    final width = MediaQuery.sizeOf(context).width;
    final bodyWidth = max(2.0, min(8.0, (width - 70) / candles.length * 0.6));

    return CandlestickChart(
      CandlestickChartData(
        candlestickSpots: [
          for (var i = 0; i < candles.length; i++)
            CandlestickSpot(
              x: i.toDouble(),
              open: candles[i].open,
              high: candles[i].high,
              low: candles[i].low,
              close: candles[i].close,
            ),
        ],
        minX: -1,
        maxX: candles.length.toDouble(),
        minY: lo - pad,
        maxY: hi + pad,
        candlestickPainter: DefaultCandlestickPainter(
          candlestickStyleProvider: (spot, _) {
            final c = spot.isUp ? AppColors.bullish : AppColors.bearish;
            return CandlestickStyle(
              lineColor: c,
              lineWidth: 1,
              bodyStrokeColor: c,
              bodyStrokeWidth: 0,
              bodyFillColor: c,
              bodyWidth: bodyWidth,
              bodyRadius: 1,
            );
          },
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: cs.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 0.6,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (value, meta) =>
                  value == meta.min || value == meta.max
                  ? const SizedBox.shrink()
                  : SideTitleWidget(
                      meta: meta,
                      child: Text(
                        Fmt.axis(value),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 9,
                          color: cs.onSurfaceVariant,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                    ),
            ),
          ),
        ),
        candlestickTouchData: CandlestickTouchData(
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions) {
              onTouch(null);
              return;
            }
            onTouch(response?.touchedSpot?.spotIndex);
          },
        ),
      ),
    );
  }
}
