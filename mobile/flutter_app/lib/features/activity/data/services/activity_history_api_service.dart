import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/local_sync_store.dart';
import '../../../../core/services/session_data_cache.dart';
import 'offline_activity_queue_service.dart';
import '../../../auth/data/services/auth_session_store.dart';

class ActivityHistoryApiService {
  const ActivityHistoryApiService();

  Future<Map<String, dynamic>> fetchHistory() async {
    final session = await AuthSessionStore().load();
    final cache = const LocalSyncStore();
    unawaited(const OfflineActivityQueueService().flush());
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/activity/history'),
        headers: {
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('No se pudo cargar el historial');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await cache.writeHistory(data);
      SessionDataCache.instance.history = data;
      return data;
    } catch (_) {
      final inMemory = SessionDataCache.instance.history;
      if (inMemory != null) {
        return inMemory;
      }
      final cached = await cache.readHistory();
      if (cached != null) {
        SessionDataCache.instance.history = cached;
        return cached;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchFilteredHistory({
    required String filterType,
    int limit = 12,
  }) async {
    final session = await AuthSessionStore().load();
    final response = await http.get(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/api/v1/activity/history/filter?filter_type=$filterType&limit=$limit',
      ),
      headers: {
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el historial filtrado');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (filterType == 'all') {
      SessionDataCache.instance.history = data;
    }
    return data;
  }

  Future<void> updateWorkout({
    required int id,
    required int sessionMinutes,
    required String focus,
    required String energyLevel,
    String notes = '',
  }) async {
    await _sendJson(
      path: '/api/v1/activity/workouts/$id',
      method: 'PUT',
      body: {
        'session_minutes': sessionMinutes,
        'focus': focus,
        'energy_level': energyLevel,
        'notes': notes,
      },
    );
  }

  Future<void> deleteWorkout(int id) async {
    await _sendJson(path: '/api/v1/activity/workouts/$id', method: 'DELETE');
  }

  Future<void> updateNutrition({
    required int id,
    required String mealLabel,
    required int adherenceScore,
    required int proteinGrams,
    required int hydrationLiters,
    String notes = '',
  }) async {
    await _sendJson(
      path: '/api/v1/activity/nutrition/$id',
      method: 'PUT',
      body: {
        'meal_label': mealLabel,
        'adherence_score': adherenceScore,
        'protein_grams': proteinGrams,
        'hydration_liters': hydrationLiters,
        'notes': notes,
      },
    );
  }

  Future<void> deleteNutrition(int id) async {
    await _sendJson(path: '/api/v1/activity/nutrition/$id', method: 'DELETE');
  }

  Future<void> updateBodyMetric({
    required int id,
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
    await _sendJson(
      path: '/api/v1/activity/body-metrics/$id',
      method: 'PUT',
      body: {
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
      },
    );
  }

  Future<void> deleteBodyMetric(int id) async {
    await _sendJson(
      path: '/api/v1/activity/body-metrics/$id',
      method: 'DELETE',
    );
  }

  Future<void> _sendJson({
    required String path,
    required String method,
    Map<String, Object?>? body,
  }) async {
    final session = await AuthSessionStore().load();
    final request = http.Request(
      method,
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
    );
    request.headers.addAll({
      'Content-Type': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    });
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await request.send();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('No se pudo completar la operacion');
    }
  }
}
