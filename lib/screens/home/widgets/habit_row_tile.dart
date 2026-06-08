import 'package:flutter/material.dart';

import '../../../models/habit_with_streak.dart';

class HabitRowTile extends StatelessWidget {
  final HabitWithStreak data;
  final List<DateTime> weekDays; // 7 days Mon–Sun
  final void Function(DateTime date) onToggle;
  final VoidCallback? onLongPress;

  const HabitRowTile({
    super.key,
    required this.data,
    required this.weekDays,
    required this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final habitColor = Color(data.habit.colorValue);
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: habitColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      IconData(data.habit.iconCodePoint,
                          fontFamily: 'MaterialIcons'),
                      color: habitColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.habit.name,
                            style:
                                Theme.of(context).textTheme.titleSmall),
                        if (data.habit.description != null)
                          Text(
                            data.habit.description!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _StreakBadge(
                    streak: data.streak,
                    warn: data.hasMissedTwoDays,
                    color: habitColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekDays.map((day) {
                  final isFuture = day.isAfter(todayNorm);
                  final completed = data.completedOn(day);
                  final isToday = day == todayNorm;
                  return _DayChip(
                    date: day,
                    completed: completed,
                    isFuture: isFuture,
                    isToday: isToday,
                    color: habitColor,
                    onTap: isFuture ? null : () => onToggle(day),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime date;
  final bool completed;
  final bool isFuture;
  final bool isToday;
  final Color color;
  final VoidCallback? onTap;

  const _DayChip({
    required this.date,
    required this.completed,
    required this.isFuture,
    required this.isToday,
    required this.color,
    this.onTap,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _dayLabels[date.weekday - 1];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? color : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? color
                  : isFuture
                      ? Colors.transparent
                      : color.withValues(alpha: 0.08),
              border: isToday && !completed
                  ? Border.all(color: color, width: 1.5)
                  : null,
            ),
            child: completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  final bool warn;
  final Color color;

  const _StreakBadge(
      {required this.streak, required this.warn, required this.color});

  @override
  Widget build(BuildContext context) {
    if (streak == 0 && !warn) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: warn
            ? Colors.orange.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            warn ? Icons.warning_amber_rounded : Icons.local_fire_department,
            size: 14,
            color: warn ? Colors.orange : color,
          ),
          const SizedBox(width: 3),
          Text(
            warn ? '!' : '$streak',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: warn ? Colors.orange : color,
            ),
          ),
        ],
      ),
    );
  }
}
