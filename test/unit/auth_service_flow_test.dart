import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/core/errors/app_exception.dart';
import 'package:study_mate/data/remote/auth_service.dart';
import 'package:study_mate/data/remote/firebase_service.dart';
import 'package:study_mate/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Firebase Credentials & Options Verification', () {
    test('DefaultFirebaseOptions contains correct Project ID and App ID', () {
      final options = DefaultFirebaseOptions.android;
      expect(options.projectId, equals('studymate-e8da6'));
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, contains('784115163650'));
      expect(options.storageBucket, contains('studymate-e8da6'));
    });
  });

  group('Auth Service Flow & Fallback Verification', () {
    test('AuthService registers local user successfully when offline', () async {
      final authService = AuthService(FirebaseService.instance);
      final uniqueEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      final profile = await authService.registerWithEmailAndPassword(
        name: 'Test Student',
        email: uniqueEmail,
        password: 'password123',
      );

      expect(profile.displayName, equals('Test Student'));
      expect(profile.email, equals(uniqueEmail));
      expect(profile.uid, isNotEmpty);
    });

    test('AuthService rejects duplicate registration with clean error', () async {
      final authService = AuthService(FirebaseService.instance);
      const email = 'duplicate@studymate.app';

      await authService.registerWithEmailAndPassword(
        name: 'First User',
        email: email,
        password: 'password123',
      );

      expect(
        () => authService.registerWithEmailAndPassword(
          name: 'Second User',
          email: email,
          password: 'password123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('AuthService logs in registered user and checks password', () async {
      final authService = AuthService(FirebaseService.instance);
      const email = 'aman@studymate.app';

      final user = await authService.loginWithEmailAndPassword(
        email: email,
        password: '123',
      );

      expect(user.displayName, equals('Aman'));
      expect(user.email, equals(email));

      // Wrong password throws AuthException
      expect(
        () => authService.loginWithEmailAndPassword(
          email: email,
          password: 'wrong_password',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('AuthService signOut clears active session', () async {
      final authService = AuthService(FirebaseService.instance);
      await authService.signOut();
      final current = await authService.getCurrentUser();
      expect(current, isNull);
    });
  });
}
