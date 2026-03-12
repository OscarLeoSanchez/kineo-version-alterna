import '../../features/profile/data/services/profile_preferences_sync_service.dart';

class PersonalizedHeadersService {
  const PersonalizedHeadersService();

  Future<Map<String, String>> build() async {
    final preferences = await ProfilePreferencesSyncService().load();
    return {
      'X-Coach-Style': preferences.coachingStyle,
      'X-Experience-Mode': preferences.experienceMode,
      'X-Membership-Plan': preferences.experienceMode,
      'X-Units': preferences.units,
    };
  }
}
