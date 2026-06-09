import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Channels
  static const _remindersChannelId = 'habit_reminders';
  static const _remindersChannelName = 'Habit Reminders';
  static const _progressChannelId = 'habit_progress';
  static const _progressChannelName = 'Daily Progress';

  // Fixed IDs well above the SQLite auto-increment range for habits
  static const _dailyReminderId = 999997;
  static const _progressNotifId = 999998;

  static const _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _remindersChannelId,
      _remindersChannelName,
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

  /// Show or update the today-progress notification.
  /// Called after every toggle and on app open.
  static Future<void> showTodayProgress(
      int done, int total, List<String> pending) async {
    if (total == 0) {
      await _plugin.cancel(_progressNotifId);
      return;
    }

    if (done == total) {
      await _plugin.show(
        _progressNotifId,
        'HabitArc — all done!',
        'You completed all $total habit${total == 1 ? '' : 's'} today.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _progressChannelId,
            _progressChannelName,
            channelDescription: "Today's habit completion progress",
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            onlyAlertOnce: true,
          ),
        ),
      );
      return;
    }

    final remaining = total - done;
    final names = pending.take(3).join(', ');
    final overflow = pending.length > 3 ? ' +${pending.length - 3} more' : '';

    await _plugin.show(
      _progressNotifId,
      'HabitArc — $done / $total done',
      '$remaining pending: $names$overflow',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _progressChannelId,
          _progressChannelName,
          channelDescription: "Today's habit completion progress",
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showProgress: true,
          maxProgress: total,
          progress: done,
          onlyAlertOnce: true,
        ),
      ),
    );
  }

  /// Schedule a repeating daily 8 PM reminder.
  /// Safe to call on every app launch — replaces any existing schedule.
  static Future<void> scheduleDailyReminder() async {
    await _plugin.zonedSchedule(
      _dailyReminderId,
      'HabitArc',
      "Don't forget to check your habits today!",
      _nextInstanceOf(20, 0),
      _reminderDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a next-day 8 AM reminder for a single habit.
  static Future<void> scheduleReminder(int habitId, String habitName) async {
    await _plugin.zonedSchedule(
      habitId,
      'HabitArc',
      'Reminder: $habitName — don\'t miss two days in a row!',
      _nextInstanceOf(8, 0),
      _reminderDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a per-habit reminder.
  static Future<void> cancelReminder(int habitId) async {
    await _plugin.cancel(habitId);
  }

  /// Cancel all pending notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
