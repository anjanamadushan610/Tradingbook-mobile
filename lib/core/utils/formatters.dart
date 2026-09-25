import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class Fmt {
  Fmt._();

  static final _compact = NumberFormat.compact();
  static final _date = DateFormat('MMM d, y');
  static final _dateShort = DateFormat('MMM d');
  static final _time = DateFormat('HH:mm');

  /// 1234 → 1.2K
  static String count(int n) => n < 1000 ? '$n' : _compact.format(n);

  /// "5m ago", falling back to a date after a week.
  static String relative(DateTime t) {
    final age = DateTime.now().difference(t);
    if (age.inDays >= 7) {
      return t.year == DateTime.now().year ? _dateShort.format(t) : _date.format(t);
    }
    return timeago.format(t, locale: 'en_short') == 'now'
        ? 'now'
        : timeago.format(t, locale: 'en_short');
  }

  static String date(DateTime t) => _date.format(t);

  static String clock(DateTime t) => _time.format(t);

  /// Prices: more decimals for small numbers so sub-cent coins stay readable.
  static String price(double v) {
    final abs = v.abs();
    final digits = abs >= 1000
        ? 2
        : abs >= 1
            ? 4
            : abs >= 0.01
                ? 5
                : 8;
    return NumberFormat.currency(symbol: '', decimalDigits: digits).format(v).trim();
  }

  /// A delta shown in the precision of the price it belongs to (BTC's
  /// +322.60, not +322.6000).
  static String priceChange(double delta, double reference) {
    final digits = _digitsFor(reference.abs());
    final f = NumberFormat.currency(symbol: '', decimalDigits: digits).format(delta.abs()).trim();
    return '${delta >= 0 ? '+' : '-'}$f';
  }

  /// Chart axis labels: short enough to never wrap.
  static String axis(double v) {
    final abs = v.abs();
    if (abs >= 10000) return NumberFormat('#,##0').format(v);
    if (abs >= 100) return v.toStringAsFixed(1);
    if (abs >= 1) return v.toStringAsFixed(3);
    return v.toStringAsPrecision(3);
  }

  static int _digitsFor(double abs) => abs >= 1000
      ? 2
      : abs >= 1
          ? 4
          : abs >= 0.01
              ? 5
              : 8;

  static String percent(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';

  static String signed(double v) =>
      '${v >= 0 ? '+' : '-'}${price(v.abs())}';

  static String volume(double v) => _compact.format(v);

  /// "Updated 12s ago" — market data must always show its age.
  static String age(DateTime fetchedAt) {
    final s = DateTime.now().difference(fetchedAt).inSeconds;
    if (s < 5) return 'just now';
    if (s < 60) return '${s}s ago';
    if (s < 3600) return '${s ~/ 60}m ago';
    return relative(fetchedAt);
  }
}
