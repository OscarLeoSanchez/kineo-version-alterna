import '../../domain/models/profile_preferences.dart';
import 'profile_preferences_api_service.dart';
import 'profile_preferences_store.dart';

class ProfilePreferencesSyncService {
  ProfilePreferencesSyncService({
    ProfilePreferencesStore? store,
    ProfilePreferencesApiService? apiService,
  }) : _store = store ?? ProfilePreferencesStore(),
       _apiService = apiService ?? const ProfilePreferencesApiService();

  final ProfilePreferencesStore _store;
  final ProfilePreferencesApiService _apiService;

  Future<ProfilePreferences> load() async {
    try {
      var remote = await _apiService.fetchPreferences();
      if (remote.experienceMode == 'Free' || remote.experienceMode == 'Pro Trial') {
        remote = await _apiService.updatePreferences(
          remote.copyWith(experienceMode: 'Full'),
        );
      }
      await _store.save(remote);
      return remote;
    } catch (_) {
      final local = await _store.load();
      final normalized =
          local.experienceMode == 'Free' || local.experienceMode == 'Pro Trial'
          ? local.copyWith(experienceMode: 'Full')
          : local;
      await _store.save(normalized);
      return normalized;
    }
  }

  Future<ProfilePreferences> save(ProfilePreferences preferences) async {
    final normalized =
        preferences.experienceMode == 'Free' ||
            preferences.experienceMode == 'Pro Trial'
        ? preferences.copyWith(experienceMode: 'Full')
        : preferences;
    try {
      final remote = await _apiService.updatePreferences(normalized);
      await _store.save(remote);
      return remote;
    } catch (_) {
      await _store.save(normalized);
      return normalized;
    }
  }
}
