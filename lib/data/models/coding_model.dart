class CodingRoadmapTopic {
  final String id;
  final String language;
  final String title;
  final String description;
  final int estimatedHours;
  final List<String> concepts;
  final bool isCompleted;

  const CodingRoadmapTopic({
    required this.id,
    required this.language,
    required this.title,
    required this.description,
    required this.estimatedHours,
    required this.concepts,
    this.isCompleted = false,
  });
}

class CodingExerciseModel {
  final String id;
  final String language;
  final String title;
  final String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  final String description;
  final String starterCode;
  final String solutionCode;
  final String explanation;
  final List<String> testCases;
  final bool isSolved;

  const CodingExerciseModel({
    required this.id,
    required this.language,
    required this.title,
    required this.difficulty,
    required this.description,
    required this.starterCode,
    required this.solutionCode,
    required this.explanation,
    required this.testCases,
    this.isSolved = false,
  });
}

class InterviewQuestionModel {
  final String id;
  final String language;
  final String
  category; // 'Core', 'Data Structures', 'Algorithms', 'System Design'
  final String question;
  final String answer;
  final String codeExample;

  const InterviewQuestionModel({
    required this.id,
    required this.language,
    required this.category,
    required this.question,
    required this.answer,
    required this.codeExample,
  });
}
