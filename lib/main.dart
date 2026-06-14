import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/notification_service.dart';

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
