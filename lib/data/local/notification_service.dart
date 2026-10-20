import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService._init();

  static const String pomodoroChannelId = 'studymate_pomodoro_channel';
  static const String ongoingTimerChannelId = 'studymate_ongoing_timer_channel';
  static const String remindersChannelId = 'studymate_reminders_channel';
  static const String examsChannelId = 'studymate_exams_channel';

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Create Android Notification Channels with high priority for heads-up alerts
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidImpl != null) {
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              pomodoroChannelId,
              'Focus & Study Timer',
              description: 'Alerts when your Pomodoro study or break finishes',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );

          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              remindersChannelId,
              'Daily Study Briefing & Alarms',
              description: 'Morning study digest, tasks, and class timetable alarms',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );

          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              examsChannelId,
              'Exam Countdowns & Target Alerts',
              description: 'Upcoming exam milestones and preparation reminders',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );

          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              ongoingTimerChannelId,
              'Live Study Timer (Ongoing)',
              description: 'Shows active timer countdown on status bar and lockscreen',
              importance: Importance.low,
              playSound: false,
              enableVibration: false,
              showBadge: false,
            ),
          );
        }
      }

      _initialized = true;

      // Auto request permissions on startup so notifications work in background
      await requestPermissions();
    } catch (e) {
      debugPrint('Notification initialization notice: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? false;
      } else if (!kIsWeb && Platform.isIOS) {
        final iosImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  /// Show immediate notification (Foreground or Background)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = pomodoroChannelId,
    String? payload,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            channelId == pomodoroChannelId
                ? 'Focus & Study Timer'
                : 'StudyMate Reminders',
            channelDescription:
                'Notifications for tasks, exams, timetable and study timers',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error displaying notification: $e');
    }
  }

  /// Update sticky ongoing notification for active focus session on lockscreen/status bar
  Future<void> showOngoingTimerNotification({
    required int id,
    required String title,
    required String body,
    int? progress,
    int? maxProgress,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            ongoingTimerChannelId,
            'Live Study Timer (Ongoing)',
            channelDescription: 'Active study countdown',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: true,
            showProgress: maxProgress != null && progress != null,
            maxProgress: maxProgress ?? 100,
            progress: progress ?? 0,
            category: AndroidNotificationCategory.stopwatch,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error updating ongoing timer notification: $e');
    }
  }

  /// Schedule background notification at exact date & time (works even when app is locked/minimized)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String channelId = pomodoroChannelId,
    String? payload,
  }) async {
    try {
      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) return;

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            channelId == pomodoroChannelId
                ? 'Focus & Study Timer'
                : 'StudyMate Reminders',
            channelDescription:
                'Notifications for tasks, exams, timetable and study timers',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling background notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Automatically schedule daily morning student briefing (8:00 AM)
  Future<void> scheduleDailyMorningBriefing() async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 8, 0);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await scheduleNotification(
        id: 8888,
        title: 'Good Morning Scholar! ☀️',
        body: 'Your StudyMate timetable and goals are ready. Let\'s make today count!',
        scheduledDate: scheduledDate,
        channelId: remindersChannelId,
      );
    } catch (e) {
      debugPrint('Error scheduling morning briefing: $e');
    }
  }

  /// Schedule target reminder 24 hours before an upcoming exam
  Future<void> scheduleExamReminder({
    required int examId,
    required String examTitle,
    required DateTime examDate,
  }) async {
    try {
      final reminderTime = examDate.subtract(const Duration(days: 1));
      if (reminderTime.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: 7000 + (examId % 1000),
          title: 'Exam Target Alert: $examTitle 🎯',
          body: 'Your exam is tomorrow! Review high-yield formulas and active recall flashcards.',
          scheduledDate: reminderTime,
          channelId: examsChannelId,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling exam reminder: $e');
    }
  }
}
