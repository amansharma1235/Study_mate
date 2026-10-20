import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/coding_model.dart';

class CodingScreen extends StatefulWidget {
  const CodingScreen({super.key});

  @override
  State<CodingScreen> createState() => _CodingScreenState();
}

class _CodingScreenState extends State<CodingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedLang = 'Dart / Flutter';

  final List<String> _languages = [
    'Dart / Flutter',
    'Python',
    'Java',
    'C++',
    'JavaScript',
  ];

  final List<CodingRoadmapTopic> _roadmaps = [
    const CodingRoadmapTopic(
      id: 'rm-1',
      language: 'Dart / Flutter',
      title: 'Phase 1: Dart Fundamentals & OOP',
      description:
          'Variables, null safety, asynchronous futures, streams, and mixins',
      estimatedHours: 12,
      concepts: [
        'Null Safety (? and !)',
        'Async / Await / Streams',
        'Factory Constructors',
        'Mixins & Extension Methods',
      ],
      isCompleted: true,
    ),
    const CodingRoadmapTopic(
      id: 'rm-2',
      language: 'Dart / Flutter',
      title: 'Phase 2: Flutter Widgets & State Management',
      description:
          'Widget lifecycle, Riverpod / Bloc architectures, custom painters',
      estimatedHours: 20,
      concepts: [
        'Stateless vs Stateful lifecycle',
        'StateNotifier & Provider patterns',
        'Optimizing build() methods',
        'InheritedWidget mechanics',
      ],
      isCompleted: false,
    ),
    const CodingRoadmapTopic(
      id: 'rm-3',
      language: 'Dart / Flutter',
      title: 'Phase 3: Networking & Offline Storage',
      description: 'REST APIs, JSON serialization, SQLite/Drift, and FlutterSecureStorage',
      estimatedHours: 15,
      concepts: [
        'HTTP Client & interceptors',
        'Database Migrations',
        'Secure token storage',
        'Offline cache synchronization',
      ],
      isCompleted: false,
    ),
  ];

  final List<CodingExerciseModel> _exercises = [
    const CodingExerciseModel(
      id: 'ex-1',
      language: 'Dart / Flutter',
      title: 'Two Sum Problem',
      difficulty: 'Beginner',
      description: 'Given an array of integers nums and an integer target, return indices of the two numbers such that they add up to target in O(n) time.',
      starterCode: 'List<int> twoSum(List<int> nums, int target) {\n  // Implement O(n) hash map solution here\n  return [];\n}',
      solutionCode: 'List<int> twoSum(List<int> nums, int target) {\n  final Map<int, int> seen = {};\n  for (int i = 0; i < nums.length; i++) {\n    final complement = target - nums[i];\n    if (seen.containsKey(complement)) {\n      return [seen[complement]!, i];\n    }\n    seen[nums[i]] = i;\n  }\n  return [];\n}',
      explanation: 'Using a Hash Map gives O(1) lookups. As we iterate through nums, we check if the complement (target - num) was previously stored. Time complexity: O(n), Space: O(n).',
      testCases: [
        'nums = [2,7,11,15], target = 9 -> [0, 1]',
        'nums = [3,2,4], target = 6 -> [1, 2]',
      ],
      isSolved: true,
    ),
    const CodingExerciseModel(
      id: 'ex-2',
      language: 'Dart / Flutter',
      title: 'Reverse a Linked List',
      difficulty: 'Intermediate',
      description: 'Given the head of a singly linked list, reverse the list, and return the reversed list in-place.',
      starterCode: 'Node? reverseList(Node? head) {\n  // Pointer reversal logic\n  return null;\n}',
      solutionCode: 'Node? reverseList(Node? head) {\n  Node? prev = null;\n  Node? curr = head;\n  while (curr != null) {\n    final nextTemp = curr.next;\n    curr.next = prev;\n    prev = curr;\n    curr = nextTemp;\n  }\n  return prev;\n}',
      explanation: 'Maintain three pointers: prev, curr, and nextTemp. Update curr.next to point backwards to prev. Time complexity: O(n), Space: O(1).',
      testCases: ['head = [1,2,3,4,5] -> [5,4,3,2,1]', 'head = [1,2] -> [2,1]'],
    ),
    const CodingExerciseModel(
      id: 'ex-3',
      language: 'Dart / Flutter',
      title: 'Valid Parentheses & Brackets',
      difficulty: 'Beginner',
      description: 'Determine if an input string containing \'(\', \')\', \'{\', \'}\', \'[\', \']\' is valid based on matching open and close pairs.',
      starterCode: 'bool isValid(String s) {\n  // Use a stack to match brackets\n  return true;\n}',
      solutionCode: 'bool isValid(String s) {\n  final List<String> stack = [];\n  final matching = {\')\': \'(\', \'}\': \'{\', \']\': \'[\'};\n  for (final char in s.split(\'\')) {\n    if (matching.containsValue(char)) {\n      stack.add(char);\n    } else if (matching.containsKey(char)) {\n      if (stack.isEmpty || stack.removeLast() != matching[char]) {\n        return false;\n      }\n    }\n  }\n  return stack.isEmpty;\n}',
      explanation: 'A Stack (LIFO) guarantees that the most recently opened bracket is closed first. Time: O(n), Space: O(n).',
      testCases: [
        's = "()" -> true',
        's = "()[]{}" -> true',
        's = "(]" -> false',
      ],
    ),
  ];

  final List<InterviewQuestionModel> _interviewQuestions = [
    const InterviewQuestionModel(
      id: 'iq-1',
      language: 'Dart / Flutter',
      category: 'Core',
      question: 'What is the difference between hot reload and hot restart in Flutter?',
      answer: 'Hot reload injects updated source code into the running Dart VM without destroying the current widget state (very fast, ~1s). Hot restart destroys the state and re-executes main(), rebuilding the entire widget tree from scratch.',
      codeExample: '// Hot reload preserves this count:\nint counter = 5;',
    ),
    const InterviewQuestionModel(
      id: 'iq-2',
      language: 'Dart / Flutter',
      category: 'Data Structures',
      question: 'Why does HashMap provide O(1) average lookup and what causes worst-case O(n)?',
      answer: 'HashMaps use a hash function to compute an array index for any key in O(1). If the hash function produces many collisions (multiple keys mapping to the same bucket), search degrades to O(n) linked list traversal (or O(log n) in balanced tree buckets).',
      codeExample: 'final bucketIndex = key.hashCode % capacity;',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Coding Practice Center',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.textMutedDark
              : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Roadmaps'),
            Tab(text: 'Exercises'),
            Tab(text: 'Interview Prep'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Language Selector Strip
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _languages.length,
              itemBuilder: (context, i) {
                final lang = _languages[i];
                final isSel = lang == _selectedLang;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLang = lang),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel
                            ? AppColors.primary
                            : AppColors.borderLight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      lang,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSel
                            ? Colors.white
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Tabs Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRoadmapsTab(isDark),
                _buildExercisesTab(isDark),
                _buildInterviewTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapsTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.space16),
      itemCount: _roadmaps.length,
      itemBuilder: (context, idx) {
        final rm = _roadmaps[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        rm.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (rm.isCompleted
                                    ? AppColors.success
                                    : AppColors.primary)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rm.isCompleted ? 'COMPLETED' : '~${rm.estimatedHours}h',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: rm.isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rm.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: rm.concepts.map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : const Color(0xFFF1F3F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '• $c',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExercisesTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.space16),
      itemCount: _exercises.length,
      itemBuilder: (context, idx) {
        final ex = _exercises[idx];
        final diffColor = ex.difficulty == 'Beginner'
            ? AppColors.success
            : (ex.difficulty == 'Intermediate'
                  ? Colors.orange
                  : AppColors.error);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ex.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: diffColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ex.difficulty.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: diffColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  ex.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 12),

                // Code Snippet Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    ex.starterCode,
                    style: GoogleFonts.firaCode(
                      fontSize: 12,
                      color: const Color(0xFFCDD6F4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // View Solution Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.code_rounded, size: 16),
                    label: const Text(
                      'View Solution & Analysis',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _showSolutionSheet(ex),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInterviewTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.space16),
      itemCount: _interviewQuestions.length,
      itemBuilder: (context, idx) {
        final q = _interviewQuestions[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    q.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  q.question,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  q.answer,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    q.codeExample,
                    style: GoogleFonts.firaCode(
                      fontSize: 11.5,
                      color: const Color(0xFFA6E3A1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSolutionSheet(CodingExerciseModel ex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Solution: ${ex.title}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ex.explanation,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    ex.solutionCode,
                    style: GoogleFonts.firaCode(
                      fontSize: 12.5,
                      color: const Color(0xFFCDD6F4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
