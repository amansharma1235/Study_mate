import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_profile_model.dart';
import '../../data/remote/auth_service.dart';
import '../../data/remote/sync_service.dart';

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
  }

  Future<void> deleteAccount({required String password}) async {
    await _authService.deleteAccount(password: password);
    state = const AsyncValue.data(null);
    _ref.read(currentProfileProvider.notifier).state = null;
  }
}
