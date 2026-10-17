import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../data/local/app_database.dart';
import '../auth/auth_controller.dart';

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  String? _exportedJson;
  bool _isLoading = false;
  int _noteCount = 0;
  int _taskCount = 0;
  int _timetableCount = 0;
  int _examCount = 0;
  int _sessionCount = 0;

  Future<void> _generateExport() async {
    setState(() => _isLoading = true);
    final user = ref.read(currentProfileProvider);
    final userId = user?.uid ?? 'guest';
    final db = ref.read(appDatabaseProvider);

    final notes = await db.getNotes(userId);
    final tasks = await db.getTasks(userId);
    final timetable = await db.getTimetable(userId);
    final exams = await db.getExams(userId);
    final sessions = await db.getSessions(userId);

    final exportMap = {
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'StudyMate',
      'version': '1.0.0',
      'user': {
        'uid': userId,
        'email': user?.email ?? 'offline',
        'displayName': user?.displayName ?? 'Student',
      },
      'notes': notes.map((n) => n.toMap()).toList(),
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'timetable': timetable.map((c) => c.toMap()).toList(),
      'exams': exams.map((e) => e.toMap()).toList(),
      'pomodoroSessions': sessions.map((s) => s.toMap()).toList(),
    };

    final encoder = const JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(exportMap);

    if (mounted) {
      setState(() {
        _exportedJson = formatted;
        _noteCount = notes.length;
        _taskCount = tasks.length;
        _timetableCount = timetable.length;
        _examCount = exams.length;
        _sessionCount = sessions.length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Export My Data')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Complete Academic Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Export all your local and synchronized records as formatted JSON text to keep a portable offline archive.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppDimensions.space20),

            AppButton(
              text: 'Generate Export Archive',
              icon: Icons.archive_outlined,
              isLoading: _isLoading,
              onPressed: _generateExport,
            ),
            const SizedBox(height: AppDimensions.space24),

            if (_exportedJson != null) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Archive Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '• $_noteCount Notes\n• $_taskCount Tasks\n• $_timetableCount Timetable entries\n• $_examCount Exams\n• $_sessionCount Focus sessions',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                    ),
                    const Divider(height: 24),
                    AppButton(
                      text: 'Copy Full JSON to Clipboard',
                      icon: Icons.copy_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _exportedJson!));
                        AppDialogs.showSnackBar(
                          context,
                          message: 'JSON backup copied to clipboard!',
                          isSuccess: true,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _exportedJson!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
