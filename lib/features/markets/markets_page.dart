import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/routes.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/market.dart';
import '../../data/repositories/market_repository.dart';
import '../notifications/notification_bell.dart';
import 'watchlist_cubit.dart';

/// Live spot crypto quotes: your watchlist plus every listed instrument.
/// Refreshes every 30s (the server's cache window) while on screen, always
/// shows how old the numbers are, and says so plainly when prices are down.
class MarketsPage extends StatefulWidget {
  const MarketsPage({super.key});

  @override
  State<MarketsPage> createState() => _MarketsPageState();
}

class _MarketsPageState extends State<MarketsPage> with WidgetsBindingObserver {
  final _repo = sl<MarketRepository>();
  MarketEnvelope<List<Quote>>? _quotes;
  List<MarketSymbol> _symbols = const [];
  Object? _error;
  Timer? _timer;
  Timer? _ageTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
    _ageTicker = Timer.periodic(const Duration(seconds: 5), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _ageTicker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final watchlist = context.read<WatchlistCubit>().state;
    try {
      if (_symbols.isEmpty) _symbols = await _repo.symbols();
      final wanted = {
        ...watchlist,
        ..._symbols.map((s) => s.symbol),
      }.take(25).toList();
      final q = await _repo.quotes(wanted);
      if (mounted) {
        setState(() {
          _quotes = q;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistCubit>().state;
    final cs = Theme.of(context).colorScheme;
    final disabled = _error is ApiException && (_error as ApiException).statusCode == 503;

    Widget body;
    if (_quotes == null && _error == null) {
      body = const LoadingView();
    } else if (disabled) {
      body = const EmptyView(
        icon: Icons.candlestick_chart_outlined,
        title: 'Markets unavailable',
        message: 'Market data isn\'t available right now.',
      );
    } else if (_quotes == null) {
      body = ErrorView(error: _error, onRetry: _load);
    } else {
      final byId = {for (final q in _quotes!.items) q.symbol: q};
      final labels = {for (final s in _symbols) s.symbol: s};
      final watched = watchlist.where(byId.containsKey).toList();
      final others = _symbols.map((s) => s.symbol).where((s) => !watchlist.contains(s) && byId.containsKey(s)).toList();
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _StatusBar(fetchedAt: _quotes!.fetchedAt, provider: _quotes!.provider, stale: _error != null),
            if (watched.isNotEmpty) ...[
              const _Section('Watchlist'),
              for (final s in watched) _QuoteRow(quote: byId[s]!, label: labels[s]?.label, starred: true),
            ],
            if (others.isNotEmpty) ...[
              const _Section('All markets'),
              for (final s in others) _QuoteRow(quote: byId[s]!, label: labels[s]?.label, starred: false),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Spot crypto prices, passed through from the exchange. For information only — '
                'not investment advice.',
                style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Markets'),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: body,
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.fetchedAt, required this.provider, required this.stale});

  final DateTime fetchedAt;
  final String provider;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: stale ? AppColors.warning.withValues(alpha: 0.12) : null,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Icon(
            stale ? Icons.warning_amber_rounded : Icons.circle,
            size: stale ? 16 : 8,
            color: stale ? AppColors.warning : AppColors.bullish,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stale
                  ? 'Couldn\'t refresh — showing prices from ${Fmt.age(fetchedAt)}'
                  : 'Updated ${Fmt.age(fetchedAt)}${provider.isEmpty ? '' : ' · via ${provider[0].toUpperCase()}${provider.substring(1)}'}',
              style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(text, style: AppTextStyles.headlineSmall.copyWith(color: Theme.of(context).colorScheme.onSurface)),
      );
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.quote, required this.label, required this.starred});

  final Quote quote;
  final String? label;
  final bool starred;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = quote.isUp ? AppColors.bullish : AppColors.bearish;
    final base = (label ?? quote.symbol).split('/').first;
    return InkWell(
      onTap: () => context.push(Routes.market(quote.symbol)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
        child: Row(
          children: [
            IconButton(
              tooltip: starred ? 'Remove from watchlist' : 'Add to watchlist',
              onPressed: () => context.read<WatchlistCubit>().toggle(quote.symbol),
              icon: Icon(
                starred ? Icons.star_rounded : Icons.star_border_rounded,
                color: starred ? AppColors.warning : cs.onSurfaceVariant,
              ),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                base.length > 4 ? base.substring(0, 4) : base,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label ?? quote.symbol, style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
                  Text(
                    'Vol ${Fmt.volume(quote.quoteVolume24h)}',
                    style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Fmt.price(quote.price), style: AppTextStyles.mono.copyWith(color: cs.onSurface)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    Fmt.percent(quote.changePercent24h),
                    style: AppTextStyles.labelMedium.copyWith(color: color, letterSpacing: 0),
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
