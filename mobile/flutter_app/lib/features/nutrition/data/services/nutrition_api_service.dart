import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/local_sync_store.dart';
import '../../../../core/services/personalized_headers_service.dart';
import '../../../../core/services/session_data_cache.dart';
import '../../../activity/data/services/offline_activity_queue_service.dart';
import '../../../auth/data/services/auth_session_store.dart';

class NutritionApiService {
  const NutritionApiService();

  Future<Map<String, dynamic>> fetchNutritionSummary({int? planId}) async {
    final session = await AuthSessionStore().load();
    final personalizedHeaders = await const PersonalizedHeadersService()
        .build();
    final cache = const LocalSyncStore();
    unawaited(const OfflineActivityQueueService().flush());
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/experience/nutrition',
    ).replace(queryParameters: {if (planId != null) 'plan_id': '$planId'});
    try {
      final response = await http.get(
        uri,
        headers: {
          ...personalizedHeaders,
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('No se pudo cargar la nutricion');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await cache.writeNutritionSummary(data);
      SessionDataCache.instance.nutritionSummary = data;
      return data;
    } catch (_) {
      final inMemory = SessionDataCache.instance.nutritionSummary;
      if (inMemory != null) {
        return inMemory;
      }
      final cached = await cache.readNutritionSummary();
      if (cached != null) {
        SessionDataCache.instance.nutritionSummary = cached;
        return cached;
      }
      rethrow;
    }
  }
}
