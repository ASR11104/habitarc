import '../database/app_database.dart';

class HabitWithStreak {
  final Habit habit;
  final Set<DateTime> completedDates;

  const HabitWithStreak({
    required this.habit,
    required this.completedDates,
  });

  int get streak {
    int count = 0;
    DateTime day = _today;
    while (completedDates.contains(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  // Missed yesterday and the day before → visual warning
  bool get hasMissedTwoDays {
    final yesterday = _today.subtract(const Duration(days: 1));
    final dayBefore = _today.subtract(const Duration(days: 2));
    return !completedDates.contains(yesterday) &&
        !completedDates.contains(dayBefore);
  }

  bool completedOn(DateTime date) => completedDates.contains(_normalize(date));

  static DateTime get _today => _normalize(DateTime.now());

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
