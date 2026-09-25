/// The backend's `{ items, nextCursor }` envelope. The cursor is opaque —
/// keyset on time-sorted lists, an offset on ranked ones — so it is only ever
/// passed back, never built or parsed. `nextCursor == null` is the only end
/// signal: a page may hold fewer than `limit` items and still have more.
class Paginated<T> {
  const Paginated({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return Paginated(
      items: raw.whereType<Map<String, dynamic>>().map(fromItem).toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  static Paginated<T> empty<T>() => Paginated<T>(items: const []);
}
