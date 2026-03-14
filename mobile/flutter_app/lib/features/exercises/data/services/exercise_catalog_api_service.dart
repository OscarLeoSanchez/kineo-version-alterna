import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/personalized_headers_service.dart';
import '../../../auth/data/services/auth_session_store.dart';
import '../../domain/models/exercise_catalog_item.dart';

class ExerciseCatalogApiService {
  const ExerciseCatalogApiService();

  Future<Map<String, String>> _headers() async {
    final session = await AuthSessionStore().load();
    final personalized =
        await const PersonalizedHeadersService().build();
    return {
      ...personalized,
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  Future<List<ExerciseCatalogItem>> getExercises({
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (muscleGroup != null) queryParams['muscle_group'] = muscleGroup;
    if (equipment != null) queryParams['equipment'] = equipment;
    if (difficulty != null) queryParams['difficulty'] = difficulty;

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/exercises',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo cargar el catálogo de ejercicios (${response.statusCode})',
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(ExerciseCatalogItem.fromJson)
        .toList();
  }

  Future<ExerciseCatalogItem> getExercise(int id) async {
    final uri =
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/exercises/$id');

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo cargar el ejercicio $id (${response.statusCode})',
      );
    }

    return ExerciseCatalogItem.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<ExerciseCatalogItem>> getSubstitutes(
    int exerciseId, {
    List<String> availableEquipment = const [],
  }) async {
    final queryParams = <String, dynamic>{};
    if (availableEquipment.isNotEmpty) {
      queryParams['equipment'] = availableEquipment;
    }

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/exercises/$exerciseId/substitutes',
    ).replace(queryParameters: queryParams.map(
      (k, v) => MapEntry(k, v is List ? v.join(',') : v.toString()),
    ));

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo cargar sustitutos del ejercicio $exerciseId (${response.statusCode})',
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(ExerciseCatalogItem.fromJson)
        .toList();
  }
}
