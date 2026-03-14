import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/local_sync_store.dart';
import '../../../auth/data/services/auth_session_store.dart';

class OfflineActivityQueueService {
  const OfflineActivityQueueService();

  Future<void> enqueueWorkout(Map<String, dynamic> payload) async {
    final store = const LocalSyncStore();
    final queue = await store.readPendingWorkouts();
    queue.add(payload);
    await store.writePendingWorkouts(queue);
  }

  Future<void> enqueueNutrition(Map<String, dynamic> payload) async {
    final store = const LocalSyncStore();
    final queue = await store.readPendingNutrition();
    queue.add(payload);
    await store.writePendingNutrition(queue);
  }

  Future<void> flush() async {
    final session = await AuthSessionStore().load();
    if (session == null) {
      return;
    }
    await _flushQueue(
      path: '/api/v1/activity/workouts',
      queueKey: 'workouts',
      items: await const LocalSyncStore().readPendingWorkouts(),
      token: session.accessToken,
    );
    await _flushQueue(
      path: '/api/v1/activity/nutrition',
      queueKey: 'nutrition',
      items: await const LocalSyncStore().readPendingNutrition(),
      token: session.accessToken,
    );
  }

  Future<void> _flushQueue({
    required String path,
    required String queueKey,
    required List<Map<String, dynamic>> items,
    required String token,
  }) async {
    if (items.isEmpty) {
      return;
    }
    final pending = <Map<String, dynamic>>[];
    for (final item in items) {
      try {
        final response = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(item),
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          pending.add(item);
        }
      } catch (_) {
        pending.add(item);
      }
    }

    if (queueKey == 'workouts') {
      await const LocalSyncStore().writePendingWorkouts(pending);
    } else {
      await const LocalSyncStore().writePendingNutrition(pending);
    }
  }
}
