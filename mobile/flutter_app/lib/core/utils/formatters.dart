// Utility functions for formatting values throughout the app

/// Formats [totalSeconds] as "MM:SS".
String formatTime(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// Formats [date] in Spanish long form, e.g. "lunes, 10 mar".
String formatDate(DateTime date) {
  const weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  return '$weekday, ${date.day} $month';
}

/// Formats [date] in Spanish short form, e.g. "10 mar".
String formatDateShort(DateTime date) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final month = months[date.month - 1];
  return '${date.day} $month';
}

/// Formats a macro gram value with one decimal, e.g. "12.5g".
String formatMacro(double value) => '${value.toStringAsFixed(1)}g';

/// Formats a calorie value rounded to nearest integer, e.g. "350 kcal".
String formatCalories(double value) => '${value.round()} kcal';

/// Formats a weight value with one decimal, e.g. "75.0 kg".
String formatWeight(double value) => '${value.toStringAsFixed(1)} kg';
