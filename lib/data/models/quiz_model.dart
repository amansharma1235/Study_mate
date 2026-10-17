class QuizQuestion {
  final String id;
  final String category;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as String,
      category: map['category'] as String,
      question: map['question'] as String,
      options: List<String>.from(map['options'] as List),
      correctIndex: (map['correctIndex'] as num).toInt(),
      explanation: map['explanation'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}

class QuizAttempt {
  final String id;
  final String userId;
  final String category;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercentage;
  final DateTime completedAt;

  QuizAttempt({
    required this.id,
    required this.userId,
    required this.category,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'scorePercentage': scorePercentage,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      id: map['id'] as String,
      userId: (map['userId'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'General',
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (map['correctAnswers'] as num?)?.toInt() ?? 0,
      scorePercentage: (map['scorePercentage'] as num?)?.toDouble() ?? 0.0,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : DateTime.now(),
    );
  }
}

typedef QuizAttemptModel = QuizAttempt;
