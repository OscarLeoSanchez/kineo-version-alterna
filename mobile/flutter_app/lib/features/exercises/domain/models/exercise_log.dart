class ExerciseLog {
  final int? id;
  final int? userId;
  final String dayIsoDate;
  final String exerciseName;
  final String? blockTitle;
  final int setNumber;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final String? notes;
  final DateTime? loggedAt;

  const ExerciseLog({
    this.id,
    this.userId,
    required this.dayIsoDate,
    required this.exerciseName,
    this.blockTitle,
    required this.setNumber,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.notes,
    this.loggedAt,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      dayIsoDate: json['day_iso_date'] as String? ?? '',
      exerciseName: json['exercise_name'] as String? ?? '',
      blockTitle: json['block_title'] as String?,
      setNumber: json['set_number'] as int? ?? 1,
      reps: json['reps'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      durationSeconds: json['duration_seconds'] as int?,
      notes: json['notes'] as String?,
      loggedAt: json['logged_at'] != null
          ? DateTime.tryParse(json['logged_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_iso_date': dayIsoDate,
        'exercise_name': exerciseName,
        if (blockTitle != null) 'block_title': blockTitle,
        'set_number': setNumber,
        if (reps != null) 'reps': reps,
        if (weightKg != null) 'weight_kg': weightKg,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (notes != null) 'notes': notes,
      };
}
