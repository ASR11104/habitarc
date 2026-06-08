import 'package:drift/drift.dart';
import 'habits_table.dart';

class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id)();
  // Stored normalized to midnight (date only)
  DateTimeColumn get logDate => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, logDate}
      ];
}
