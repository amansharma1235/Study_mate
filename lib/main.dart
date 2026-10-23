import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/app_colors.dart';
import 'data/local/db_initializer.dart';
import 'core/services/analytics_service.dart';
import 'core/services/error_tracking_service.dart';
import 'data/local/notification_service.dart';
import 'data/local/preference_service.dart';
import 'data/remote/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize centralized error tracking service
  ErrorTrackingService.instance.init();

  // Production-grade graceful Error Widget instead of red/yellow screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 36),
              const SizedBox(height: 12),
              const Text(
                'Something encountered a minor issue',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                'StudyMate is running safely. Please return to the previous screen.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Initialize SQLite database factory for Desktop / FFI
  initDatabaseFactory();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize analytics telemetry
  await AnalyticsService.instance.init(sharedPreferences);

  // Initialize local notifications service
  await NotificationService.instance.init();

  // Initialize Firebase (safely handles missing google-services.json)
  await FirebaseService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const StudyMateApp(),
    ),
  );
}
