import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/notification_service.dart';
import '../../data/local/preference_service.dart';
import '../../data/models/pomodoro_session_model.dart';
import '../../data/repositories/timer_repository.dart';
import '../auth/auth_controller.dart';

enum TimerStateStatus { initial, running, paused, completed }

class PomodoroState {
  final PomodoroMode mode;
  final TimerStateStatus status;
  final int totalDurationSeconds;
  final int remainingSeconds;
  final int completedFocusSessions;
  final String selectedSubject;
  final DateTime? targetEndTime;
  final bool hasRecordedCompletion;
  final bool isStrictMode;
  final bool hasWitheredAlert;

  const PomodoroState({
    required this.mode,
    required this.status,
    required this.totalDurationSeconds,
    required this.remainingSeconds,
    required this.completedFocusSessions,
    required this.selectedSubject,
    this.targetEndTime,
    this.hasRecordedCompletion = false,
    this.isStrictMode = false,
    this.hasWitheredAlert = false,
  });

  double get progress {
    if (totalDurationSeconds <= 0) return 0.0;
    final elapsed = totalDurationSeconds - remainingSeconds;
    return (elapsed / totalDurationSeconds).clamp(0.0, 1.0);
  }

  PomodoroState copyWith({
    PomodoroMode? mode,
    TimerStateStatus? status,
    int? totalDurationSeconds,
    int? remainingSeconds,
    int? completedFocusSessions,
    String? selectedSubject,
    DateTime? targetEndTime,
    bool clearTargetEndTime = false,
    bool? hasRecordedCompletion,
    bool? isStrictMode,
    bool? hasWitheredAlert,
  }) {
    return PomodoroState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedFocusSessions:
          completedFocusSessions ?? this.completedFocusSessions,
      selectedSubject: selectedSubject ?? this.selectedSubject,
      targetEndTime: clearTargetEndTime
          ? null
          : (targetEndTime ?? this.targetEndTime),
      hasRecordedCompletion:
          hasRecordedCompletion ?? this.hasRecordedCompletion,
      isStrictMode: isStrictMode ?? this.isStrictMode,
      hasWitheredAlert: hasWitheredAlert ?? this.hasWitheredAlert,
    );
  }
}

final pomodoroControllerProvider =
    StateNotifierProvider<PomodoroController, PomodoroState>((ref) {
      final prefs = ref.watch(preferenceServiceProvider);
      final repo = ref.watch(timerRepositoryProvider);
      final notif = ref.watch(notificationServiceProvider);
      final user = ref.watch(currentProfileProvider);
      final userId = user?.uid ?? 'guest';

      return PomodoroController(prefs, repo, notif, userId);
    });

class PomodoroController extends StateNotifier<PomodoroState> {
  final PreferenceService _prefs;
  final TimerRepository _repo;
  final NotificationService _notificationService;
  final String _userId;

  Timer? _ticker;

  PomodoroController(
    this._prefs,
    this._repo,
    this._notificationService,
    this._userId,
  ) : super(
        PomodoroState(
          mode: PomodoroMode.focus,
          status: TimerStateStatus.initial,
          totalDurationSeconds: _prefs.getPomodoroFocusMinutes() * 60,
          remainingSeconds: _prefs.getPomodoroFocusMinutes() * 60,
          completedFocusSessions: 0,
          selectedSubject: 'General Study',
          isStrictMode: _prefs.isStrictMode(),
        ),
      );

  Future<void> toggleStrictMode(bool enabled) async {
    await _prefs.setStrictMode(enabled);
    state = state.copyWith(isStrictMode: enabled);
  }

  void clearWitheredAlert() {
    state = state.copyWith(hasWitheredAlert: false);
  }

  void setSubject(String subject) {
    state = state.copyWith(selectedSubject: subject);
  }

  void setMode(PomodoroMode mode) {
    _ticker?.cancel();
    int minutes;
    switch (mode) {
      case PomodoroMode.focus:
        minutes = _prefs.getPomodoroFocusMinutes();
        break;
      case PomodoroMode.shortBreak:
        minutes = _prefs.getPomodoroShortBreakMinutes();
        break;
      case PomodoroMode.longBreak:
        minutes = _prefs.getPomodoroLongBreakMinutes();
        break;
    }

    final totalSeconds = minutes * 60;
    state = state.copyWith(
      mode: mode,
      status: TimerStateStatus.initial,
      totalDurationSeconds: totalSeconds,
      remainingSeconds: totalSeconds,
      clearTargetEndTime: true,
      hasRecordedCompletion: false,
    );
  }

