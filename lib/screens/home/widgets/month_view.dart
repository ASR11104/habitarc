import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/habits_provider.dart';

class MonthView extends ConsumerStatefulWidget {
  const MonthView({super.key});

  @override
  ConsumerState<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<MonthView> {
  DateTime _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime get _monthStart => _displayMonth;
  DateTime get _monthEnd =>
      DateTime(_displayMonth.year, _displayMonth.month + 1, 0);

  void _prevMonth() =>
      setState(() => _displayMonth =
          DateTime(_displayMonth.year, _displayMonth.month - 1));

  void _nextMonth() {
    final next =
        DateTime(_displayMonth.year, _displayMonth.month + 1);
    if (!next.isAfter(DateTime(DateTime.now().year, DateTime.now().month))) {
      setState(() => _displayMonth = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = (start: _monthStart, end: _monthEnd);
    final habitsAsync = ref.watch(habitsStreamProvider);
    final logsAsync = ref.watch(logsForRangeProvider(range));
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Month navigation
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: _displayMonth.year == DateTime.now().year &&
                        _displayMonth.month == DateTime.now().month
                    ? null
                    : _nextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        // Day-of-week header
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

        // Calendar grid
        Expanded(
          child: habitsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (habits) => logsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (logs) {
                final totalHabits = habits.length;
                final completedByDate = <DateTime, int>{};
                for (final log in logs) {
                  completedByDate.update(
                      log.logDate, (v) => v + 1,
                      ifAbsent: () => 1);
                }

                return _CalendarGrid(
                  month: _displayMonth,
                  totalHabits: totalHabits,
                  completedByDate: completedByDate,
                );
              },
            ),
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: cs.primary.withValues(alpha: 0.2),
                  label: 'Partial'),
              const SizedBox(width: 16),
              _LegendDot(color: cs.primary, label: 'All done'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: cs.surfaceContainerHighest, label: 'None'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final int totalHabits;
  final Map<DateTime, int> completedByDate;

  const _CalendarGrid({
    required this.month,
    required this.totalHabits,
    required this.completedByDate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;
    // Offset: Monday = 0
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

        final date =
            DateTime(month.year, month.month, dayNumber);
        final isFuture = date.isAfter(today);
        final isToday = date == today;
        final completed = completedByDate[date] ?? 0;
        final ratio =
            totalHabits > 0 ? completed / totalHabits : 0.0;

        Color cellColor;
        if (isFuture) {
          cellColor = Colors.transparent;
        } else if (totalHabits == 0) {
          cellColor = cs.surfaceContainerHighest;
        } else if (ratio == 1.0) {
          cellColor = cs.primary;
        } else if (ratio > 0) {
          cellColor = cs.primary.withValues(alpha: 0.25);
        } else {
          cellColor = cs.surfaceContainerHighest;
        }

        return Container(
          decoration: BoxDecoration(
            color: cellColor,
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(color: cs.primary, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isToday ? FontWeight.bold : FontWeight.normal,
                color: ratio == 1.0 && !isFuture
                    ? cs.onPrimary
                    : cs.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
