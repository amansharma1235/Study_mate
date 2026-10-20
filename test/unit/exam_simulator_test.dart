import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/data/local/exam_simulator_service.dart';
import 'package:study_mate/data/models/exam_simulator_model.dart';
import 'package:study_mate/data/remote/gemini_service.dart';

class MockGeminiService extends Fake implements GeminiService {
  @override
  Future<GeminiResponse> generateContent({
    required String apiKey,
    required String prompt,
    String? systemInstruction,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    // Return empty to test resilient offline fallback
    throw Exception('Offline mode simulation');
  }
}

void main() {
  group('Exam Simulator Engine & Negative Marking Unit Tests', () {
    late ExamSimulatorService service;

    setUp(() {
      service = ExamSimulatorService(MockGeminiService());
    });

    test('Generates questions gracefully via offline bank when network offline', () async {
      const config = ExamSimConfig(
        title: 'CS Mock',
        subject: 'Computer Science',
        questionCount: 5,
        durationMinutes: 10,
        hasNegativeMarking: true,
      );

      final questions = await service.generateExamQuestions(config: config);
      expect(questions.length, 5);
      expect(questions.every((q) => q.options.length == 4), isTrue);
      expect(questions.every((q) => q.subtopic.isNotEmpty), isTrue);
    });

    test('Correctly computes +4 / -1 negative marking net score', () {
      const config = ExamSimConfig(
        title: 'JEE Mock Test',
        subject: 'Physics',
        questionCount: 4,
        hasNegativeMarking: true,
      );

      final questions = [
        ExamSimQuestion(
          id: '1',
          subject: 'Physics',
          subtopic: 'Mechanics',
          question: 'Q1',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          explanation: 'Sol',
          selectedOptionIndex: 0, // Correct (+4)
        ),
        ExamSimQuestion(
          id: '2',
          subject: 'Physics',
          subtopic: 'Mechanics',
          question: 'Q2',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 1,
          explanation: 'Sol',
          selectedOptionIndex: 2, // Incorrect (-1)
        ),
        ExamSimQuestion(
          id: '3',
          subject: 'Physics',
          subtopic: 'Thermodynamics',
          question: 'Q3',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 2,
          explanation: 'Sol',
          selectedOptionIndex: 2, // Correct (+4)
        ),
        ExamSimQuestion(
          id: '4',
          subject: 'Physics',
          subtopic: 'Thermodynamics',
          question: 'Q4',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 3,
          explanation: 'Sol',
          selectedOptionIndex: null, // Unattempted (0)
        ),
      ];

      final result = service.evaluateExam(
        config: config,
        questions: questions,
        totalTimeSpentSeconds: 300,
      );

      expect(result.attemptedCount, 3);
      expect(result.correctCount, 2);
      expect(result.incorrectCount, 1);
      expect(result.unattemptedCount, 1);
      // Net score: (2 * 4) - (1 * 1) = 7
      expect(result.scoreObtained, 7.0);
      // Max possible marks: 4 * 4 = 16
      expect(result.maxPossibleScore, 16.0);
      expect(result.percentage, (7.0 / 16.0) * 100);
      expect(result.aiDiagnosis.isNotEmpty, isTrue);
    });

    test('Subtopic breakdown flags weak subtopics below 50% accuracy', () {
      const config = ExamSimConfig(
        title: 'Diagnostic Test',
        subject: 'CS',
        questionCount: 3,
        hasNegativeMarking: false,
      );

      final questions = [
        ExamSimQuestion(
          id: '1',
          subject: 'CS',
          subtopic: 'Algorithms',
          question: 'Q1',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 0,
          explanation: 'Sol',
          selectedOptionIndex: 0, // Correct (100% Algorithms)
        ),
        ExamSimQuestion(
          id: '2',
          subject: 'CS',
          subtopic: 'Operating Systems',
          question: 'Q2',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 1,
          explanation: 'Sol',
          selectedOptionIndex: 3, // Incorrect (0% OS)
        ),
        ExamSimQuestion(
          id: '3',
          subject: 'CS',
          subtopic: 'Operating Systems',
          question: 'Q3',
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 2,
          explanation: 'Sol',
          selectedOptionIndex: 1, // Incorrect (0% OS)
        ),
      ];

      final result = service.evaluateExam(
        config: config,
        questions: questions,
        totalTimeSpentSeconds: 120,
      );

      expect(result.weakSubtopics.contains('Operating Systems'), isTrue);
      expect(result.strongSubtopics.contains('Algorithms'), isTrue);
      expect(result.aiDiagnosis.contains('Operating Systems'), isTrue);
    });
  });
}