  static const int ongoingNotificationId = 8888;

  void start() {
    if (state.status == TimerStateStatus.running) return;

    final targetEndTime = DateTime.now().add(
      Duration(seconds: state.remainingSeconds),
    );

    state = state.copyWith(
      status: TimerStateStatus.running,
      targetEndTime: targetEndTime,
      hasRecordedCompletion: false,
    );

    // Schedule background exact alarm / notification for when timer ends
    final isFocus = state.mode == PomodoroMode.focus;
    final notifTitle = isFocus ? 'Focus Session Completed! 🎉' : 'Break Finished! 🔔';
    final notifBody = isFocus
        ? 'Great job on ${state.selectedSubject}. Time for a well-deserved rest.'
        : 'Break is over. Ready for your next study session?';

    _notificationService.scheduleNotification(
      id: 9999,
      title: notifTitle,
      body: notifBody,
      scheduledDate: targetEndTime,
      channelId: NotificationService.pomodoroChannelId,
    );

    _updateOngoingNotification(state.remainingSeconds);
    _startTicker();
  }

  void pause() {
    if (state.status != TimerStateStatus.running) return;
    _ticker?.cancel();
    _notificationService.cancelNotification(9999);
    _notificationService.showOngoingTimerNotification(
      id: ongoingNotificationId,
      title: '⏸️ Paused: ${state.selectedSubject}',
      body: 'Timer is paused. Open app to resume.',
    );

    // Recalculate remaining seconds based on deadline
    if (state.targetEndTime != null) {
      final now = DateTime.now();
      final diff = state.targetEndTime!.difference(now).inSeconds;
      final remaining = diff.clamp(0, state.totalDurationSeconds);
      state = state.copyWith(
        status: TimerStateStatus.paused,
        remainingSeconds: remaining,
        clearTargetEndTime: true,
      );
    } else {
      state = state.copyWith(status: TimerStateStatus.paused);
    }
  }

  void resume() {
    if (state.status != TimerStateStatus.paused) return;
    start();
  }

  void reset() {
    _ticker?.cancel();
    _notificationService.cancelNotification(9999);
    _notificationService.cancelNotification(ongoingNotificationId);
    state = state.copyWith(
      status: TimerStateStatus.initial,
      remainingSeconds: state.totalDurationSeconds,
      clearTargetEndTime: true,
      hasRecordedCompletion: false,
    );
  }

  void skip() {
    _ticker?.cancel();
    _notificationService.cancelNotification(9999);
    _notificationService.cancelNotification(ongoingNotificationId);
    _advanceToNextMode();
  }

  Future<void> checkAppPaused() async {
    if (state.status == TimerStateStatus.running &&
        state.mode == PomodoroMode.focus &&
        state.isStrictMode) {
      // User broke focus in strict mode!
      _ticker?.cancel();
      _notificationService.cancelNotification(9999);
      _notificationService.cancelNotification(ongoingNotificationId);

      // Record withered tree in Garden
      final treeRecord = jsonEncode({
        'id': const Uuid().v4(),
        'species': 'withered_bush',
        'subject': state.selectedSubject,
        'durationMinutes':
            (state.totalDurationSeconds - state.remainingSeconds) ~/ 60,
        'isWithered': true,
        'plantedAt': DateTime.now().toIso8601String(),
      });
      await _prefs.addPlantedTreeRecord(treeRecord);

      // Reset timer & trigger alert
      state = state.copyWith(
        status: TimerStateStatus.initial,
        remainingSeconds: state.totalDurationSeconds,
        clearTargetEndTime: true,
        hasRecordedCompletion: false,
        hasWitheredAlert: true,
      );

      _notificationService.showNotification(
        id: 7777,
        title: '⚠️ Focus Broken! Tree Withered 🥀',
        body:
            'You left StudyMate during Strict Deep Focus. Your tree in the Garden withered!',
        channelId: NotificationService.pomodoroChannelId,
      );
    }
  }

