import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/api_exception.dart';
import '../network/paginated.dart';

enum PagedStatus { initial, loading, ready, error }

class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.nextCursor,
    this.status = PagedStatus.initial,
    this.loadingMore = false,
    this.error,
    this.loadMoreFailed = false,
  });

  final List<T> items;
  final String? nextCursor;
  final PagedStatus status;
  final bool loadingMore;
  final Object? error;
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;
  bool get isEmpty => status == PagedStatus.ready && items.isEmpty;

  PagedState<T> copyWith({
    List<T>? items,
    String? Function()? nextCursor,
    PagedStatus? status,
    bool? loadingMore,
    Object? Function()? error,
    bool? loadMoreFailed,
  }) =>
      PagedState<T>(
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        status: status ?? this.status,
        loadingMore: loadingMore ?? this.loadingMore,
        error: error != null ? error() : this.error,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );
}

/// Every infinite list in the app (feed, profiles, comments, members,
/// notifications…) is this cubit over a `fetch(cursor)` function. Cursor
/// semantics stay opaque: whatever `nextCursor` came back is passed back.
class PagedCubit<T> extends Cubit<PagedState<T>> {
  PagedCubit(this._fetch, {this.keyOf}) : super(PagedState<T>());

  final Future<Paginated<T>> Function(String? cursor) _fetch;

  /// Optional identity for de-duplication: ranked (offset-cursor) lists can
  /// repeat an item across a cache refresh mid-scroll.
  final Object Function(T item)? keyOf;

  int _generation = 0;

  Future<void> load() async {
    if (state.status == PagedStatus.loading) return;
    final gen = ++_generation;
    emit(PagedState<T>(status: PagedStatus.loading, items: state.items));
    try {
      final page = await _fetch(null);
      if (isClosed || gen != _generation) return;
      emit(PagedState<T>(
        items: _dedupe(page.items),
        nextCursor: page.nextCursor,
        status: PagedStatus.ready,
      ));
    } catch (e) {
      if (isClosed || gen != _generation) return;
      emit(PagedState<T>(status: PagedStatus.error, error: e, items: state.items));
    }
  }

  /// Pull-to-refresh: keeps current items visible until the new page lands.
  Future<void> refresh() async {
    final gen = ++_generation;
    try {
      final page = await _fetch(null);
      if (isClosed || gen != _generation) return;
      emit(PagedState<T>(
        items: _dedupe(page.items),
        nextCursor: page.nextCursor,
        status: PagedStatus.ready,
      ));
    } catch (e) {
      if (isClosed || gen != _generation) return;
      if (state.items.isEmpty) {
        emit(PagedState<T>(status: PagedStatus.error, error: e));
      } else {
        rethrow;
      }
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore || state.status != PagedStatus.ready) {
      return;
    }
    final gen = _generation;
    emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final page = await _fetch(cursor);
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(
        items: _dedupe([...state.items, ...page.items]),
        nextCursor: () => page.nextCursor,
        loadingMore: false,
      ));
    } on ApiException {
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  void prepend(T item) => emit(state.copyWith(items: [item, ...state.items]));

  void append(T item) => emit(state.copyWith(items: [...state.items, item]));

  void replaceWhere(bool Function(T) test, T Function(T) update) {
    emit(state.copyWith(
      items: [for (final i in state.items) test(i) ? update(i) : i],
    ));
  }

  void removeWhere(bool Function(T) test) {
    emit(state.copyWith(items: state.items.where((i) => !test(i)).toList()));
  }

  List<T> _dedupe(List<T> items) {
    final key = keyOf;
    if (key == null) return items;
    final seen = <Object>{};
    return [for (final i in items) if (seen.add(key(i))) i];
  }
}
