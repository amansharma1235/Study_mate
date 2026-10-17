import 'dart:async';

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

  const PomodoroState({
    required this.mode,
    required this.status,
    required this.totalDurationSeconds,
    required this.remainingSeconds,
    required this.completedFocusSessions,
    required this.selectedSubject,
    this.targetEndTime,
    this.hasRecordedCompletion = false,
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
        ),
      );

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

    _startTicker();
  }

  void pause() {
    if (state.status != TimerStateStatus.running) return;
    _ticker?.cancel();

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
    state = state.copyWith(
      status: TimerStateStatus.initial,
      remainingSeconds: state.totalDurationSeconds,
      clearTargetEndTime: true,
      hasRecordedCompletion: false,
    );
  }

  void skip() {
    _ticker?.cancel();
    _advanceToNextMode();
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
      }
    });
  }

  Future<void> _onSessionComplete() async {
    _ticker?.cancel();

    if (state.hasRecordedCompletion) return; // Prevent duplicate completion

    state = state.copyWith(
      status: TimerStateStatus.completed,
      remainingSeconds: 0,
      clearTargetEndTime: true,
      hasRecordedCompletion: true,
    );

    // Show completion notification
    final isFocus = state.mode == PomodoroMode.focus;
    final title = isFocus ? 'Focus Session Completed! 🎉' : 'Break Finished!';
    final body = isFocus
        ? 'Great job on ${state.selectedSubject}. Time for a well-deserved rest.'
        : 'Ready for another round of productive study?';

    _notificationService.showNotification(id: 9999, title: title, body: body);

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
