import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/personalized_headers_service.dart';
import '../../../auth/data/services/auth_session_store.dart';
import '../../domain/models/exercise_log.dart';

class ExerciseLogApiService {
  const ExerciseLogApiService();

  Future<Map<String, String>> _headers({bool withContentType = false}) async {
    final session = await AuthSessionStore().load();
    final personalized =
        await const PersonalizedHeadersService().build();
    return {
      ...personalized,
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      if (withContentType) 'Content-Type': 'application/json',
    };
  }

  Future<ExerciseLog> logSet(ExerciseLog log) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/activity/exercise-logs',
    );

    final response = await http.post(
      uri,
      headers: await _headers(withContentType: true),
      body: jsonEncode(log.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo registrar el set (${response.statusCode})',
      );
    }

    return ExerciseLog.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<ExerciseLog>> getDayLogs(
    String dayIso, {
    String? exerciseName,
  }) async {
    final queryParams = <String, String>{'day': dayIso};
    if (exerciseName != null) queryParams['exercise_name'] = exerciseName;

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/activity/exercise-logs',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo cargar los registros del día $dayIso (${response.statusCode})',
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(ExerciseLog.fromJson)
        .toList();
  }
}
