import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String timeAgo(int epochMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  static String formatDate(int epochMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatJoinDate(int epochMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return 'Joined ${DateFormat('MMM yyyy').format(date)}';
  }
}

class AppNumberUtils {
  AppNumberUtils._();

  static String compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }

  static String compactDouble(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  static String formatPrice(double price) {
    final formatter = NumberFormat('#,##0.##');
    return formatter.format(price);
  }

  static String formatPriceWithPrefix(double price, {bool dollar = true}) {
    return '${dollar ? '\$' : ''}${formatPrice(price)}';
  }

  static String formatPercent(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(2)}%';
  }
}
