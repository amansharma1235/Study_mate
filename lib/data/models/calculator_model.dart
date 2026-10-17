class SubjectMark {
  final String subjectName;
  final double obtainedMarks;
  final double maxMarks;

  SubjectMark({
    required this.subjectName,
    required this.obtainedMarks,
    required this.maxMarks,
  });

  double get percentage {
    if (maxMarks <= 0) return 0.0;
    return (obtainedMarks / maxMarks) * 100.0;
  }

  String get standardGrade {
    final p = percentage;
    if (p >= 90) return 'A+';
    if (p >= 80) return 'A';
    if (p >= 70) return 'B';
    if (p >= 60) return 'C';
    if (p >= 50) return 'D';
    return 'F';
  }

  SubjectMark copyWith({
    String? subjectName,
    double? obtainedMarks,
    double? maxMarks,
  }) {
    return SubjectMark(
      subjectName: subjectName ?? this.subjectName,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      maxMarks: maxMarks ?? this.maxMarks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'obtainedMarks': obtainedMarks,
      'maxMarks': maxMarks,
    };
  }

  factory SubjectMark.fromMap(Map<String, dynamic> map) {
    return SubjectMark(
      subjectName: map['subjectName'] as String,
      obtainedMarks: (map['obtainedMarks'] as num).toDouble(),
      maxMarks: (map['maxMarks'] as num).toDouble(),
    );
  }
}

class MultiSubjectCalculationResult {
  final double totalObtained;
  final double totalMax;
  final double overallPercentage;
  final String overallGrade;
  final int subjectCount;

  MultiSubjectCalculationResult({
    required this.totalObtained,
    required this.totalMax,
    required this.overallPercentage,
    required this.overallGrade,
    required this.subjectCount,
  });
}