  void checkAppResumed() {
    // When returning from background, recalculate remaining seconds from deadline
    if (state.status == TimerStateStatus.running &&
        state.targetEndTime != null) {
      final now = DateTime.now();
      final remaining = state.targetEndTime!.difference(now).inSeconds;

      if (remaining <= 0) {
        _onSessionComplete();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.targetEndTime == null) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final remaining = state.targetEndTime!.difference(now).inSeconds;

      if (remaining <= 0) {
        timer.cancel();
        _onSessionComplete();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
        // Sync ongoing notification every 5 seconds to minimize battery consumption
        if (remaining % 5 == 0) {
          _updateOngoingNotification(remaining);
        }
      }
    });
  }

  void _updateOngoingNotification(int remaining) {
    final mins = remaining ~/ 60;
    final secs = (remaining % 60).toString().padLeft(2, '0');
    final isFocus = state.mode == PomodoroMode.focus;
    final modeLabel = isFocus ? 'Focus' : 'Break';
    final progress = state.totalDurationSeconds > 0
        ? ((state.totalDurationSeconds - remaining) / state.totalDurationSeconds * 100).toInt()
        : 0;

    _notificationService.showOngoingTimerNotification(
      id: ongoingNotificationId,
      title: '⏱️ $modeLabel: ${state.selectedSubject} ($mins:$secs)',
      body: '$mins min $secs sec remaining • Focus session active',
      progress: progress,
      maxProgress: 100,
    );
  }

  Future<void> _onSessionComplete() async {
    _ticker?.cancel();
    _notificationService.cancelNotification(ongoingNotificationId);

    if (state.hasRecordedCompletion) return; // Prevent duplicate completion

    state = state.copyWith(
      status: TimerStateStatus.completed,
      remainingSeconds: 0,
      clearTargetEndTime: true,
      hasRecordedCompletion: true,
    );

    // Show completion notification
    final isFocus = state.mode == PomodoroMode.focus;
    final title = isFocus ? 'Focus Session Completed! 🎉' : 'Break Finished! 🔔';
    final body = isFocus
        ? 'Great job on ${state.selectedSubject}! Earned +50 XP & +10 Coins 🪙. A new tree grew in your Garden 🌳!'
        : 'Ready for another round of productive study?';

    _notificationService.showNotification(
      id: 9999,
      title: title,
      body: body,
      channelId: NotificationService.pomodoroChannelId,
    );

    // Record session if it was a focus session
    if (isFocus) {
      final sessionModel = PomodoroSessionModel(
        id: const Uuid().v4(),
        userId: _userId,
        subject: state.selectedSubject,
        durationMinutes: state.totalDurationSeconds ~/ 60,
        mode: state.mode,
        completedAt: DateTime.now(),
      );

      await _repo.recordSession(sessionModel);
      await _prefs.incrementCompletedPomodoroCount();
      await _prefs.setUserXp(_prefs.getUserXp() + 50);
      await _prefs.addStudyCoins(10);

      // Plant tree in Virtual Study Garden
      final treeSpecies = _prefs.getSelectedTreeId();
      final treeRecord = jsonEncode({
        'id': const Uuid().v4(),
        'species': treeSpecies,
        'subject': state.selectedSubject,
        'durationMinutes': state.totalDurationSeconds ~/ 60,
        'plantedAt': DateTime.now().toIso8601String(),
      });
      await _prefs.addPlantedTreeRecord(treeRecord);
    }

    _advanceToNextMode();
  }

  void _advanceToNextMode() {
    int newCompleted = state.completedFocusSessions;
    PomodoroMode nextMode;

    if (state.mode == PomodoroMode.focus) {
      newCompleted++;
      final sessionsBeforeLongBreak = _prefs.getSessionsBeforeLongBreak();
      if (newCompleted % sessionsBeforeLongBreak == 0) {
        nextMode = PomodoroMode.longBreak;
      } else {
        nextMode = PomodoroMode.shortBreak;
      }
    } else {
      nextMode = PomodoroMode.focus;
    }

    int durationMinutes;
    switch (nextMode) {
      case PomodoroMode.focus:
        durationMinutes = _prefs.getPomodoroFocusMinutes();
        break;
      case PomodoroMode.shortBreak:
        durationMinutes = _prefs.getPomodoroShortBreakMinutes();
        break;
      case PomodoroMode.longBreak:
        durationMinutes = _prefs.getPomodoroLongBreakMinutes();
        break;
    }

    final totalSecs = durationMinutes * 60;
    state = state.copyWith(
      mode: nextMode,
      status: TimerStateStatus.initial,
      totalDurationSeconds: totalSecs,
      remainingSeconds: totalSecs,
      completedFocusSessions: newCompleted,
      clearTargetEndTime: true,
      hasRecordedCompletion: false,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
