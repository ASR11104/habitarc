import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/habit_with_streak.dart';
import '../services/notification_service.dart';
import 'database_provider.dart';

// ── Raw streams ─────────────────────────────────────────────────────────────

final habitsStreamProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(databaseProvider).watchActiveHabits();
});

// Date-range log stream, re-evaluated when the range changes
final logsForRangeProvider =
    StreamProvider.family<List<HabitLog>, ({DateTime start, DateTime end})>(
        (ref, range) {
  return ref
      .watch(databaseProvider)
      .watchLogsForDateRange(range.start, range.end);
});

// ── Derived: habits + streaks ────────────────────────────────────────────────

final habitsWithStreakProvider =
    Provider.family<AsyncValue<List<HabitWithStreak>>,
        ({DateTime start, DateTime end})>((ref, range) {
  final habitsAsync = ref.watch(habitsStreamProvider);
  final logsAsync = ref.watch(logsForRangeProvider(range));

  return habitsAsync.when(
    data: (habits) => logsAsync.when(
      data: (logs) {
        final logsByHabit = <int, Set<DateTime>>{};
        for (final log in logs) {
          logsByHabit.putIfAbsent(log.habitId, () => {}).add(log.logDate);
        }
        return AsyncValue.data(habits
            .map((h) => HabitWithStreak(
                  habit: h,
                  completedDates: logsByHabit[h.id] ?? {},
                ))
            .toList());
      },
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// ── Mutations ────────────────────────────────────────────────────────────────

class HabitsRepository {
  const HabitsRepository(this._db);
  final AppDatabase _db;

  Future<void> addHabit(String name, String? description, int colorValue,
      int iconCodePoint) async {
    await _db.insertHabit(HabitsCompanion(
      name: Value(name),
      description: Value(description),
      colorValue: Value(colorValue),
      iconCodePoint: Value(iconCodePoint),
      createdAt: Value(DateTime.now()),
    ));
  }

  Future<void> updateHabit(Habit habit) async {
    await _db.updateHabit(HabitsCompanion(
      id: Value(habit.id),
      name: Value(habit.name),
      description: Value(habit.description),
      colorValue: Value(habit.colorValue),
      iconCodePoint: Value(habit.iconCodePoint),
    ));
  }

  Future<void> archiveHabit(int id) async {
    await _db.archiveHabit(id);
    await NotificationService.cancelReminder(id);
  }

  Future<void> toggleLog(int habitId, DateTime date) async {
    await _db.toggleHabitLog(habitId, date);
  }

  /// Call after any toggle to re-evaluate reminders for a habit.
  Future<void> syncReminder(HabitWithStreak hws) async {
    final yesterday =
        DateTime.now().subtract(const Duration(days: 1));
    final yNorm = DateTime(yesterday.year, yesterday.month, yesterday.day);

    if (!hws.completedDates.contains(yNorm)) {
      // Missed yesterday → schedule next-day reminder
      await NotificationService.scheduleReminder(
          hws.habit.id, hws.habit.name);
    } else {
      await NotificationService.cancelReminder(hws.habit.id);
    }
  }

  /// Update the today-progress notification based on the full habit list.
  /// Call after any toggle and on app open.
  Future<void> syncProgressNotification(List<HabitWithStreak> all) async {
    final today = DateTime.now();
    final tNorm = DateTime(today.year, today.month, today.day);

    final total = all.length;
    final done = all.where((h) => h.completedDates.contains(tNorm)).length;
    final pending = all
        .where((h) => !h.completedDates.contains(tNorm))
        .map((h) => h.habit.name)
        .toList();

    await NotificationService.showTodayProgress(done, total, pending);
  }
}

final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  return HabitsRepository(ref.watch(databaseProvider));
});
