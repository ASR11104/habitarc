import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/habits_table.dart';
import 'tables/habit_logs_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Habits, HabitLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(habits, habits.sortOrder);
            await m.addColumn(habits, habits.isWeeklyPillar);
            await m.addColumn(habits, habits.weeklyDays);
            await customStatement('UPDATE habits SET sort_order = id');
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'habitarc');
  }

  // ── Habits ──────────────────────────────────────────────────────────────

  Stream<List<Habit>> watchActiveHabits() => (select(habits)
        ..where((h) => h.isActive.equals(true))
        ..orderBy([
          (t) => OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc),
          (t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc),
        ]))
      .watch();

  Future<void> reorderHabits(List<int> orderedIds) => transaction(() async {
        for (int i = 0; i < orderedIds.length; i++) {
          await (update(habits)..where((h) => h.id.equals(orderedIds[i])))
              .write(HabitsCompanion(sortOrder: Value(i)));
        }
      });

  Future<int> insertHabit(HabitsCompanion companion) =>
      into(habits).insert(companion);

  Future<void> updateHabit(HabitsCompanion companion) =>
      (update(habits)..where((h) => h.id.equals(companion.id.value)))
          .write(companion);

  Future<void> archiveHabit(int id) =>
      (update(habits)..where((h) => h.id.equals(id)))
          .write(const HabitsCompanion(isActive: Value(false)));

  Future<void> deleteHabit(int id) => transaction(() async {
        await (delete(habitLogs)..where((l) => l.habitId.equals(id))).go();
        await (delete(habits)..where((h) => h.id.equals(id))).go();
      });

  // ── Habit Logs ───────────────────────────────────────────────────────────

  Stream<List<HabitLog>> watchLogsForDateRange(
      DateTime start, DateTime end) {
    return (select(habitLogs)
          ..where((l) => l.logDate.isBetweenValues(start, end)))
        .watch();
  }

  Future<List<HabitLog>> getLogsForHabit(int habitId) =>
      (select(habitLogs)..where((l) => l.habitId.equals(habitId))).get();

  Stream<List<HabitLog>> watchLogsForHabit(int habitId) =>
      (select(habitLogs)..where((l) => l.habitId.equals(habitId))).watch();

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
