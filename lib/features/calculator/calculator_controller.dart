import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/calculator_model.dart';

// Single Percentage State
class PercentageCalculationState {
  final double? obtainedMarks;
  final double? maxMarks;
  final double? percentage;
  final String? error;

  const PercentageCalculationState({
    this.obtainedMarks,
    this.maxMarks,
    this.percentage,
    this.error,
  });
}

final percentageCalculatorProvider =
    StateNotifierProvider<
      PercentageCalculatorNotifier,
      PercentageCalculationState
    >((ref) {
      return PercentageCalculatorNotifier();
    });

class PercentageCalculatorNotifier
    extends StateNotifier<PercentageCalculationState> {
  PercentageCalculatorNotifier() : super(const PercentageCalculationState());

  void calculate(String obtainedStr, String maxStr) {
    final obtained = double.tryParse(obtainedStr.trim());
    final max = double.tryParse(maxStr.trim());

    if (obtained == null || max == null) {
      state = const PercentageCalculationState(
        error: 'Please enter valid numerical marks.',
      );
      return;
    }

    if (max <= 0) {
      state = const PercentageCalculationState(
        error: 'Maximum marks must be greater than zero.',
      );
      return;
    }

    if (obtained < 0) {
      state = const PercentageCalculationState(
        error: 'Obtained marks cannot be negative.',
      );
      return;
    }

    if (obtained > max) {
      state = const PercentageCalculationState(
        error: 'Obtained marks cannot exceed maximum possible marks.',
      );
      return;
    }

    final percentage = (obtained / max) * 100.0;
    state = PercentageCalculationState(
      obtainedMarks: obtained,
      maxMarks: max,
      percentage: percentage,
      error: null,
    );
  }

  void reset() {
    state = const PercentageCalculationState();
  }
}

// Multi-Subject Calculator State
final multiSubjectCalculatorProvider =
    StateNotifierProvider<MultiSubjectCalculatorNotifier, List<SubjectMark>>((
      ref,
    ) {
      return MultiSubjectCalculatorNotifier();
    });

class MultiSubjectCalculatorNotifier extends StateNotifier<List<SubjectMark>> {
  MultiSubjectCalculatorNotifier()
    : super([
        SubjectMark(
          subjectName: 'Mathematics',
          obtainedMarks: 85,
          maxMarks: 100,
        ),
        SubjectMark(
          subjectName: 'Computer Science',
          obtainedMarks: 92,
          maxMarks: 100,
        ),
        SubjectMark(subjectName: 'Physics', obtainedMarks: 78, maxMarks: 100),
      ]);

  void addSubject({
    String name = 'Subject',
    double obtained = 80,
    double max = 100,
  }) {
    state = [
      ...state,
      SubjectMark(subjectName: name, obtainedMarks: obtained, maxMarks: max),
    ];
  }

  void removeSubject(int index) {
    if (state.length <= 1) return; // Keep at least one subject
    final list = List<SubjectMark>.from(state);
    list.removeAt(index);
    state = list;
  }

  void updateSubject(int index, SubjectMark updated) {
    final list = List<SubjectMark>.from(state);
    list[index] = updated;
    state = list;
  }

  MultiSubjectCalculationResult calculateTotal() {
    double totalObtained = 0;
    double totalMax = 0;

    for (final s in state) {
      totalObtained += s.obtainedMarks;
      totalMax += s.maxMarks;
    }

    final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100.0 : 0.0;

    String grade = 'F';
    if (percentage >= 90) {
      grade = 'A+';
    } else if (percentage >= 80) {
      grade = 'A';
    } else if (percentage >= 70) {
      grade = 'B';
    } else if (percentage >= 60) {
      grade = 'C';
    } else if (percentage >= 50) {
      grade = 'D';
    }

    return MultiSubjectCalculationResult(
      totalObtained: totalObtained,
      totalMax: totalMax,
      overallPercentage: percentage,
      overallGrade: grade,
      subjectCount: state.length,
    );
  }

  void reset() {
    state = [
      SubjectMark(subjectName: 'Mathematics', obtainedMarks: 0, maxMarks: 100),
      SubjectMark(
        subjectName: 'Computer Science',
        obtainedMarks: 0,
        maxMarks: 100,
      ),
    ];
  }
}
