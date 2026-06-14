import 'package:drift/drift.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF6750A4))();
  IntColumn get iconCodePoint => integer().withDefault(const Constant(0xe3c9))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isWeeklyPillar => boolean().withDefault(const Constant(false))();
  TextColumn get weeklyDays => text().nullable()();
}
