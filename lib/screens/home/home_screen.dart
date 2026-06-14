import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../add_habit/add_habit_screen.dart';
import 'widgets/week_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HabitArc',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              DateFormat('EEEE, MMM d').format(now),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Anchor Habits'),
            Tab(text: 'Weekly Pillars'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WeekView(isWeeklyPillar: false),
          WeekView(isWeeklyPillar: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddHabitScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
