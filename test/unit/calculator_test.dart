import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/data/models/calculator_model.dart';
import 'package:study_mate/features/calculator/calculator_controller.dart';

void main() {
  group('Calculator Logic Unit Tests', () {
    test('Calculates exact percentage accurately', () {
      final notifier = PercentageCalculatorNotifier();
      notifier.calculate('80', '100');
      expect(notifier.state.percentage, 80.0);
      expect(notifier.state.error, isNull);

      notifier.calculate('45', '60');
      expect(notifier.state.percentage, 75.0);
    });

    test('Prevents division by zero in percentage calculation', () {
      final notifier = PercentageCalculatorNotifier();
      notifier.calculate('50', '0');
      expect(notifier.state.percentage, isNull);
      expect(notifier.state.error, contains('greater than zero'));
    });

    test('Rejects negative numbers and impossible marks', () {
      final notifier = PercentageCalculatorNotifier();
      notifier.calculate('-5', '100');
      expect(notifier.state.error, contains('cannot be negative'));

      notifier.calculate('105', '100');
      expect(notifier.state.error, contains('cannot exceed'));
    });

    test('Multi-subject calculator calculates cumulative total, percentage, and letter grade', () {
      final notifier = MultiSubjectCalculatorNotifier();
      notifier.reset(); // Mathematics 0/100, Computer Science 0/100
      notifier.updateSubject(
        0,
        SubjectMark(subjectName: 'Math', obtainedMarks: 90, maxMarks: 100),
      );
      notifier.updateSubject(
        1,
        SubjectMark(subjectName: 'CS', obtainedMarks: 95, maxMarks: 100),
      );

      final result = notifier.calculateTotal();
      expect(result.totalObtained, 185.0);
      expect(result.totalMax, 200.0);
      expect(result.overallPercentage, 92.5);
      expect(result.overallGrade, 'A+');
    });
  });
}
