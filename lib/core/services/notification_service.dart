import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';

/// Schedules local habit reminders. Fully on-device; no network involved.
///
/// A habit's reminder id is derived deterministically from its UUID so a habit
/// always owns the same notification slot (re-scheduling replaces, never
/// duplicates).
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      // Fall back to UTC if the platform timezone can't be resolved.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Schedules (or reschedules) a daily reminder at [time] ('HH:mm').
  Future<void> scheduleDailyReminder({
    required String habitId,
    required String habitName,
    required String time,
  }) async {
    await init();
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    await _plugin.zonedSchedule(
      _idFor(habitId),
      'Time for $habitName',
      'A small step today keeps your streak alive.',
      _nextInstanceOf(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.reminderChannelId,
          AppConstants.reminderChannelName,
          channelDescription: 'Daily habit reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String habitId) =>
      _plugin.cancel(_idFor(habitId));

  Future<void> cancelAll() => _plugin.cancelAll();

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Stable 31-bit notification id derived from the habit UUID.
  int _idFor(String habitId) => habitId.hashCode & 0x7fffffff;
}
