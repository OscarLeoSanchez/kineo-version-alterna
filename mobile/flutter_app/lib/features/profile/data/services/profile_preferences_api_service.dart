import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../auth/data/services/auth_session_store.dart';
import '../../domain/models/profile_preferences.dart';

class ProfilePreferencesApiService {
  const ProfilePreferencesApiService();

  Future<ProfilePreferences> fetchPreferences() async {
    final session = await AuthSessionStore().load();
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/preferences/me'),
      headers: {
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las preferencias');
    }

    return _fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ProfilePreferences> updatePreferences(
    ProfilePreferences preferences,
  ) async {
    final session = await AuthSessionStore().load();
    final response = await http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/preferences/me'),
      headers: {
        'Content-Type': 'application/json',
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'coaching_style': preferences.coachingStyle,
        'units': preferences.units,
        'reminders_enabled': preferences.remindersEnabled,
        'experience_mode': preferences.experienceMode,
        'daily_priority': preferences.dailyPriority,
        'recommendation_depth': preferences.recommendationDepth,
        'proactive_adjustments': preferences.proactiveAdjustments,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron guardar las preferencias');
    }

    return _fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  ProfilePreferences _fromJson(Map<String, dynamic> body) {
    final rawExperience =
        body['experience_mode']?.toString() ??
        body['membership_plan']?.toString() ??
        'Full';
    return ProfilePreferences(
      coachingStyle: body['coaching_style']?.toString() ?? 'Equilibrado',
      units: body['units']?.toString() ?? 'Metricas',
      remindersEnabled: body['reminders_enabled'] as bool? ?? true,
      experienceMode: switch (rawExperience) {
        'Free' => 'Full',
        'Pro Trial' => 'Full',
        _ => rawExperience,
      },
      dailyPriority: body['daily_priority']?.toString() ?? 'Adherencia',
      recommendationDepth:
          body['recommendation_depth']?.toString() ?? 'Profunda',
      proactiveAdjustments:
          body['proactive_adjustments'] as bool? ?? true,
    );
  }
}
