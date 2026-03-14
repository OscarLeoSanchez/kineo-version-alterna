import 'package:flutter/foundation.dart';

/// In-memory cache for dashboard data with a 5-minute TTL.
///
/// Stores raw dashboard data as [Map<String, dynamic>] with keys:
/// fullName, summary, plan, progress, goal, history, preferences, todayStatus,
/// hasProfile.
class DashboardCache {
  static final DashboardCache _instance = DashboardCache._internal();
  factory DashboardCache() => _instance;
  DashboardCache._internal();

  Map<String, dynamic>? _data;
  DateTime? _cachedAt;
  static const _ttl = Duration(minutes: 5);

  bool get isStale =>
      _cachedAt == null || DateTime.now().difference(_cachedAt!) > _ttl;

  Map<String, dynamic>? get cachedData => isStale ? null : _data;

  void store(Map<String, dynamic> data) {
    _data = data;
    _cachedAt = DateTime.now();
    debugPrint('[DashboardCache] stored at $_cachedAt');
  }

  void invalidate() {
    _data = null;
    _cachedAt = null;
    debugPrint('[DashboardCache] invalidated');
  }
}
