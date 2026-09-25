import 'package:flutter_test/flutter_test.dart';
import 'package:trading_book/core/network/api_exception.dart';
import 'package:trading_book/core/network/paginated.dart';
import 'package:trading_book/core/paging/paged_cubit.dart';

void main() {
  test('loads, pages with the returned cursor, and stops at null', () async {
    final seen = <String?>[];
    final cubit = PagedCubit<int>((cursor) async {
      seen.add(cursor);
      return cursor == null
          ? const Paginated(items: [1, 2], nextCursor: 'c1')
          : const Paginated(items: [3]);
    });
    await cubit.load();
    expect(cubit.state.items, [1, 2]);
    expect(cubit.state.hasMore, isTrue);
    await cubit.loadMore();
    expect(cubit.state.items, [1, 2, 3]);
    expect(cubit.state.hasMore, isFalse);
    await cubit.loadMore(); // no-op at the end
    expect(seen, [null, 'c1']);
  });

  test('de-duplicates by key (ranked lists can repeat across refresh)', () async {
    final cubit = PagedCubit<int>(
      (cursor) async => cursor == null
          ? const Paginated(items: [1, 2], nextCursor: 'x')
          : const Paginated(items: [2, 3]),
      keyOf: (i) => i,
    );
    await cubit.load();
    await cubit.loadMore();
    expect(cubit.state.items, [1, 2, 3]);
  });

  test('a failed next page keeps items and flags a retry', () async {
    var calls = 0;
    final cubit = PagedCubit<int>((cursor) async {
      calls++;
      if (cursor != null) throw ApiException.network;
      return const Paginated(items: [1], nextCursor: 'n');
    });
    await cubit.load();
    await cubit.loadMore();
    expect(cubit.state.items, [1]);
    expect(cubit.state.loadMoreFailed, isTrue);
    expect(calls, 2);
  });

  test('first-page failure surfaces as an error state', () async {
    final cubit = PagedCubit<int>((_) async => throw ApiException.network);
    await cubit.load();
    expect(cubit.state.status, PagedStatus.error);
  });
}
