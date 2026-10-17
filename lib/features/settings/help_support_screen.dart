import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialogs.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'q': 'How does offline mode and synchronization work?',
      'a': 'StudyMate is built offline-first using a local SQLite database. All your notes, tasks, exams, and timer sessions are immediately saved locally. When connected and signed in, records synchronize to Cloud Firestore.',
    },
    {
      'q': 'How does the Pomodoro study timer calculate remaining time?',
      'a': 'Unlike basic counters that fail when backgrounded, StudyMate calculates elapsed time using exact deadline timestamps. When returning to the app from the background, the timer instantly synchronizes and checks whether your session completed.',
    },
    {
      'q': 'Are notifications guaranteed on Android?',
      'a': 'Yes, StudyMate uses flutter_local_notifications configured for Android exact alarms. Ensure notification permissions are granted in Notification Settings.',
    },
    {
      'q': 'Can I backup and export my records?',
      'a': 'Yes! Visit Settings > Data Export to download all your notes, tasks, exams, and study logs in structured JSON format.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Support Card
            AppCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Assistance?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'support@studymate.app',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Copy Email',
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: 'support@studymate.app'),
                      );
                      AppDialogs.showSnackBar(
                        context,
                        message: 'Support email copied!',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),

            // FAQs list
            ..._faqs.map((faq) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    title: Text(
                      faq['q']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    children: [
                      Text(
                        faq['a']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
