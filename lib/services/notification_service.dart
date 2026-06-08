import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'habit_reminders';
  static const _channelName = 'Habit Reminders';

  static const _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily reminders for missed habits',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));

    // Request POST_NOTIFICATIONS permission on Android 13+
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Schedule a next-day 8 AM reminder for a habit.
  /// Call this when a habit was missed yesterday.
  static Future<void> scheduleReminder(int habitId, String habitName) async {
    await _plugin.zonedSchedule(
      habitId,
      'HabitArc',
      'Reminder: $habitName — don\'t miss two days in a row!',
      _nextInstanceOf8AM(),
      _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a pending reminder (call when habit is completed).
  static Future<void> cancelReminder(int habitId) async {
    await _plugin.cancel(habitId);
  }

  /// Cancel all pending reminders.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOf8AM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
