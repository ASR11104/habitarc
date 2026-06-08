import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/habits_table.dart';
import 'tables/habit_logs_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Habits, HabitLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'habitarc');
  }

  // ── Habits ──────────────────────────────────────────────────────────────

  Stream<List<Habit>> watchActiveHabits() =>
      (select(habits)..where((h) => h.isActive.equals(true))).watch();

  Future<int> insertHabit(HabitsCompanion companion) =>
      into(habits).insert(companion);

  Future<void> updateHabit(HabitsCompanion companion) =>
      (update(habits)..where((h) => h.id.equals(companion.id.value)))
          .write(companion);

  Future<void> archiveHabit(int id) =>
      (update(habits)..where((h) => h.id.equals(id)))
          .write(const HabitsCompanion(isActive: Value(false)));

  // ── Habit Logs ───────────────────────────────────────────────────────────

  Stream<List<HabitLog>> watchLogsForDateRange(
      DateTime start, DateTime end) {
    return (select(habitLogs)
          ..where((l) => l.logDate.isBetweenValues(start, end)))
        .watch();
  }

  Future<List<HabitLog>> getLogsForHabit(int habitId) =>
      (select(habitLogs)..where((l) => l.habitId.equals(habitId))).get();

  Future<void> toggleHabitLog(int habitId, DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    final existing = await (select(habitLogs)
          ..where((l) =>
              l.habitId.equals(habitId) & l.logDate.equals(normalized)))
        .getSingleOrNull();

    if (existing == null) {
      await into(habitLogs).insert(HabitLogsCompanion(
        habitId: Value(habitId),
        logDate: Value(normalized),
      ));
    } else {
      await (delete(habitLogs)..where((l) => l.id.equals(existing.id))).go();
    }
  }
}
