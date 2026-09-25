/// Tolerant JSON readers. The backend's shapes are stable, but a missing
/// optional field must degrade to a sensible default, never a TypeError that
/// takes down a whole list.
List<String> readStringList(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];

int readInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double readDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

String readString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

String? readNullableString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

bool readBool(Object? value, [bool fallback = false]) =>
    value is bool ? value : fallback;

DateTime readTime(Object? epochMillis) =>
    DateTime.fromMillisecondsSinceEpoch(readInt(epochMillis));
