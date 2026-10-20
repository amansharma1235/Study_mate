import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_profile_model.dart';
import '../../data/remote/auth_service.dart';
import '../../data/remote/sync_service.dart';
import '../exams/exams_controller.dart';
import '../flashcards/flashcards_controller.dart';
import '../home/home_controller.dart';
import '../notes/notes_controller.dart';
import '../planner/planner_controller.dart';
import '../syllabus/syllabus_controller.dart';
import '../tasks/tasks_controller.dart';
import '../timetable/timetable_controller.dart';
import '../timer/pomodoro_controller.dart';
import '../timer/timer_history_screen.dart';

final authStateProvider = StreamProvider<UserProfileModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges();
});

final currentProfileProvider = StateProvider<UserProfileModel?>((ref) => null);

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserProfileModel?>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return AuthController(authService, ref);
    });

class AuthController extends StateNotifier<AsyncValue<UserProfileModel?>> {
  final AuthService _authService;
  final Ref _ref;

  AuthController(this._authService, this._ref)
    : super(const AsyncValue.data(null)) {
    _init();
  }

  void _invalidateUserData() {
    _ref.invalidate(notesControllerProvider);
    _ref.invalidate(tasksControllerProvider);
    _ref.invalidate(examsControllerProvider);
    _ref.invalidate(upcomingExamsProvider);
    _ref.invalidate(timetableControllerProvider);
    _ref.invalidate(currentDayClassesProvider);
    _ref.invalidate(homeDashboardProvider);
    _ref.invalidate(flashcardDecksProvider);
    _ref.invalidate(syllabusTopicsProvider);
    _ref.invalidate(plannerControllerProvider);
    _ref.invalidate(studyHistoryProvider);
    _ref.invalidate(pomodoroControllerProvider);
  }

  Future<void> _init() async {
    final user = await _authService.getCurrentUser();
    state = AsyncValue.data(user);
    _ref.read(currentProfileProvider.notifier).state = user;
    if (user != null && user.uid.isNotEmpty) {
      _ref.read(syncStateProvider.notifier).triggerSync(user.uid);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
      _ref.read(currentProfileProvider.notifier).state = user;
      _invalidateUserData();
      if (user.uid.isNotEmpty) {
        _ref.read(syncStateProvider.notifier).triggerSync(user.uid);
      }
      return user;
    });
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authService.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );
      _ref.read(currentProfileProvider.notifier).state = user;
      _invalidateUserData();
      if (user.uid.isNotEmpty) {
        _ref.read(syncStateProvider.notifier).triggerSync(user.uid);
      }
      return user;
    });
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> sendEmailVerification() async {
    await _authService.sendEmailVerification();
  }

  Future<void> updateProfile({
    required String displayName,
    String? photoUrl,
    int? dailyGoalMinutes,
  }) async {
    await _authService.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      dailyGoalMinutes: dailyGoalMinutes,
    );
    final user = await _authService.getCurrentUser();
    state = AsyncValue.data(user);
    _ref.read(currentProfileProvider.notifier).state = user;
  }

  Future<void> logout() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
    _ref.read(currentProfileProvider.notifier).state = null;
    _invalidateUserData();
  }

  Future<void> deleteAccount({required String password}) async {
    await _authService.deleteAccount(password: password);
    state = const AsyncValue.data(null);
    _ref.read(currentProfileProvider.notifier).state = null;
    _invalidateUserData();
  }
}
