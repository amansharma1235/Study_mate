import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../data/local/notification_service.dart';
import '../../data/local/preference_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late bool _notificationsEnabled;
  bool _taskReminders = true;
  bool _examReminders = true;
  bool _timetableReminders = true;
  bool _timerReminders = true;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferenceServiceProvider);
    _notificationsEnabled = prefs.isNotificationsEnabled();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Notifications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          children: [
            // Master Permission Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              'Required for deadlines and timer alerts',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) async {
                          setState(() => _notificationsEnabled = val);
                          await ref
                              .read(preferenceServiceProvider)
                              .setNotificationsEnabled(val);
                          if (val) {
                            await ref
                                .read(notificationServiceProvider)
                                .requestPermissions();
                          } else {
                            await ref
                                .read(notificationServiceProvider)
                                .cancelAll();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space20),

            // Notification Categories
            AppCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _taskReminders && _notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Task Due Reminders',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Alerts prior to homework and assignment deadlines',
                      style: TextStyle(fontSize: 12),
                    ),
                    onChanged: _notificationsEnabled
                        ? (val) => setState(() => _taskReminders = val)
                        : null,
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: _examReminders && _notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Exam Countdown Alerts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Reminders ahead of exams, midterms, and finals',
                      style: TextStyle(fontSize: 12),
                    ),
                    onChanged: _notificationsEnabled
                        ? (val) => setState(() => _examReminders = val)
                        : null,
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: _timetableReminders && _notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Class Timetable Reminders',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Notifies you 10 minutes before class commences',
                      style: TextStyle(fontSize: 12),
                    ),
                    onChanged: _notificationsEnabled
                        ? (val) => setState(() => _timetableReminders = val)
                        : null,
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: _timerReminders && _notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Pomodoro Interval Completion',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Alert when focus duration or break finishes',
                      style: TextStyle(fontSize: 12),
                    ),
                    onChanged: _notificationsEnabled
                        ? (val) => setState(() => _timerReminders = val)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Test Immediate Notification Button
            AppButton(
              text: 'Send Test Notification (Immediate)',
              variant: AppButtonVariant.outline,
              icon: Icons.notifications_active_rounded,
              onPressed: () async {
                await ref
                    .read(notificationServiceProvider)
                    .showNotification(
                      id: 1111,
                      title: 'StudyMate Foreground Alert 🔔',
                      body: 'Your StudyMate notifications are working actively in foreground!',
                    );
                if (context.mounted) {
                  AppDialogs.showSnackBar(
                    context,
                    message: 'Foreground notification displayed!',
                    isSuccess: true,
                  );
                }
              },
            ),
            const SizedBox(height: 12),

            // Schedule Background Test (5s) Button
            AppButton(
              text: 'Test Background Notification (5s)',
              variant: AppButtonVariant.primary,
              icon: Icons.timer_outlined,
              onPressed: () async {
                final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
                await ref
                    .read(notificationServiceProvider)
                    .scheduleNotification(
                      id: 2222,
                      title: 'Background Study Alert! ⏰',
                      body: 'This notification fired while app is in background or screen is locked!',
                      scheduledDate: scheduledTime,
                    );
                if (context.mounted) {
                  AppDialogs.showSnackBar(
                    context,
                    message: 'Scheduled in 5s! Minimize or lock screen to test background alert.',
                    isSuccess: true,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
