import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/firebase_options.dart';

void main() {
  group('Firebase Options & Credentials Validation Tests', () {
    test('DefaultFirebaseOptions contains correct Project ID and App ID', () {
      final options = DefaultFirebaseOptions.android;
      expect(options.projectId, equals('studymate-e8da6'));
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, contains('784115163650'));
      expect(options.storageBucket, contains('studymate-e8da6'));
    });
  });
}
