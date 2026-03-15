// Safe casting for dynamic JSON values.
// Avoids "type 'String' is not a subtype of 'num'" runtime errors.

/// Safely converts [value] to a [double].
/// Handles num, String, and null. Returns [fallback] when conversion fails.
double toDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

/// Safely converts [value] to an [int].
/// Handles num, String, and null. Returns [fallback] when conversion fails.
int toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  }
  return fallback;
}

/// Safely converts [value] to a [String].
/// Returns [fallback] for null; calls toString() on everything else.
String toStr(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

/// Safely converts [value] to a [List<String>].
/// Accepts a List (each element converted via [toStr]) or a single value.
/// Returns an empty list when [value] is null or not convertible.
List<String> toStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) => toStr(e)).toList();
  }
  if (value is String) return [value];
  return [];
}
