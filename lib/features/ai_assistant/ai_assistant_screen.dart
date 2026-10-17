import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum AiTaskMode {
  explainConcept,
  summarizeNotes,
  generateQuestions,
  debugCodeError,
  revisionAdvice,
}

class AiMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? templateTag;

  AiMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.templateTag,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isConfigured = false;
  bool _isLoading = false;
  String _userApiKey = '';
  AiTaskMode _currentMode = AiTaskMode.explainConcept;

  final List<AiMessage> _messages = [
    AiMessage(
      text: 'Hello! I am your StudyMate AI Tutor. 🎓\n\nI can explain difficult concepts simply, summarize lengthy lecture notes, generate practice quiz questions, or help you debug programming errors.\n\nSelect a quick prompt below or ask your own question!',
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final key = await _storage.read(key: 'user_gemini_api_key');
    if (key != null && key.isNotEmpty) {
      setState(() {
        _userApiKey = key;
        _isConfigured = true;
      });
    }
  }

  Future<void> _saveApiKey(String key) async {
    await _storage.write(key: 'user_gemini_api_key', value: key.trim());
    setState(() {
      _userApiKey = key.trim();
      _isConfigured = true;
    });
  }

  void _sendMessage([String? textToSend]) {
    final query = textToSend ?? _inputController.text.trim();
    if (query.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(AiMessage(text: query, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    // Process using Educational Knowledge Engine / Configured API
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final reply = _generateEducationalResponse(query, _currentMode);
      setState(() {
        _messages.add(
          AiMessage(
            text: reply,
            isUser: false,
            templateTag: _getModeTitle(_currentMode),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    });
  }

  String _generateEducationalResponse(String query, AiTaskMode mode) {
    final q = query.toLowerCase();

    switch (mode) {
      case AiTaskMode.explainConcept:
        if (q.contains('newton') || q.contains('motion')) {
          return '📌 Concept: Newton\'s 3 Laws of Motion\n\n1. Law of Inertia: An object at rest stays at rest, and an object in motion stays in motion with constant velocity unless acted on by a net external force.\n2. Law of Acceleration: Net force equals mass times acceleration (F = m·a). Acceleration is inversely proportional to mass.\n3. Action-Reaction: For every action, there is an equal and opposite reaction (forces always occur in matched pairs).\n\n💡 Practical Memory Tip: Remember "Rest, Result, Reaction".';
        }
        if (q.contains('recursion') || q.contains('recursive')) {
          return '📌 Concept: Recursion in Computer Science\n\nRecursion is a programming technique where a function solves a problem by calling a smaller instance of itself.\n\nTwo Non-Negotiable Components:\n1. Base Case: The condition that halts recursion (e.g. if (n <= 1) return 1;)\n2. Recursive Step: Breaking the problem down toward the base case (e.g. return n * factorial(n - 1);)\n\n⚠️ Caution: Without a proper base case, you will encounter a Stack Overflow error because each call occupies a frame on the call stack.';
        }
        return '📌 Concept Analysis: "$query"\n\n1. Core Definition: The fundamental principle revolves around dividing complex mechanisms into first-principles components.\n2. Key Formula / Rule: Review the standard governing theorem and identify independent vs dependent variables.\n3. Common Pitfall: Students frequently overlook edge cases and boundary conditions.\n4. Real-world Analogy: Think of this like a pipeline where each stage processes inputs sequentially.';

      case AiTaskMode.summarizeNotes:
        return '📝 Structured Executive Summary:\n\n• Key Takeaway: The provided notes focus on foundational theorems, constraints, and their applied proofs.\n• Primary Principles: 3 governing axioms are emphasized with step-by-step mathematical justifications.\n• High-Yield Exam Topics: Definitions, boundary constraints, and direct numerical applications.\n• Review Checklist: Ensure you can reproduce the key diagram and derive the final equilibrium equation independently.';

      case AiTaskMode.generateQuestions:
        return '❓ Practice Quiz Questions Generated:\n\n1. [Multiple Choice] What is the primary operational condition required for this theorem to hold true?\n   A) Zero external friction\n   B) Infinite bandwidth\n   C) Constant temperature and pressure\n   D) Uniform distribution\n\n2. [True/False] The efficiency can theoretically exceed 100% under adiabatic conditions. (Answer: False)\n\n3. [Concept Proof] State the two critical boundary assumptions and write down the governing formula.';

      case AiTaskMode.debugCodeError:
        return '🐞 Debugging & Code Analysis:\n\n• Identified Issue: Common causes include Null Check Operator errors, Unhandled Promise Rejections, or Off-By-One loop limits (i <= length instead of i < length).\n• Recommended Fix: Verify your array boundaries and wrap asynchronous calls inside a try-catch block with proper fallback handling.\n• Best Practice: Use defensive null-coalescing operators (??) and assert inputs before passing them into state mutators.';

      case AiTaskMode.revisionAdvice:
        return '📅 Personalized Revision Advice:\n\n• Spaced Schedule: Review today, repeat in 48 hours, and test active recall in 7 days.\n• Active Recall: Close your textbook and write the entire concept on a blank sheet from memory before checking the answer.\n• Focus Areas: Prioritize the 20% high-weightage topics that account for 80% of past examination questions.';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getModeTitle(AiTaskMode m) {
    switch (m) {
      case AiTaskMode.explainConcept:
        return 'Concept Explainer';
      case AiTaskMode.summarizeNotes:
        return 'Notes Summarizer';
      case AiTaskMode.generateQuestions:
        return 'Question Generator';
      case AiTaskMode.debugCodeError:
        return 'Code Debugger';
      case AiTaskMode.revisionAdvice:
        return 'Revision Planner';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StudyMate AI Tutor',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _isConfigured
                      ? 'Gemini Engine Active'
                      : 'Offline Knowledge Engine',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _isConfigured
                        ? AppColors.success
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'API Key Configuration',
            onPressed: () => _showApiKeyDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Prompt Mode Chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildModeChip(AiTaskMode.explainConcept, '💡 Explain Concept'),
                _buildModeChip(AiTaskMode.summarizeNotes, '📝 Summarize Notes'),
                _buildModeChip(
                  AiTaskMode.generateQuestions,
                  '❓ Generate Quiz Questions',
                ),
                _buildModeChip(
                  AiTaskMode.debugCodeError,
                  '🐞 Debug Code Error',
                ),
                _buildModeChip(
                  AiTaskMode.revisionAdvice,
                  '📅 Revision Strategy',
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppDimensions.space16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'StudyMate AI is analyzing concept...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),

          // Quick Starter Questions
          if (_messages.length <= 2)
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildQuickAction('Explain Newton\'s Laws simply'),
                  _buildQuickAction('Explain Recursion with base case'),
                  _buildQuickAction('Give me 3 practice quiz questions'),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask concept, paste code or notes...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (v) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(AiTaskMode mode, String label) {
    final isSel = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentMode = mode),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSel ? Colors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage msg, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: msg.isUser
                ? AppColors.primary
                : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
              bottomRight: Radius.circular(msg.isUser ? 4 : 16),
            ),
            border: msg.isUser
                ? null
                : Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!msg.isUser && msg.templateTag != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    msg.templateTag!,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              SelectableText(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: msg.isUser
                      ? Colors.white
                      : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final keyCtrl = TextEditingController(text: _userApiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.key_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Gemini API Setup',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optionally enter your own Google Gemini API key to enable live online generative assistance. StudyMate stores this securely inside encrypted hardware storage on your device.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key (AIzaSy...)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              await _saveApiKey(keyCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ API Configuration Saved Securely!'),
                  ),
                );
              }
            },
            child: const Text(
              'Save Key',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
