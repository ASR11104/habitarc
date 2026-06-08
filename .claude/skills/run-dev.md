# run-dev

Start the app on a connected Android device or emulator.

## When to use
When asked to run, start, or preview the app during development.

## Execution
<command-instructions>
Ensure a device is connected (run `flutter devices` to check), then:

  flutter run

For a release build:
  flutter build apk --release

To regenerate Drift DB code after schema changes:
  dart run build_runner build --delete-conflicting-outputs
</command-instructions>
