import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../auth/data/services/auth_session_store.dart';

class BodyMetricApiService {
  const BodyMetricApiService();

  Future<void> submitMetric({
    required double weightKg,
    double? waistCm,
    double? bodyFatPct,
    double? hipsCm,
    double? chestCm,
    double? armCm,
    double? thighCm,
    double? muscleMassKg,
    double? sleepHours,
    int? energyLevel,
    int? moodScore,
    int? steps,
    int? restingHeartRate,
    String? notes,
  }) async {
    final session = await AuthSessionStore().load();
    final Map<String, dynamic> payload = {
      'weight_kg': weightKg,
    };
    if (waistCm != null) payload['waist_cm'] = waistCm;
    if (bodyFatPct != null) payload['body_fat_pct'] = bodyFatPct;
    if (hipsCm != null) payload['hips_cm'] = hipsCm;
    if (chestCm != null) payload['chest_cm'] = chestCm;
    if (armCm != null) payload['arm_cm'] = armCm;
    if (thighCm != null) payload['thigh_cm'] = thighCm;
    if (muscleMassKg != null) payload['muscle_mass_kg'] = muscleMassKg;
    if (sleepHours != null) payload['sleep_hours'] = sleepHours;
    if (energyLevel != null) payload['energy_level'] = energyLevel;
    if (moodScore != null) payload['mood_score'] = moodScore;
    if (steps != null) payload['steps'] = steps;
    if (restingHeartRate != null) payload['resting_heart_rate'] = restingHeartRate;
    if (notes != null && notes.isNotEmpty) payload['notes'] = notes;
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/activity/body-metrics'),
      headers: {
        'Content-Type': 'application/json',
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo registrar la metrica corporal');
    }
  }
}
