# Sprint — 2026-06-08

**Goal:** Ship Phase 1 — working habit tracker on Android with week view, streaks, and reminders.

## In Progress

## Todo
- [x] Test on physical device [type: chore]
- [x] App icon + splash screen [type: feature]
- [x] Habit detail screen (tap habit → full monthly calendar for that habit) [type: feature]

## Done
- [x] Flutter project scaffold
- [x] Drift DB (Habits + HabitLogs tables)
- [x] Riverpod stream providers
- [x] Week view with 7-day toggle grid
- [x] Streak calculation + 2-day miss warning badge
- [x] Month heatmap view
- [x] Add/edit habit form (name, color, icon)
- [x] flutter_local_notifications next-day reminder
- [x] Core library desugaring fix for Android build
- [x] CLAUDE.md, .gitignore, push to GitHub

## Notes
- build_runner pinned to <2.6.0 (AOT hooks incompatibility with Dart 3.10.8)
- Core library desugaring required by flutter_local_notifications
