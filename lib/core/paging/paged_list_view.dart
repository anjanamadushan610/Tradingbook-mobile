import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/api_exception.dart';
import '../widgets/feedback.dart';
import '../widgets/state_views.dart';
import 'paged_cubit.dart';

/// Infinite, pull-to-refreshable list over a [PagedCubit]: skeleton on first
/// load, error-with-retry, empty state, "loading more" footer and an inline
/// retry when a later page fails.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    required this.empty,
    this.headerSlivers = const [],
    this.separated = false,
    this.padding = const EdgeInsets.only(bottom: 96),
    this.skeletonHeight = 180,
    this.controller,
    this.onRefresh,
  });

  final PagedCubit<T> cubit;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget empty;
  final List<Widget> headerSlivers;
  final bool separated;
  final EdgeInsets padding;
  final double skeletonHeight;
  final ScrollController? controller;

  /// Extra work on pull-to-refresh (e.g. resetting cached engagement).
  final Future<void> Function()? onRefresh;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  @override
  void initState() {
    super.initState();
    if (widget.cubit.state.status == PagedStatus.initial) widget.cubit.load();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.pixels > n.metrics.maxScrollExtent - 800) {
      widget.cubit.loadMore();
    }
    return false;
  }

  Future<void> _refresh() async {
    try {
      await widget.onRefresh?.call();
      await widget.cubit.refresh();
    } on ApiException catch (e) {
      if (mounted) Toast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagedCubit<T>, PagedState<T>>(
      bloc: widget.cubit,
      builder: (context, state) {
        final slivers = <Widget>[...widget.headerSlivers];
        if (state.items.isEmpty) {
          switch (state.status) {
            case PagedStatus.initial:
            case PagedStatus.loading:
              slivers.add(SkeletonList(sliver: true, itemHeight: widget.skeletonHeight));
            case PagedStatus.error:
              slivers.add(SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(error: state.error, onRetry: widget.cubit.load),
              ));
            case PagedStatus.ready:
              slivers.add(SliverFillRemaining(hasScrollBody: false, child: widget.empty));
          }
        } else {
          slivers.add(SliverList.builder(
            itemCount: state.items.length,
            itemBuilder: (context, i) {
              final child = widget.itemBuilder(context, state.items[i], i);
              if (!widget.separated || i == state.items.length - 1) return child;
              return Column(children: [child, const Divider(height: 1, indent: 72)]);
            },
          ));
          slivers.add(SliverToBoxAdapter(child: _footer(state)));
        }
        return NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: widget.controller,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                ...slivers,
                SliverPadding(padding: widget.padding),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _footer(PagedState<T> state) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (state.loadMoreFailed) {
      return Center(
        child: TextButton.icon(
          onPressed: widget.cubit.loadMore,
          icon: const Icon(Icons.refresh),
          label: const Text('Couldn\'t load more. Retry'),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
