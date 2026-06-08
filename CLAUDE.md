# HabitArc

## Overview
Android habit-tracking app built with Flutter. Users create daily habits, mark them complete on a week view, review streaks, and get a local notification reminder the next day whenever a habit is missed. A monthly heatmap gives a longer-term view of completion rates.

## Tech Stack
- **Flutter** 3.38.9 / **Dart** 3.10.8
- **Drift** 2.28.x — SQLite ORM (code-generated via build_runner)
- **Riverpod** 2.6.x — state management (StreamProvider + Provider)
- **flutter_local_notifications** 18.x — next-day reminders
- **timezone** 0.9.x — TZ-aware notification scheduling
- **intl** 0.20.x — date formatting

## Project Structure
```
lib/
├── main.dart                     # Entry: init notifications, ProviderScope
├── app.dart                      # MaterialApp, M3 theme, dark mode
├── database/
│   ├── app_database.dart         # @DriftDatabase + all queries
│   ├── app_database.g.dart       # Generated — do not edit
│   └── tables/
│       ├── habits_table.dart     # Habits schema
│       └── habit_logs_table.dart # HabitLogs schema (unique: habitId + date)
├── models/
│   └── habit_with_streak.dart    # Streak calc, 2-day miss warning
├── providers/
│   ├── database_provider.dart    # Provider<AppDatabase>
│   └── habits_provider.dart      # Stream providers + HabitsRepository
├── services/
│   └── notification_service.dart # Schedule / cancel per-habit reminders
└── screens/
    ├── home/
    │   ├── home_screen.dart      # TabBar: Week | Month
    │   └── widgets/
    │       ├── week_view.dart    # 7-day grid, toggle, long-press options
    │       ├── month_view.dart   # Heatmap calendar, month nav
    │       └── habit_row_tile.dart # Habit row with day chips + streak badge
    └── add_habit/
        └── add_habit_screen.dart # Create / edit habit form
```

## Development Setup
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # regenerate app_database.g.dart
flutter run
```

> **Note:** `build_runner` is pinned to `>=2.4.14 <2.6.0` because 2.6+ introduced
> AOT build hooks incompatible with `dart compile` in this SDK version.

## Key Commands
```bash
flutter run                          # run on connected device/emulator
flutter analyze                      # static analysis
flutter test                         # unit + widget tests
dart run build_runner build \
  --delete-conflicting-outputs       # regen Drift code after schema changes
flutter build apk --release          # production APK
```

## Architecture Notes
- **Database:** Two Drift tables — `Habits` (id, name, desc, color, icon, isActive) and `HabitLogs` (habitId, logDate — unique constraint). Toggling a day inserts or deletes a log row.
- **Streak:** Computed in `HabitWithStreak` by walking backwards from today through `completedDates`. No stored streak column.
- **Reminder logic:** `HabitsRepository.syncReminder()` checks if yesterday's log is absent; if so, schedules a notification for the next 8 AM via `NotificationService`. Called after every toggle.
- **2-day warning:** `HabitWithStreak.hasMissedTwoDays` — true when both yesterday and the day before have no log. Shown as an orange `!` badge replacing the streak count.
- **Core library desugaring** is enabled in `android/app/build.gradle.kts` (required by `flutter_local_notifications`).

## Sprint Workflow
Claude uses `.claude/sprints/` for task tracking:
- `.claude/sprints/current.md` — active sprint
- `.claude/sprints/backlog.md` — upcoming work
- `.claude/sprints/archive/` — completed sprints

Use `/claude-developer --reset-sprint` to archive and start fresh.
