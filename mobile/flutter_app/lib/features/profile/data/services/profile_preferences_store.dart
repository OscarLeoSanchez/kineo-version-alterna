import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/profile_preferences.dart';

class ProfilePreferencesStore {
  static const _coachingStyleKey = 'profile.coaching_style';
  static const _unitsKey = 'profile.units';
  static const _remindersEnabledKey = 'profile.reminders_enabled';
  static const _experienceModeKey = 'profile.experience_mode';
  static const _legacyMembershipPlanKey = 'profile.membership_plan';
  static const _dailyPriorityKey = 'profile.daily_priority';
  static const _recommendationDepthKey = 'profile.recommendation_depth';
  static const _proactiveAdjustmentsKey = 'profile.proactive_adjustments';

  Future<ProfilePreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = ProfilePreferences.defaults();
    return ProfilePreferences(
      coachingStyle: prefs.getString(_coachingStyleKey) ?? defaults.coachingStyle,
      units: prefs.getString(_unitsKey) ?? defaults.units,
      remindersEnabled:
          prefs.getBool(_remindersEnabledKey) ?? defaults.remindersEnabled,
      experienceMode:
          prefs.getString(_experienceModeKey) ??
          prefs.getString(_legacyMembershipPlanKey) ??
          defaults.experienceMode,
      dailyPriority:
          prefs.getString(_dailyPriorityKey) ?? defaults.dailyPriority,
      recommendationDepth:
          prefs.getString(_recommendationDepthKey) ??
          defaults.recommendationDepth,
      proactiveAdjustments:
          prefs.getBool(_proactiveAdjustmentsKey) ??
          defaults.proactiveAdjustments,
    );
  }

  Future<void> save(ProfilePreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coachingStyleKey, preferences.coachingStyle);
    await prefs.setString(_unitsKey, preferences.units);
    await prefs.setBool(_remindersEnabledKey, preferences.remindersEnabled);
    await prefs.setString(_experienceModeKey, preferences.experienceMode);
    await prefs.remove(_legacyMembershipPlanKey);
    await prefs.setString(_dailyPriorityKey, preferences.dailyPriority);
    await prefs.setString(
      _recommendationDepthKey,
      preferences.recommendationDepth,
    );
    await prefs.setBool(
      _proactiveAdjustmentsKey,
      preferences.proactiveAdjustments,
    );
  }
}
