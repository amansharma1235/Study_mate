import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/core/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('validateEmail returns error on invalid email format', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail('user@'), isNotNull);
      expect(Validators.validateEmail('@domain.com'), isNotNull);
      expect(Validators.validateEmail('student@university.edu'), isNull);
    });

    test('validatePassword validates minimum length requirement', () {
      expect(Validators.validatePassword(null), isNotNull);
      expect(Validators.validatePassword('12345'), isNotNull); // < 6 chars
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('securePass123'), isNull);
    });

    test('validateConfirmPassword checks equality', () {
      expect(Validators.validateConfirmPassword('pass1', 'pass2'), isNotNull);
      expect(Validators.validateConfirmPassword('pass123', 'pass123'), isNull);
    });

    test('validatePositiveNumber rejects negative values and invalid text', () {
      expect(Validators.validatePositiveNumber(''), isNotNull);
      expect(Validators.validatePositiveNumber('abc'), isNotNull);
      expect(Validators.validatePositiveNumber('-10'), isNotNull);
      expect(Validators.validatePositiveNumber('0'), isNull);
      expect(Validators.validatePositiveNumber('85.5'), isNull);
    });
  });
}
