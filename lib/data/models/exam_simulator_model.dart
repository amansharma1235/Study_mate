class ExamSimQuestion {
  final String id;
  final String subject;
  final String subtopic;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  int? selectedOptionIndex;
  bool isMarkedForReview;
  int timeSpentSeconds;

  ExamSimQuestion({
    required this.id,
    required this.subject,
    required this.subtopic,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.selectedOptionIndex,
    this.isMarkedForReview = false,
    this.timeSpentSeconds = 0,
  });

  bool get isAttempted => selectedOptionIndex != null;
  bool get isCorrect => selectedOptionIndex == correctIndex;

  ExamSimQuestion copyWith({
    int? selectedOptionIndex,
    bool? isMarkedForReview,
    int? timeSpentSeconds,
  }) {
    return ExamSimQuestion(
      id: id,
      subject: subject,
      subtopic: subtopic,
      question: question,
      options: options,
      correctIndex: correctIndex,
      explanation: explanation,
      selectedOptionIndex: selectedOptionIndex ?? this.selectedOptionIndex,
      isMarkedForReview: isMarkedForReview ?? this.isMarkedForReview,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'subtopic': subtopic,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'selectedOptionIndex': selectedOptionIndex,
      'isMarkedForReview': isMarkedForReview,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  factory ExamSimQuestion.fromMap(Map<String, dynamic> map) {
    return ExamSimQuestion(
      id: map['id'] as String? ?? '',
      subject: map['subject'] as String? ?? 'General',
      subtopic: map['subtopic'] as String? ?? 'Core',
      question: map['question'] as String? ?? '',
      options: List<String>.from(map['options'] as List? ?? []),
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: map['explanation'] as String? ?? '',
      selectedOptionIndex: map['selectedOptionIndex'] as int?,
      isMarkedForReview: map['isMarkedForReview'] as bool? ?? false,
      timeSpentSeconds: (map['timeSpentSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExamSimConfig {
  final String title;
  final String subject;
  final int durationMinutes;
  final bool hasNegativeMarking;
  final int questionCount;
  final String difficulty;
  final String? customTopic;

  const ExamSimConfig({
    required this.title,
    required this.subject,
    this.durationMinutes = 15,
    this.hasNegativeMarking = true,
    this.questionCount = 10,
    this.difficulty = 'Medium',
    this.customTopic,
  });

  int get correctMarks => hasNegativeMarking ? 4 : 1;
  double get incorrectMarks => hasNegativeMarking ? -1.0 : 0.0;
  int get maxMarks => questionCount * correctMarks;
}

class SubtopicAccuracy {
  final String subtopic;
  final int totalQuestions;
  final int correctCount;

  const SubtopicAccuracy({
    required this.subtopic,
    required this.totalQuestions,
    required this.correctCount,
  });

  double get accuracy => totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;
}

class ExamSimResult {
  final String id;
  final String title;
  final String subject;
  final int totalQuestions;
  final int attemptedCount;
  final int correctCount;
  final int incorrectCount;
  final int unattemptedCount;
  final int markedReviewCount;
  final double scoreObtained;
  final double maxPossibleScore;
  final double percentage;
  final int totalTimeSpentSeconds;
  final List<SubtopicAccuracy> subtopicBreakdown;
  final List<String> weakSubtopics;
  final List<String> strongSubtopics;
  final String aiDiagnosis;
  final List<ExamSimQuestion> questions;
  final DateTime completedAt;

  const ExamSimResult({
    required this.id,
    required this.title,
    required this.subject,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.unattemptedCount,
    required this.markedReviewCount,
    required this.scoreObtained,
    required this.maxPossibleScore,
    required this.percentage,
    required this.totalTimeSpentSeconds,
    required this.subtopicBreakdown,
    required this.weakSubtopics,
    required this.strongSubtopics,
    required this.aiDiagnosis,
    required this.questions,
    required this.completedAt,
  });
}
