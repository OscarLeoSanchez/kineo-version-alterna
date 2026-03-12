import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../auth/data/services/auth_session_store.dart';

class BodyMetricApiService {
  const BodyMetricApiService();

  Future<void> submitMetric({
    required double weightKg,
    double? waistCm,
    double? bodyFatPercentage,
    double? hipCm,
    double? chestCm,
    double? armCm,
    double? thighCm,
    double? sleepHours,
    int? steps,
    int? restingHeartRate,
  }) async {
    final session = await AuthSessionStore().load();
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/activity/body-metrics'),
      headers: {
        'Content-Type': 'application/json',
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'weight_kg': weightKg,
        'waist_cm': waistCm,
        'body_fat_percentage': bodyFatPercentage,
        'hip_cm': hipCm,
        'chest_cm': chestCm,
        'arm_cm': armCm,
        'thigh_cm': thighCm,
        'sleep_hours': sleepHours,
        'steps': steps,
        'resting_heart_rate': restingHeartRate,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('No se pudo registrar la metrica corporal');
    }
  }
}
