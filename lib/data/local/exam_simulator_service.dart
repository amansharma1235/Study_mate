import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../models/exam_simulator_model.dart';
import '../remote/gemini_service.dart';

final examSimulatorServiceProvider = Provider<ExamSimulatorService>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  return ExamSimulatorService(gemini);
});

class ExamSimulatorService {
  final GeminiService _geminiService;
  final _uuid = const Uuid();

  ExamSimulatorService(this._geminiService);

  /// Generates mock exam questions using Gemini AI, with offline fallback.
  Future<List<ExamSimQuestion>> generateExamQuestions({
    required ExamSimConfig config,
  }) async {
    final subject = config.subject;
    final topic = config.customTopic?.trim();
    final count = config.questionCount;
    final difficulty = config.difficulty;

    final keyToUse = AppConstants.defaultGeminiApiKey.trim();
    if (keyToUse.isNotEmpty) {
      try {
        final prompt = '''
Generate an academic mock exam test with exactly $count multiple choice questions.
Subject: $subject
Specific Focus: ${topic != null && topic.isNotEmpty ? topic : "Comprehensive $subject curriculum"}
Difficulty Level: $difficulty

Return ONLY a valid JSON array of objects. Do not wrap in markdown quotes if possible, or use standard ```json ... ```.
Each JSON object must have:
- "question": string (concise, clear problem or conceptual question)
- "subtopic": string (e.g. "Kinematics", "Recursion", "Calculus", "Memory Management")
- "options": array of exactly 4 strings
- "correctIndex": integer (0, 1, 2, or 3)
- "explanation": string (1-2 sentence solution explanation)
''';

        final response = await _geminiService.generateContent(
          prompt: prompt,
          apiKey: keyToUse,
        );

      final text = response.text.trim();
      List<dynamic>? parsedList;

      // Extract JSON array
      final startIdx = text.indexOf('[');
      final endIdx = text.lastIndexOf(']');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        final jsonStr = text.substring(startIdx, endIdx + 1);
        parsedList = jsonDecode(jsonStr) as List<dynamic>;
      }

      if (parsedList != null && parsedList.isNotEmpty) {
        final questions = <ExamSimQuestion>[];
        for (final item in parsedList) {
          if (item is Map<String, dynamic>) {
            final opts = List<String>.from(item['options'] as List? ?? []);
            if (opts.length >= 4) {
              questions.add(
                ExamSimQuestion(
                  id: _uuid.v4(),
                  subject: subject,
                  subtopic: item['subtopic'] as String? ?? 'Core Concept',
                  question: item['question'] as String? ?? '',
                  options: opts.sublist(0, 4),
                  correctIndex: (item['correctIndex'] as num?)?.toInt() ?? 0,
                  explanation: item['explanation'] as String? ?? '',
                ),
              );
            }
          }
        }
        if (questions.length >= count) {
          return questions.sublist(0, count);
        } else if (questions.isNotEmpty) {
          // Fill remaining with offline questions
          final offline = _getOfflineBank(subject, topic);
          offline.shuffle();
          questions.addAll(offline.take(count - questions.length));
          return questions;
        }
      }
    } catch (_) {
      // Offline fallback
    }
    }

