# Bug Log: Release Startup Hang (Timezone & Notification Block)

## Metadata
- **Status**: Fixed
- **Severity**: Critical (Blocks app boot/launch)
- **Date Discovered**: 2026-06-13
- **Date Resolved**: 2026-06-13
- **Target Platform**: Android (specifically observed on Android 13/14+ API 33+)

---

## Symptom
After installing the release build of the app, creating a habit, closing the app, and swiping it away from the background, the app hangs indefinitely on the splash/logo screen upon reopening.

---

## Root Causes

1. **Uninitialized Timezone Location (`StateError`):**
   The app uses timezone-aware notification scheduling (`tz.TZDateTime.now(tz.local)`). Although `tz.initializeTimeZones()` was called, the timezone package's local location (`tz.local`) was never set via `tz.setLocalLocation(...)`.
   - On the first boot, with an empty database, no habit-specific notifications were scheduled.
   - On the second boot, once a habit exists, Riverpod's database stream listener triggered `repo.syncProgressNotification` / `NotificationService.showTodayProgress` which attempted to read `tz.local`. This threw a `StateError` because the location was unconfigured.

2. **Blocked App Startup (`runApp` Not Called):**
   In `lib/main.dart`, the notification startup and initial schedule procedures were awaited directly:
   ```dart
   await NotificationService.init();
   await NotificationService.scheduleDailyReminder();
   runApp(...);
   ```
   An unhandled exception during these awaited initializations prevented `runApp()` from executing, freezing the Flutter application context and leaving the user stuck on the OS launch/splash screen.

---

## Resolution

### 1. Timezone Location Setup
Added the `flutter_timezone` dependency in `pubspec.yaml` to detect the device's local timezone. Added the following setup in `NotificationService.init()`:
```dart
try {
  final timezoneInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
} catch (e) {
  debugPrint('NotificationService: Failed to get local timezone, defaulting to UTC. Error: $e');
}
```

### 2. Guarded Notification Services
Wrapped all scheduled, triggered, and cancelled notification APIs inside `NotificationService` in safe `try-catch` blocks to protect against platform-channel crashes or permission-denial exceptions (such as Android 13/14 exact alarm restrictions).

### 3. Fail-Safe Main Boot
Modified `lib/main.dart` to catch any startup failures from the notification module and proceed with loading the UI:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.init();
    await NotificationService.scheduleDailyReminder();
  } catch (e) {
    debugPrint('Failed to initialize notifications on startup: $e');
  }
  runApp(const ProviderScope(child: HabitArcApp()));
}
```

---

## Verification
- Built a release APK using the `--no-tree-shake-icons` flag: `flutter build apk --release --no-tree-shake-icons`.
- Installed the APK, created a habit, force closed the app, and successfully verified that the app boots instantly on subsequent launches without hanging.
