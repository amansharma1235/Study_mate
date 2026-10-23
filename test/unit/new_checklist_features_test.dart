import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/core/services/analytics_service.dart';
import 'package:study_mate/core/services/error_tracking_service.dart';
import 'package:study_mate/core/utils/rate_limiter.dart';

void main() {
  group('RateLimiter Unit Tests', () {
    setUp(() {
      RateLimiter.instance.reset('test_action');
      RateLimiter.instance.reset('test_throttle');
    });

    test('checkLimit allows requests up to maxAttempts and rejects excess', () {
      final limiter = RateLimiter.instance;

      final res1 = limiter.checkLimit('test_action', maxAttempts: 2);
      expect(res1.isAllowed, isTrue);
      expect(res1.remainingAttempts, equals(1));

      final res2 = limiter.checkLimit('test_action', maxAttempts: 2);
      expect(res2.isAllowed, isTrue);
      expect(res2.remainingAttempts, equals(0));

      // Third attempt must be blocked
      final res3 = limiter.checkLimit('test_action', maxAttempts: 2);
      expect(res3.isAllowed, isFalse);
      expect(res3.errorMessage, contains('Too many attempts'));
    });

    test('reset clears attempts for key', () {
      final limiter = RateLimiter.instance;

      limiter.checkLimit('test_action', maxAttempts: 1);
      final blocked = limiter.checkLimit('test_action', maxAttempts: 1);
      expect(blocked.isAllowed, isFalse);

      limiter.reset('test_action');
      final allowedAgain = limiter.checkLimit('test_action', maxAttempts: 1);
      expect(allowedAgain.isAllowed, isTrue);
    });

    test('throttle enforces cooldown period', () {
      final limiter = RateLimiter.instance;

      final call1 = limiter.throttle('test_throttle', cooldown: const Duration(seconds: 5));
      expect(call1.isAllowed, isTrue);

      final call2 = limiter.throttle('test_throttle', cooldown: const Duration(seconds: 5));
      expect(call2.isAllowed, isFalse);
      expect(call2.errorMessage, contains('Please wait'));
    });
  });

  group('AnalyticsService Unit Tests', () {
    test('records events and increments session summary counts', () {
      final analytics = AnalyticsService.instance;
      analytics.logEvent('quiz_completed', {'score': 90});

      final summary = analytics.getSummary();
      expect(summary.containsKey('quiz_completed'), isTrue);
      expect(summary['quiz_completed']! >= 1, isTrue);
    });

    test('logs screen views properly', () {
      final analytics = AnalyticsService.instance;
      analytics.logScreenView('NotesScreen');

      final summary = analytics.getSummary();
      expect(summary.containsKey('screen_view'), isTrue);
    });
  });

  group('ErrorTrackingService Unit Tests', () {
    test('captures and retains errors in recentErrors list', () {
      final errorService = ErrorTrackingService.instance;
      errorService.recordError(
        Exception('Network socket timeout test'),
        StackTrace.current,
        context: 'Unit test',
      );

      final errors = errorService.recentErrors;
      expect(errors.any((e) => e.message.contains('Network socket timeout test')), isTrue);
    });
  });
}
