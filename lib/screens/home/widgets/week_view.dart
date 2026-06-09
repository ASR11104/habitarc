import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/habit_with_streak.dart';
import '../../../providers/habits_provider.dart';
import '../../add_habit/add_habit_screen.dart';
import 'habit_row_tile.dart';

class WeekView extends ConsumerWidget {
  const WeekView({super.key});

  static List<DateTime> _currentWeekDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday of this week
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekDays = _currentWeekDays();
    final range = (start: weekDays.first, end: weekDays.last);
    final repo = ref.read(habitsRepositoryProvider);

    // Sync the progress notification whenever habit data changes (app open + toggles).
    ref.listen<AsyncValue<List<HabitWithStreak>>>(
      habitsWithStreakProvider(range),
      (_, next) => next.whenData(repo.syncProgressNotification),
    );

    final dataAsync = ref.watch(habitsWithStreakProvider(range));

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checklist_rounded,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'No habits yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first habit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final hws = items[i];
            return HabitRowTile(
              data: hws,
              weekDays: weekDays,
              onToggle: (date) async {
                await repo.toggleLog(hws.habit.id, date);
                // Re-read updated state and sync reminders
                final updated = ref.read(habitsWithStreakProvider(range));
                updated.whenData((list) {
                  final updatedHws =
                      list.firstWhere((h) => h.habit.id == hws.habit.id);
                  repo.syncReminder(updatedHws);
                });
              },
              onLongPress: () => _showHabitOptions(context, ref, hws.habit),
            );
          },
        );
      },
    );
  }

  void _showHabitOptions(BuildContext context, WidgetRef ref, habit) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddHabitScreen(habit: habit),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(habitsRepositoryProvider)
                    .archiveHabit(habit.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
