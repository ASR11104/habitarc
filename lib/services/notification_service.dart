import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
    try {
      tz.initializeTimeZones();
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      } catch (e) {
        debugPrint('NotificationService: Failed to get local timezone, defaulting to UTC. Error: $e');
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));

      // Request POST_NOTIFICATIONS permission on Android 13+
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission().catchError((e) {
          debugPrint('NotificationService: Failed to request notifications permission. Error: $e');
          return null;
        });
        await androidPlugin.requestExactAlarmsPermission().catchError((e) {
          debugPrint('NotificationService: Failed to request exact alarms permission. Error: $e');
          return null;
        });
      }
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }
  }

  /// Show or update the today-progress notification.
  /// Called after every toggle and on app open.
  static Future<void> showTodayProgress(
      int done, int total, List<String> pending) async {
    try {
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
    } catch (e) {
      debugPrint('NotificationService: Failed to show today progress: $e');
    }
  }

  /// Schedule a repeating daily 8 PM reminder.
  /// Safe to call on every app launch — replaces any existing schedule.
  static Future<void> scheduleDailyReminder() async {
    try {
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
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule daily reminder: $e');
    }
  }

  /// Schedule a next-day 8 AM reminder for a single habit.
  static Future<void> scheduleReminder(int habitId, String habitName) async {
    try {
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
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule reminder for habit $habitId ($habitName): $e');
    }
  }

  /// Cancel a per-habit reminder.
  static Future<void> cancelReminder(int habitId) async {
    try {
      await _plugin.cancel(habitId);
    } catch (e) {
      debugPrint('NotificationService: Failed to cancel reminder for habit $habitId: $e');
    }
  }

  /// Cancel all pending notifications.
  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService: Failed to cancel all notifications: $e');
    }
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
