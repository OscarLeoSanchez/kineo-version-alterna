import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  Future<void> scheduleDailyReminder({
    required bool enabled,
    required String time,
  }) async {
    await initialize();
    await _plugin.cancel(1001);
    if (!enabled) return;

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'kineo_daily',
        'Kineo Daily',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    // On Android 12+, verify exact alarm permission before using zonedSchedule.
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final canSchedule =
          await androidPlugin?.canScheduleExactNotifications() ?? false;
      if (!canSchedule) {
        // Fallback: use periodic notification instead of exact alarm.
        await _plugin.periodicallyShow(
          1001,
          'Kineo Coach',
          'Es momento de revisar tu objetivo diario.',
          RepeatInterval.daily,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
        );
        return;
      }
    }

    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 7;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1001,
      'Kineo Coach',
      'Es momento de revisar tu objetivo diario.',
      scheduled,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
