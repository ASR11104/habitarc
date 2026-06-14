import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/habit_with_streak.dart';
import '../../../providers/habits_provider.dart';
import '../../habit_detail/habit_detail_screen.dart';
import 'habit_row_tile.dart';

class WeekView extends ConsumerWidget {
  final bool isWeeklyPillar;

  const WeekView({super.key, required this.isWeeklyPillar});

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
        final filteredItems = items
            .where((item) => item.habit.isWeeklyPillar == isWeeklyPillar)
            .toList();

        if (filteredItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isWeeklyPillar
                      ? Icons.view_week_outlined
                      : Icons.checklist_rounded,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  isWeeklyPillar ? 'No weekly pillars yet' : 'No anchor habits yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isWeeklyPillar
                      ? 'Tap + to add your first scheduled habit'
                      : 'Tap + to add your first daily habit',
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

        return ReorderableListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: filteredItems.length,
          onReorder: (oldIndex, newIndex) async {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = filteredItems.removeAt(oldIndex);
            filteredItems.insert(newIndex, item);
            
            final orderedIds = filteredItems.map((h) => h.habit.id).toList();
            await repo.reorderHabits(orderedIds);
          },
          itemBuilder: (context, i) {
            final hws = filteredItems[i];
            return HabitRowTile(
              key: ValueKey(hws.habit.id),
              data: hws,
              weekDays: weekDays,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HabitDetailScreen(habit: hws.habit),
                ),
              ),
              onToggle: (date) async {
                await repo.toggleLog(hws.habit.id, date);
                final updated = ref.read(habitsWithStreakProvider(range));
                updated.whenData((list) {
                  final updatedHws =
                      list.firstWhere((h) => h.habit.id == hws.habit.id);
                  repo.syncReminder(updatedHws);
                });
              },
            );
          },
        );
      },
    );
  }
}
