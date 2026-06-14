# HabitArc

HabitArc is a sleek, modern Android habit-tracking application built with Flutter and Dart. It helps users form positive daily routines by tracking streaks, presenting completion rates across weekly and monthly (heatmap) views, and sending smart next-day local reminders if a habit is missed.

---

## 🚀 Key Features

- **Daily Habit Tracking:** Easily toggle completion logs for the current week.
- **Dynamic Streak Calculation:** Automatically computes current streaks and alerts you with a caution badge if you have missed a habit two days in a row.
- **Visual Completion Heatmaps:** Switch to the Month view to see completion consistency mapped out on a calendar heatmap.
- **Smart Next-Day Reminders:** Uses local notifications to schedule a next-day 8:00 AM reminder only if a habit is missed.
- **Daily Progress Notifications:** Displays a persistent/ongoing status notification in the shade showing your progress (e.g., "2 / 5 done") and lists pending habits.
- **Material 3 Design:** Sleek UI supporting both System Light and Dark modes.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (v3.38.9)
- **Language:** [Dart](https://dart.dev) (v3.x)
- **State Management:** [Riverpod](https://riverpod.dev) (v2.6.x) — StreamProvider + Provider
- **Local Database:** [Drift](https://drift.simonbinder.eu) (SQLite ORM) with code-generation
- **Local Notifications:** [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Timezones:** [timezone](https://pub.dev/packages/timezone) & [flutter_timezone](https://pub.dev/packages/flutter_timezone) for accurate local delivery

---

## 📂 Project Structure

```
lib/
├── main.dart                     # Entry point: initializes notifications & riverpod scope
├── app.dart                      # MaterialApp configuration (M3 themes & dark mode)
├── database/
│   ├── app_database.dart         # @DriftDatabase configuration and query definitions
│   ├── app_database.g.dart       # Generated SQLite mapping (generated via build_runner)
│   └── tables/
│       ├── habits_table.dart     # Habits schema (id, name, color, icon, isActive)
│       └── habit_logs_table.dart # Habit logs schema (unique: habitId + normalized date)
├── models/
│   └── habit_with_streak.dart    # Model that performs streak calculations & 2-day warnings
├── providers/
│   ├── database_provider.dart    # Riverpod provider for the SQLite DB
│   └── habits_provider.dart      # Streams, repositories, and state mutations
├── services/
│   └── notification_service.dart # Local notification setup, permissions, and schedulers
└── screens/
    ├── home/
    │   ├── home_screen.dart      # Navigation tab bar controller (Week | Month)
    │   └── widgets/
    │       ├── week_view.dart    # 7-day checklist grid & toggle handler
    │       ├── month_view.dart   # Monthly calendar completion heatmap
    │       └── habit_row_tile.dart # Individual habit tile rendering colors, icons, & streaks
    └── add_habit/
        └── add_habit_screen.dart # Habit creation and modification sheet
```

---

## 💻 Development Setup

### Prerequisites
Make sure you have the following installed on your machine:
- **Flutter SDK** (v3.38.9)
- **Java Development Kit (JDK 17)** (e.g., OpenJDK 17)
- **Android SDK** (with platform & command-line tools installed)
- A connected **physical Android device** (with USB debugging enabled) or an Android Emulator.

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/habitarc.git
   cd habitarc
   ```

2. **Fetch packages & dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Drift Database Code:**
   The SQLite helper files must be generated using `build_runner` before the app can compile:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Launch the application:**
   Ensure a device or emulator is active, then run:
   ```bash
   flutter run
   ```

---

## 📦 Building for Production

To generate a standalone release APK that you can distribute and install on any compatible Android device:

```bash
flutter build apk --release --no-tree-shake-icons
```

*Note: The `--no-tree-shake-icons` flag is required because the application allows users to dynamically assign variable `IconData` dynamically loaded from the database.*

The built APK will be saved at:
`build/app/outputs/flutter-apk/app-release.apk`