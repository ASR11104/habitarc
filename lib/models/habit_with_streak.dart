import '../database/app_database.dart';

class HabitWithStreak {
  final Habit habit;
  final Set<DateTime> completedDates;

  const HabitWithStreak({
    required this.habit,
    required this.completedDates,
  });

  bool isScheduledOn(DateTime date) {
    if (habit.isWeeklyPillar != true) return true;
    if (habit.weeklyDays == null || habit.weeklyDays!.isEmpty) return false;
    final days = habit.weeklyDays!
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
    return days.contains(date.weekday);
  }

  int get streak {
    int count = 0;
    DateTime day = _today;

    // Find the starting day: either today (if it's scheduled) or the most recent scheduled day before today
    int loopCount = 0;
    while (!isScheduledOn(day)) {
      day = day.subtract(const Duration(days: 1));
      loopCount++;
      if (loopCount > 30) return 0;
    }

    if (day == _today && !completedDates.contains(day)) {
      return 0;
    }

    while (completedDates.contains(day)) {
      count++;
      int innerLoop = 0;
      do {
        day = day.subtract(const Duration(days: 1));
        innerLoop++;
        if (innerLoop > 30) break;
      } while (!isScheduledOn(day));
    }
    return count;
  }

  // Missed the last two scheduled days before today → visual warning
  bool get hasMissedTwoDays {
    DateTime firstPrev = _today.subtract(const Duration(days: 1));
    int loopCount1 = 0;
    while (!isScheduledOn(firstPrev)) {
      firstPrev = firstPrev.subtract(const Duration(days: 1));
      loopCount1++;
      if (loopCount1 > 30) return false;
    }

    DateTime secondPrev = firstPrev.subtract(const Duration(days: 1));
    int loopCount2 = 0;
    while (!isScheduledOn(secondPrev)) {
      secondPrev = secondPrev.subtract(const Duration(days: 1));
      loopCount2++;
      if (loopCount2 > 30) return false;
    }

    return !completedDates.contains(firstPrev) &&
        !completedDates.contains(secondPrev);
  }

  bool completedOn(DateTime date) => completedDates.contains(_normalize(date));

  static DateTime get _today => _normalize(DateTime.now());

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
