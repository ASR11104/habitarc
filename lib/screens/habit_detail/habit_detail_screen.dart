import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../database/app_database.dart';
import '../../models/habit_with_streak.dart';
import '../../providers/habits_provider.dart';
import '../add_habit/add_habit_screen.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _displayMonth.year == now.year && _displayMonth.month == now.month;
  }

  void _prevMonth() =>
      setState(() => _displayMonth =
          DateTime(_displayMonth.year, _displayMonth.month - 1));

  void _nextMonth() {
    if (!_isCurrentMonth) {
      setState(() => _displayMonth =
          DateTime(_displayMonth.year, _displayMonth.month + 1));
    }
  }

  bool _isScheduledOn(DateTime date) {
    if (widget.habit.isWeeklyPillar != true) return true;
    if (widget.habit.weeklyDays == null || widget.habit.weeklyDays!.isEmpty) return false;
    final days = widget.habit.weeklyDays!
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
    return days.contains(date.weekday);
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final habitColor = Color(habit.colorValue);
    final logsAsync = ref.watch(allLogsForHabitProvider(habit.id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: habitColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconData(habit.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: habitColor,
                size: 18,
              ),
            ),
            Expanded(
              child: Text(habit.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit habit',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddHabitScreen(habit: habit)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete habit',
            onPressed: () => _confirmDelete(context, habit),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          final allDates = logs.map((l) => l.logDate).toSet();

          final hws = HabitWithStreak(habit: habit, completedDates: allDates);
          final currentStreak = hws.streak;
          final bestStreak = _bestStreak(allDates, _isScheduledOn);
          final total = allDates.length;

          final monthStart = _displayMonth;
          final monthEnd =
              DateTime(_displayMonth.year, _displayMonth.month + 1, 0);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final daysElapsed = _isCurrentMonth
              ? today.day
              : monthEnd.day;

          int totalScheduledDays = 0;
          for (int d = 1; d <= daysElapsed; d++) {
            final date = DateTime(_displayMonth.year, _displayMonth.month, d);
            if (_isScheduledOn(date)) {
              totalScheduledDays++;
            }
          }

          final monthDates = allDates
              .where((d) => !d.isBefore(monthStart) && !d.isAfter(monthEnd) && _isScheduledOn(d))
              .toSet();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (habit.description != null && habit.description!.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    habit.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ),

              // ── Stats row ────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _StatCard(
                      label: 'Current streak',
                      value: '$currentStreak',
                      unit: currentStreak == 1 ? 'day' : 'days',
                      icon: Icons.local_fire_department,
                      color: habitColor,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Best streak',
                      value: '$bestStreak',
                      unit: bestStreak == 1 ? 'day' : 'days',
                      icon: Icons.emoji_events_outlined,
                      color: habitColor,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: 'Total done',
                      value: '$total',
                      unit: total == 1 ? 'time' : 'times',
                      icon: Icons.check_circle_outline,
                      color: habitColor,
                    ),
                  ],
                ),
              ),

              // ── Month navigation ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: _prevMonth,
                        icon: const Icon(Icons.chevron_left)),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM().format(_displayMonth),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: _isCurrentMonth ? null : _nextMonth,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              // ── Completion rate bar ──────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _CompletionBar(
                  done: monthDates.length,
                  total: totalScheduledDays,
                  color: habitColor,
                ),
              ),

              const SizedBox(height: 4),

              // ── Day-of-week header ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurfaceVariant)),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),

              // ── Calendar grid ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SingleHabitCalendarGrid(
                  month: _displayMonth,
                  completedDates: monthDates,
                  habitColor: habitColor,
                  isScheduled: _isScheduledOn,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Habit habit) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          '"${habit.name}" and all its history will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(habitsRepositoryProvider).deleteHabit(habit.id);
      navigator.pop();
    }
  }

  int _bestStreak(Set<DateTime> dates, bool Function(DateTime) isScheduled) {
    if (dates.isEmpty) return 0;
    final sorted = dates.toList()..sort();
    final minDate = sorted.first;
    final maxDate = sorted.last;

    int best = 0;
    int current = 0;

    DateTime day = minDate;
    while (!day.isAfter(maxDate)) {
      if (isScheduled(day)) {
        if (dates.contains(day)) {
          current++;
          if (current > best) {
            best = current;
          }
        } else {
          current = 0;
        }
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return best;
  }
}

// ── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
            Text(unit,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color.withValues(alpha: 0.8),
                    )),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
      ),
    );
  }
}

// ── Completion rate bar ───────────────────────────────────────────────────────

class _CompletionBar extends StatelessWidget {
  final int done;
  final int total;
  final Color color;

  const _CompletionBar(
      {required this.done, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? done / total : 0.0;
    final pct = (ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$done / $total days',
                style: Theme.of(context).textTheme.labelMedium),
            Text('$pct%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ── Single-habit calendar grid ────────────────────────────────────────────────

class _SingleHabitCalendarGrid extends StatelessWidget {
  final DateTime month;
  final Set<DateTime> completedDates;
  final Color habitColor;
  final bool Function(DateTime) isScheduled;

  const _SingleHabitCalendarGrid({
    required this.month,
    required this.completedDates,
    required this.habitColor,
    required this.isScheduled,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final dayNumber = index - startOffset + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(month.year, month.month, dayNumber);
        final isFuture = date.isAfter(today);
        final isToday = date == today;
        final completed = completedDates.contains(date);
        final scheduled = isScheduled(date);

        Color cellColor;
        if (!scheduled) {
          cellColor = Colors.transparent;
        } else if (isFuture) {
          cellColor = Colors.transparent;
        } else if (completed) {
          cellColor = habitColor;
        } else {
          cellColor = cs.surfaceContainerHighest;
        }

        final showBorder = scheduled && isToday && !completed;

        return Container(
          decoration: BoxDecoration(
            color: cellColor,
            shape: BoxShape.circle,
            border: showBorder
                ? Border.all(color: habitColor, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 11,
                fontWeight: scheduled && isToday ? FontWeight.bold : FontWeight.normal,
                color: !scheduled
                    ? cs.onSurfaceVariant.withValues(alpha: 0.20)
                    : (completed && !isFuture ? Colors.white : cs.onSurface),
              ),
            ),
          ),
        );
      },
    );
  }
}
