import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/personalized_headers_service.dart';
import '../../../auth/data/services/auth_session_store.dart';
import '../../domain/models/onboarding_profile.dart';

class OnboardingApiService {
  const OnboardingApiService();

  Future<void> submitProfile(OnboardingProfile profile) async {
    final headers = await _authorizedHeaders();
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/onboarding/profile');
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('No se pudo guardar el onboarding');
    }
  }

  Future<OnboardingProfile?> fetchLatestProfile() async {
    final headers = await _authorizedHeaders();
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/onboarding/profile/latest');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el perfil');
    }

    return OnboardingProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> fetchDashboardSummary() async {
    final headers = await _authorizedHeaders();
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/onboarding/dashboard-summary',
    );
    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el dashboard');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final session = await AuthSessionStore().load();
    final personalizedHeaders = await const PersonalizedHeadersService().build();
    return {
      ...personalizedHeaders,
      'Content-Type': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }
}
