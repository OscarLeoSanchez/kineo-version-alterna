// Validation helpers

/// Returns an error message if [value] is null or empty, otherwise null.
String? validateRequired(String? value, {String fieldName = 'Este campo'}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName es requerido';
  }
  return null;
}

/// Returns an error message if [value] is not a valid number or is outside
/// the optional [min]/[max] range, otherwise null.
String? validateNumber(
  String? value, {
  double? min,
  double? max,
  String fieldName = 'El valor',
}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName es requerido';
  }
  final parsed = double.tryParse(value.trim());
  if (parsed == null) {
    return '$fieldName debe ser un número válido';
  }
  if (min != null && parsed < min) {
    return '$fieldName debe ser mayor o igual a $min';
  }
  if (max != null && parsed > max) {
    return '$fieldName debe ser menor o igual a $max';
  }
  return null;
}

/// Returns true if [value] can be parsed as a positive number greater than 0.
bool isPositiveNumber(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  final parsed = double.tryParse(value.trim());
  return parsed != null && parsed > 0;
}