    // Curated high-yield offline question bank
    final bank = _getOfflineBank(subject, topic);
    bank.shuffle();
    if (bank.length >= count) {
      return bank.sublist(0, count);
    }
    return bank;
  }

  /// Calculates net score, negative marks, and subtopic diagnosis
  ExamSimResult evaluateExam({
    required ExamSimConfig config,
    required List<ExamSimQuestion> questions,
    required int totalTimeSpentSeconds,
  }) {
    int attempted = 0;
    int correct = 0;
    int incorrect = 0;
    int markedForReview = 0;

    final subtopicMap = <String, List<bool>>{};

    for (final q in questions) {
      if (q.isMarkedForReview) markedForReview++;

      final sub = q.subtopic.trim().isEmpty ? 'General' : q.subtopic.trim();
      subtopicMap.putIfAbsent(sub, () => []);

      if (q.isAttempted) {
        attempted++;
        if (q.isCorrect) {
          correct++;
          subtopicMap[sub]!.add(true);
        } else {
          incorrect++;
          subtopicMap[sub]!.add(false);
        }
      } else {
        subtopicMap[sub]!.add(false);
      }
    }

    final unattempted = questions.length - attempted;

    // Score calculation
    double score = 0;
    if (config.hasNegativeMarking) {
      score = (correct * 4.0) - (incorrect * 1.0);
    } else {
      score = correct * 1.0;
    }
    // Prevent negative score if desired or keep net marks
    if (score < 0) score = 0.0;

    final maxPossible = config.maxMarks.toDouble();
    final percentage = maxPossible > 0 ? (score / maxPossible) * 100 : 0.0;

    // Subtopic breakdown
    final subtopicBreakdown = <SubtopicAccuracy>[];
    final weakList = <String>[];
    final strongList = <String>[];

    subtopicMap.forEach((sub, results) {
      final subTotal = results.length;
      final subCorrect = results.where((r) => r).length;
      final accuracy = SubtopicAccuracy(
        subtopic: sub,
        totalQuestions: subTotal,
        correctCount: subCorrect,
      );
      subtopicBreakdown.add(accuracy);

      if (accuracy.accuracy < 50.0) {
        weakList.add(sub);
      } else if (accuracy.accuracy >= 75.0) {
        strongList.add(sub);
      }
    });

    // AI Diagnosis synthesis
    String aiDiagnosis;
    if (weakList.isNotEmpty) {
      final weakStr = weakList.take(2).join(' & ');
      aiDiagnosis =
          'Targeted Focus: You scored low in "$weakStr". We strongly recommend reviewing related theory notes and solving 5 practice problems within 24 hours to reinforce memory retention.';
    } else if (unattempted > questions.length ~/ 2) {
      aiDiagnosis =
          'Time Management Alert: Over 50% of questions remained unattempted. Work on speed drills and question triage during your next mock.';
    } else {
      aiDiagnosis =
          'Outstanding Mastery! You demonstrated solid conceptual understanding across all tested topics. Maintain this revision pace for optimal exam retention.';
    }

    return ExamSimResult(
      id: _uuid.v4(),
      title: config.title,
      subject: config.subject,
      totalQuestions: questions.length,
      attemptedCount: attempted,
      correctCount: correct,
      incorrectCount: incorrect,
      unattemptedCount: unattempted,
      markedReviewCount: markedForReview,
      scoreObtained: score,
      maxPossibleScore: maxPossible,
      percentage: percentage.clamp(0.0, 100.0),
      totalTimeSpentSeconds: totalTimeSpentSeconds,
      subtopicBreakdown: subtopicBreakdown,
      weakSubtopics: weakList,
      strongSubtopics: strongList,
      aiDiagnosis: aiDiagnosis,
      questions: questions,
      completedAt: DateTime.now(),
    );
  }

  /// High-yield offline academic question bank
  List<ExamSimQuestion> _getOfflineBank(String subject, String? topic) {
    final sub = subject.toLowerCase();
    if (sub.contains('cs') || sub.contains('code') || sub.contains('computer') || sub.contains('tech')) {
      return _csQuestions;
    } else if (sub.contains('math') || sub.contains('calculus') || sub.contains('algebra')) {
      return _mathQuestions;
    } else if (sub.contains('physic') || sub.contains('science') || sub.contains('mech')) {
      return _physicsQuestions;
    } else if (sub.contains('aptitude') || sub.contains('reasoning') || sub.contains('general')) {
      return _aptitudeQuestions;
    }

    // Default mixed comprehensive bank
    final list = <ExamSimQuestion>[
      ..._csQuestions,
      ..._physicsQuestions,
      ..._mathQuestions,
      ..._aptitudeQuestions,
    ];
    return list;
  }

  final List<ExamSimQuestion> _csQuestions = [
    ExamSimQuestion(
      id: 'cs-1',
      subject: 'Computer Science',
      subtopic: 'Data Structures',
      question: 'What is the worst-case time complexity of searching in a Balanced Binary Search Tree (AVL Tree)?',
      options: ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
      correctIndex: 1,
      explanation: 'AVL trees maintain height balance within +/- 1, guaranteeing logarithmic O(log n) search depth even in worst-case.',
    ),
    ExamSimQuestion(
      id: 'cs-2',
      subject: 'Computer Science',
      subtopic: 'Operating Systems',
      question: 'Which of the following conditions is NOT required for a deadlock to occur in an OS?',
      options: ['Mutual Exclusion', 'Preemption Allowed', 'Hold and Wait', 'Circular Wait'],
      correctIndex: 1,
      explanation: 'Deadlock requires NO preemption. If resource preemption is allowed, deadlock cannot occur.',
    ),
    ExamSimQuestion(
      id: 'cs-3',
      subject: 'Computer Science',
      subtopic: 'Algorithms',
      question: 'Which sorting algorithm has an average time complexity of O(n log n) and is NOT in-place by default?',
      options: ['Heap Sort', 'Quick Sort', 'Merge Sort', 'Bubble Sort'],
      correctIndex: 2,
      explanation: 'Merge Sort requires O(n) auxiliary memory space to merge subarrays, making it not in-place.',
    ),
    ExamSimQuestion(
      id: 'cs-4',
      subject: 'Computer Science',
      subtopic: 'Database Management',
      question: 'Which normal form eliminates transitive functional dependencies on the primary key?',
      options: ['1NF', '2NF', '3NF', 'BCNF'],
      correctIndex: 2,
      explanation: '3NF ensures that every non-prime attribute is non-transitively dependent on every candidate key.',
    ),
    ExamSimQuestion(
      id: 'cs-5',
      subject: 'Computer Science',
      subtopic: 'Computer Networks',
      question: 'At which OSI layer does the TCP protocol operate?',
      options: ['Network Layer', 'Transport Layer', 'Session Layer', 'Data Link Layer'],
      correctIndex: 1,
      explanation: 'Transmission Control Protocol (TCP) is a core Transport Layer protocol providing reliable end-to-end communication.',
    ),
    ExamSimQuestion(
      id: 'cs-6',
      subject: 'Computer Science',
      subtopic: 'Data Structures',
      question: 'Which data structure is primarily used to implement Breadth-First Search (BFS) in a graph?',
      options: ['Stack', 'Queue', 'Priority Queue', 'Binary Tree'],
      correctIndex: 1,
      explanation: 'BFS explores vertices level by level using a FIFO Queue data structure.',
    ),
    ExamSimQuestion(
      id: 'cs-7',
      subject: 'Computer Science',
      subtopic: 'Operating Systems',
      question: 'What is the phenomenon called when excessive page faults lead to continuous paging with no CPU progress?',
      options: ['Fragmentation', 'Thrashing', 'Starvation', 'Pipelining'],
      correctIndex: 1,
      explanation: 'Thrashing occurs when memory allocation is too low and the OS spends more time swapping pages than executing code.',
    ),
    ExamSimQuestion(
      id: 'cs-8',
      subject: 'Computer Science',
      subtopic: 'Algorithms',
      question: 'Dijkstra’s algorithm is used to solve which problem?',
      options: ['Minimum Spanning Tree', 'Single-Source Shortest Path (non-negative weights)', 'Maximum Flow', 'Graph Coloring'],
      correctIndex: 1,
      explanation: 'Dijkstra computes shortest paths from a single source vertex to all other vertices in a non-negative weighted graph.',
    ),
    ExamSimQuestion(
      id: 'cs-9',
      subject: 'Computer Science',
      subtopic: 'Database Management',
      question: 'What does the ACID property "Isolation" ensure in database transactions?',
      options: ['Data survives power failure', 'Concurrent transactions execute as if serially scheduled', 'All or nothing execution', 'Constraints are maintained'],
      correctIndex: 1,
      explanation: 'Isolation guarantees that intermediate states of concurrent transactions are invisible to other transactions.',
    ),
    ExamSimQuestion(
      id: 'cs-10',
      subject: 'Computer Science',
      subtopic: 'OOP Concepts',
      question: 'In object-oriented programming, defining multiple methods with the same name but different parameter signatures is called:',
      options: ['Method Overriding', 'Method Overloading', 'Encapsulation', 'Dynamic Dispatch'],
      correctIndex: 1,
      explanation: 'Method Overloading allows multiple methods in the same class to share a name with varying parameter lists (compile-time polymorphism).',
    ),
  ];

  final List<ExamSimQuestion> _physicsQuestions = [
    ExamSimQuestion(
      id: 'phy-1',
      subject: 'Physics & Engineering',
      subtopic: 'Mechanics',
      question: 'A projectile is launched at an angle of 45° to the horizontal. The ratio of its maximum height to its horizontal range is:',
      options: ['1:1', '1:2', '1:4', '1:8'],
      correctIndex: 2,
      explanation: 'Range R = (u² sin 2θ)/g. Height H = (u² sin² θ)/(2g). At θ = 45°, H/R = (sin² 45°)/(2 sin 90°) = (1/2) / 2 = 1/4.',
    ),
    ExamSimQuestion(
      id: 'phy-2',
      subject: 'Physics & Engineering',
      subtopic: 'Thermodynamics',
      question: 'In an adiabatic expansion of an ideal gas, which of the following remains zero?',
      options: ['Change in Internal Energy (ΔU)', 'Work Done (W)', 'Heat Exchange (Q)', 'Change in Temperature (ΔT)'],
      correctIndex: 2,
      explanation: 'An adiabatic process is thermally insulated from its surroundings, meaning no heat is absorbed or released: Q = 0.',
    ),
    ExamSimQuestion(
      id: 'phy-3',
      subject: 'Physics & Engineering',
      subtopic: 'Electromagnetism',
      question: 'Which law relates the induced electromotive force (EMF) directly to the time rate of change of magnetic flux?',
      options: ['Ampere’s Law', 'Faraday’s Law of Induction', 'Coulomb’s Law', 'Biot-Savart Law'],
      correctIndex: 1,
      explanation: 'Faraday’s Law states EMF = -dΦ/dt, where Φ is the magnetic flux through the circuit.',
    ),
    ExamSimQuestion(
      id: 'phy-4',
      subject: 'Physics & Engineering',
      subtopic: 'Modern Physics',
      question: 'In Einstein’s photoelectric equation, the slope of the stopping potential versus incident frequency graph equals:',
      options: ['h (Planck\'s constant)', 'h/e', 'e/h', 'Work Function φ'],
      correctIndex: 1,
      explanation: 'eV₀ = hν - φ => V₀ = (h/e)ν - (φ/e). Therefore, the slope of V₀ vs ν is h/e.',
    ),
    ExamSimQuestion(
      id: 'phy-5',
      subject: 'Physics & Engineering',
      subtopic: 'Mechanics',
      question: 'A particle moves in a circle of radius r with constant speed v. The magnitude of its centripetal acceleration is:',
      options: ['v / r', 'v² / r', 'v² / r²', 'v r'],
      correctIndex: 1,
      explanation: 'Centripetal acceleration for uniform circular motion directed radially inward is a = v²/r = ω²r.',
    ),
    ExamSimQuestion(
      id: 'phy-6',
      subject: 'Physics & Engineering',
      subtopic: 'Thermodynamics',
      question: 'The maximum theoretical efficiency of a heat engine operating between temperatures Th and Tc (in Kelvin) is given by:',
      options: ['1 - Tc/Th', '1 - Th/Tc', 'Tc/Th', '(Th - Tc)/(Th + Tc)'],
      correctIndex: 0,
      explanation: 'Carnot efficiency η = 1 - (Tc / Th) represents the fundamental upper limit of any heat engine operating between two reservoirs.',
    ),
    ExamSimQuestion(
      id: 'phy-7',
      subject: 'Physics & Engineering',
      subtopic: 'Optics',
      question: 'When light passes from a denser optical medium into a rarer medium, total internal reflection occurs if the angle of incidence is:',
      options: ['Equal to 0°', 'Less than critical angle', 'Greater than critical angle', 'Exactly 45°'],
      correctIndex: 2,
      explanation: 'Total internal reflection occurs only when traveling from denser to rarer medium and the incidence angle exceeds the critical angle.',
    ),
    ExamSimQuestion(
      id: 'phy-8',
      subject: 'Physics & Engineering',
      subtopic: 'Electromagnetism',
      question: 'The electric field inside a uniformly charged conducting sphere of radius R is:',
      options: ['kQ / r²', 'Zero', 'kQ / R', 'Proportional to r'],
      correctIndex: 1,
      explanation: 'By Gauss\'s Law, all net charge resides on the outer surface of a conductor, yielding zero electric field inside.',
    ),
    ExamSimQuestion(
      id: 'phy-9',
      subject: 'Physics & Engineering',
      subtopic: 'Mechanics',
      question: 'If the kinetic energy of a body is doubled, by what factor does its linear momentum increase?',
      options: ['√2', '2', '4', '1 / √2'],
      correctIndex: 0,
      explanation: 'Linear momentum p = √(2mE). If kinetic energy E is doubled, new momentum p\' = √(2m * 2E) = √2 * p.',
    ),
    ExamSimQuestion(
      id: 'phy-10',
      subject: 'Physics & Engineering',
      subtopic: 'Waves & Oscillations',
      question: 'For a simple pendulum executing small oscillations, if its length is made 4 times, its time period will be:',
      options: ['Halved', 'Doubled', 'Quadrupled', 'Unchanged'],
      correctIndex: 1,
      explanation: 'Time period T = 2π√(L/g). If length L is quadrupled, T is multiplied by √4 = 2.',
    ),
  ];

  final List<ExamSimQuestion> _mathQuestions = [
    ExamSimQuestion(
      id: 'math-1',
      subject: 'Mathematics',
      subtopic: 'Calculus',
      question: 'What is the limit of (sin x) / x as x approaches 0?',
      options: ['0', '1', 'Infinity', 'Undefined'],
      correctIndex: 1,
      explanation: 'Fundamental trigonometric limit lim (x->0) (sin x)/x = 1 (can also be proven via L’Hopital’s rule: cos(0)/1 = 1).',
    ),
    ExamSimQuestion(
      id: 'math-2',
      subject: 'Mathematics',
      subtopic: 'Linear Algebra',
      question: 'If the determinant of a square matrix A is 0, the matrix is:',
      options: ['Orthogonal', 'Invertible', 'Singular', 'Symmetric'],
      correctIndex: 2,
      explanation: 'A matrix with zero determinant cannot be inverted and is termed singular (non-invertible).',
    ),
    ExamSimQuestion(
      id: 'math-3',
      subject: 'Mathematics',
      subtopic: 'Probability',
      question: 'Two fair six-sided dice are rolled simultaneously. What is the probability that the sum of the numbers is 7?',
      options: ['1/6', '1/12', '5/36', '7/36'],
      correctIndex: 0,
      explanation: 'Combinations yielding sum 7 are (1,6), (2,5), (3,4), (4,3), (5,2), (6,1) = 6 outcomes out of 36 total => 6/36 = 1/6.',
    ),
    ExamSimQuestion(
      id: 'math-4',
      subject: 'Mathematics',
      subtopic: 'Calculus',
      question: 'The derivative of ln(x² + 1) with respect to x is:',
      options: ['1 / (x² + 1)', '2x / (x² + 1)', 'x / (x² + 1)', '2 / x'],
      correctIndex: 1,
      explanation: 'By the chain rule: d/dx [ln(u)] = (1/u) * u\' = (1/(x² + 1)) * 2x = 2x / (x² + 1).',
    ),
    ExamSimQuestion(
      id: 'math-5',
      subject: 'Mathematics',
      subtopic: 'Linear Algebra',
      question: 'For an n x n matrix, the sum of its eigenvalues is always equal to its:',
      options: ['Determinant', 'Trace', 'Rank', 'Spectral Radius'],
      correctIndex: 1,
      explanation: 'The sum of all eigenvalues of a matrix equals the trace (sum of diagonal entries), while their product equals the determinant.',
    ),
  ];

  final List<ExamSimQuestion> _aptitudeQuestions = [
    ExamSimQuestion(
      id: 'apt-1',
      subject: 'General Aptitude',
      subtopic: 'Number Logic',
      question: 'Complete the sequence: 2, 6, 12, 20, 30, ?',
      options: ['40', '42', '44', '48'],
      correctIndex: 1,
      explanation: 'Pattern: 1*2=2, 2*3=6, 3*4=12, 4*5=20, 5*6=30. Next term is 6*7 = 42 (or difference increments by +4, +6, +8, +10, +12).',
    ),
    ExamSimQuestion(
      id: 'apt-2',
      subject: 'General Aptitude',
      subtopic: 'Work & Time',
      question: 'Pipe A fills a tank in 4 hours, and Pipe B empties it in 6 hours. If both open together, how long to fill the empty tank?',
      options: ['10 hours', '12 hours', '14 hours', '8 hours'],
      correctIndex: 1,
      explanation: 'Net rate = 1/4 - 1/6 = (3 - 2)/12 = 1/12 tank per hour. Total time required is 12 hours.',
    ),
    ExamSimQuestion(
      id: 'apt-3',
      subject: 'General Aptitude',
      subtopic: 'Percentages & Profit',
      question: 'An item is sold at 20% profit. If cost price was \$500, what is the selling price?',
      options: ['\$550', '\$600', '\$620', '\$650'],
      correctIndex: 1,
      explanation: 'Selling price = Cost Price * (1 + 0.20) = 500 * 1.20 = \$600.',
    ),
  ];
}
