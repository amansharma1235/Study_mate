import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/pomodoro_session_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/timetable_model.dart';
import '../../data/repositories/exams_repository.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repositories/tasks_repository.dart';
import '../../data/repositories/timer_repository.dart';
import '../../data/repositories/timetable_repository.dart';
import '../auth/auth_controller.dart';
import '../exams/exams_controller.dart';
import '../home/home_controller.dart';
import '../notes/notes_controller.dart';
import '../tasks/tasks_controller.dart';
import '../timetable/timetable_controller.dart';

/// Database Backup & Restore Manager.
/// Supports exporting complete offline JSON archives and restoring them into the local database.
class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _importController = TextEditingController();

  String? _exportedJson;
  bool _isLoading = false;
  bool _isRestoring = false;

  int _noteCount = 0;
  int _taskCount = 0;
  int _timetableCount = 0;
  int _examCount = 0;
  int _sessionCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    super.dispose();
  }

  Future<void> _generateExport() async {
    setState(() => _isLoading = true);
    final user = ref.read(currentProfileProvider);
    final userId = user?.uid ?? 'guest';

    final notes = await ref.read(notesRepositoryProvider).getNotes(userId);
    final tasks = await ref.read(tasksRepositoryProvider).getTasks(userId);
    final timetable = await ref.read(timetableRepositoryProvider).getTimetable(userId);
    final exams = await ref.read(examsRepositoryProvider).getExams(userId);
    final sessions = await ref.read(timerRepositoryProvider).getSessions(userId);

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

  Future<void> _handleRestore() async {
    final rawJson = _importController.text.trim();
    if (rawJson.isEmpty) {
      AppDialogs.showSnackBar(context, message: 'Please paste a valid JSON backup archive.', isError: true);
      return;
    }

    Map<String, dynamic> backupData;
    try {
      backupData = jsonDecode(rawJson) as Map<String, dynamic>;
    } catch (e) {
      AppDialogs.showSnackBar(context, message: 'Invalid JSON format: $e', isError: true);
      return;
    }

    final rawNotes = backupData['notes'] as List<dynamic>? ?? [];
    final rawTasks = backupData['tasks'] as List<dynamic>? ?? [];
    final rawTimetable = backupData['timetable'] as List<dynamic>? ?? [];
    final rawExams = backupData['exams'] as List<dynamic>? ?? [];
    final rawSessions = backupData['pomodoroSessions'] as List<dynamic>? ?? [];

    final confirm = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Confirm Database Restore',
      message: 'Found:\n'
          '• ${rawNotes.length} Notes\n'
          '• ${rawTasks.length} Tasks\n'
          '• ${rawTimetable.length} Timetable classes\n'
          '• ${rawExams.length} Exams\n'
          '• ${rawSessions.length} Study sessions\n\n'
          'Do you want to import and merge these records into your database?',
      confirmText: 'Restore Records',
    );

    if (confirm != true) return;

    setState(() => _isRestoring = true);
    final user = ref.read(currentProfileProvider);
    final userId = user?.uid ?? 'guest';

    try {
      int restoredNotes = 0;
      int restoredTasks = 0;
      int restoredExams = 0;
      int restoredTimetable = 0;
      int restoredSessions = 0;

      // Restore Notes
      final notesRepo = ref.read(notesRepositoryProvider);
      for (final item in rawNotes) {
        try {
          final noteMap = Map<String, dynamic>.from(item as Map);
          noteMap['userId'] = userId;
          final note = NoteModel.fromMap(noteMap);
          await notesRepo.saveNote(note);
          restoredNotes++;
        } catch (_) {}
      }

      // Restore Tasks
      final tasksRepo = ref.read(tasksRepositoryProvider);
      for (final item in rawTasks) {
        try {
          final taskMap = Map<String, dynamic>.from(item as Map);
          taskMap['userId'] = userId;
          final task = TaskModel.fromMap(taskMap);
          await tasksRepo.saveTask(task);
          restoredTasks++;
        } catch (_) {}
      }

      // Restore Timetable
      final timetableRepo = ref.read(timetableRepositoryProvider);
      for (final item in rawTimetable) {
        try {
          final timeMap = Map<String, dynamic>.from(item as Map);
          timeMap['userId'] = userId;
          final entry = TimetableModel.fromMap(timeMap);
          await timetableRepo.saveTimetable(entry);
          restoredTimetable++;
        } catch (_) {}
      }

      // Restore Exams
      final examsRepo = ref.read(examsRepositoryProvider);
      for (final item in rawExams) {
        try {
          final examMap = Map<String, dynamic>.from(item as Map);
          examMap['userId'] = userId;
          final exam = ExamModel.fromMap(examMap);
          await examsRepo.saveExam(exam);
          restoredExams++;
        } catch (_) {}
      }

      // Restore Sessions
      final timerRepo = ref.read(timerRepositoryProvider);
      for (final item in rawSessions) {
        try {
          final sessMap = Map<String, dynamic>.from(item as Map);
          sessMap['userId'] = userId;
          final sess = PomodoroSessionModel.fromMap(sessMap);
          await timerRepo.recordSession(sess);
          restoredSessions++;
        } catch (_) {}
      }

      // Invalidate all providers so UI updates immediately
      ref.invalidate(notesControllerProvider);
      ref.invalidate(tasksControllerProvider);
      ref.invalidate(examsControllerProvider);
      ref.invalidate(timetableControllerProvider);
      ref.invalidate(homeDashboardProvider);

      if (!mounted) return;
      _importController.clear();
      AppDialogs.showSnackBar(
        context,
        message:
            'Restored $restoredNotes notes, $restoredTasks tasks, $restoredExams exams, $restoredTimetable classes, $restoredSessions study sessions!',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnackBar(context, message: 'Restore failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Database Backup & Restore'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.archive_outlined), text: 'Export Backup'),
            Tab(icon: Icon(Icons.unarchive_outlined), text: 'Restore Database'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Export Backup
          _buildExportTab(isDark),

          // Tab 2: Restore Database
          _buildRestoreTab(isDark),
        ],
      ),
    );
  }

  Widget _buildExportTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Complete Academic Backup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Export all your local notes, homework tasks, class timetables, exams, and Pomodoro history as formatted JSON to keep a portable offline archive.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• $_noteCount Notes\n• $_taskCount Tasks\n• $_timetableCount Timetable entries\n• $_examCount Exams\n• $_sessionCount Focus sessions',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                  const Divider(height: 24),
                  AppButton(
                    text: 'Copy Backup JSON to Clipboard',
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
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
    );
  }

  Widget _buildRestoreTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Restore Database from Archive',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Paste your exported JSON archive below. StudyMate will validate and merge all your notes, tasks, exams, and classes back into your offline SQLite database.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          TextField(
            controller: _importController,
            maxLines: 8,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Paste backup JSON content here (starts with {\n  "exportedAt": ...\n})...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && data!.text!.isNotEmpty) {
                      setState(() {
                        _importController.text = data.text!;
                      });
                      if (mounted) {
                        AppDialogs.showSnackBar(context, message: 'Pasted from clipboard!');
                      }
                    }
                  },
                  icon: const Icon(Icons.paste_rounded, size: 18),
                  label: const Text('Paste Clipboard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Inspect & Restore',
                  icon: Icons.restore_rounded,
                  isLoading: _isRestoring,
                  onPressed: _handleRestore,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
