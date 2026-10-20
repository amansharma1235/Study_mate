import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../data/local/preference_service.dart';
import '../../data/local/voice_study_service.dart';
import '../../data/models/flashcard_model.dart';
import '../../data/remote/gemini_service.dart';
import '../flashcards/flashcards_controller.dart';
import 'services/academic_knowledge_engine.dart';

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
  final bool isLiveAi;
  final bool isError;
  final Uint8List? imageBytes;

  AiMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.templateTag,
    this.isLiveAi = false,
    this.isError = false,
    this.imageBytes,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  final String? initialPrompt;

  const AiAssistantScreen({super.key, this.initialPrompt});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();

  bool _isConfigured = false;
  bool _isLoading = false;
  String _userApiKey = '';
  AiTaskMode _currentMode = AiTaskMode.explainConcept;
  Uint8List? _selectedImageBytes;
  bool _isListening = false;
  String? _currentlySpeakingMessageText;
  bool _autoSpeakEnabled = false;

  Future<void> _toggleVoiceInput() async {
    final voiceService = ref.read(voiceStudyServiceProvider);
    if (_isListening) {
      await voiceService.stopListening();
      if (!mounted) return;
      setState(() => _isListening = false);
    } else {
      final started = await voiceService.startListening(
        onResult: (words) {
          if (!mounted) return;
          setState(() {
            _inputController.text = words;
          });
        },
        onListeningStarted: () {
          if (!mounted) return;
          setState(() => _isListening = true);
        },
        onListeningStopped: () {
          if (!mounted) return;
          setState(() => _isListening = false);
        },
      );
      if (!started && mounted) {
        AppDialogs.showSnackBar(
          context,
          message:
              'Microphone speech recognition is not available or permission denied.',
          isError: true,
        );
      }
    }
  }

  Future<void> _toggleSpeakMessage(String text) async {
    final voiceService = ref.read(voiceStudyServiceProvider);
    if (_currentlySpeakingMessageText == text) {
      await voiceService.stopSpeaking();
      if (!mounted) return;
      setState(() => _currentlySpeakingMessageText = null);
    } else {
      setState(() => _currentlySpeakingMessageText = text);
      await voiceService.speak(
        text,
        onStart: () {
          if (!mounted) return;
          setState(() => _currentlySpeakingMessageText = text);
        },
        onComplete: () {
          if (!mounted) return;
          setState(() => _currentlySpeakingMessageText = null);
        },
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnackBar(
        context,
        message: 'Could not load image: $e',
        isError: true,
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Take Photo with Camera',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Capture study problem, textbook page or formula',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.secondary,
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Upload assignment screenshot or diagram'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  final List<AiMessage> _messages = [
    AiMessage(
      text:
          'Hello! I am your StudyMate AI Tutor. 🎓\n\nI can explain difficult concepts, summarize lengthy lecture notes, generate practice quiz questions, or help you debug code errors.\n\nSelect a quick prompt below or type your question!',
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkApiKey().then((_) {
      if (widget.initialPrompt == 'SCAN_PHOTO') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showImageSourceDialog();
        });
      } else if (widget.initialPrompt != null &&
          widget.initialPrompt!.trim().isNotEmpty) {
        _sendMessage(widget.initialPrompt!.trim());
      }
    });
  }

  @override
  void dispose() {
    ref.read(voiceStudyServiceProvider).dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    String foundKey = '';

    // 1. Check SharedPreferences (fast & reliable across desktop, mobile, web)
    try {
      final prefKey = ref.read(preferenceServiceProvider).getGeminiApiKey();
      if (prefKey.trim().isNotEmpty) {
        foundKey = prefKey.trim();
      }
    } catch (_) {}

    // 2. Check FlutterSecureStorage if available
    if (foundKey.isEmpty) {
      try {
        final secureKey =
            await _storage.read(key: AppConstants.geminiApiKeyStorageKey);
        if (secureKey != null && secureKey.trim().isNotEmpty) {
          foundKey = secureKey.trim();
        }
      } catch (_) {}
    }

    // 3. Check AppConstants / compile-time default
    if (foundKey.isEmpty &&
        AppConstants.defaultGeminiApiKey.trim().isNotEmpty) {
      foundKey = AppConstants.defaultGeminiApiKey.trim();
    }

    if (foundKey.isNotEmpty && mounted) {
      setState(() {
        _userApiKey = foundKey;
        _isConfigured = true;
      });
    }
  }

  Future<void> _saveApiKey(String key) async {
    final trimmed = key.trim();

    // Persist to SharedPreferences
    try {
      await ref.read(preferenceServiceProvider).setGeminiApiKey(trimmed);
    } catch (e) {
      debugPrint('Preferences save note: $e');
    }

    // Also persist to FlutterSecureStorage
    try {
      await _storage.write(
        key: AppConstants.geminiApiKeyStorageKey,
        value: trimmed,
      );
    } catch (e) {
      debugPrint('SecureStorage write note: $e');
    }

    if (!mounted) return;
    setState(() {
      _userApiKey = trimmed;
      _isConfigured = trimmed.isNotEmpty;
    });
  }

  String _getSystemInstruction(AiTaskMode mode) {
    switch (mode) {
      case AiTaskMode.explainConcept:
        return 'You are StudyMate, an expert university tutor. Explain concepts clearly using first principles, practical examples, and memorable analogies. Use structured markdown with headers, bold points, and bulleted lists. Always highlight common pitfalls.';
      case AiTaskMode.summarizeNotes:
        return 'You are StudyMate, an academic note summarizer. Summarize provided notes into key takeaways, core formulas/principles, and high-yield exam points. Format with concise bullet points and bold headers.';
      case AiTaskMode.generateQuestions:
        return 'You are StudyMate, an educational exam generator. Generate 3 high-quality practice quiz questions (1 MCQ with 4 options and answer explanation, 1 True/False with justification, and 1 conceptual short-answer question).';
      case AiTaskMode.debugCodeError:
        return 'You are StudyMate, a software engineering mentor. Analyze provided code or error messages. Identify root causes clearly, provide the exact corrected code snippet, and explain the best practice to prevent recurrence.';
      case AiTaskMode.revisionAdvice:
        return 'You are StudyMate, a cognitive learning scientist. Provide an actionable spaced-repetition revision strategy with specific timeframes (Day 1, Day 3, Day 7), active recall prompts, and memory techniques.';
    }
  }

  Future<void> _sendMessage([String? textToSend]) async {
    final query = textToSend ?? _inputController.text.trim();
    if ((query.isEmpty && _selectedImageBytes == null) || _isLoading) return;

    final imageToSend = _selectedImageBytes;
    _inputController.clear();
    setState(() {
      _selectedImageBytes = null;
      _messages.add(
        AiMessage(
          text: query.isNotEmpty
              ? query
              : '📷 [Attached study image for AI analysis]',
          isUser: true,
          imageBytes: imageToSend,
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    if (_isConfigured && _userApiKey.isNotEmpty) {
      // Live Google Gemini API Request
      try {
        final geminiService = ref.read(geminiServiceProvider);
        final response = await geminiService.generateContent(
          prompt: query,
          apiKey: _userApiKey,
          systemInstruction: _getSystemInstruction(_currentMode),
          imageBytes: imageToSend,
        );

        if (!mounted) return;
        final modelTag = response.model != null
            ? 'Gemini ${response.model}'
            : 'Gemini Online';

        setState(() {
          _messages.add(
            AiMessage(
              text: response.text,
              isUser: false,
              isLiveAi: true,
              templateTag: imageToSend != null
                  ? '$modelTag Vision • Visual Solver'
                  : '$modelTag • ${_getModeTitle(_currentMode)}',
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
        if (_autoSpeakEnabled) {
          _toggleSpeakMessage(response.text);
        }
      } catch (_) {
        if (!mounted) return;
        final offlineAnswer = _generateEducationalResponse(query, _currentMode);
        final fullText = '''
$offlineAnswer

---
💡 *Using StudyMate Academic Knowledge Engine. To enable live online AI model responses, tap 🔑 in the top bar to update your Google AI Studio key.*
''';
        setState(() {
          _messages.add(
            AiMessage(
              text: fullText,
              isUser: false,
              isError: false,
              templateTag: 'StudyMate Academic Engine ⚡',
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
        if (_autoSpeakEnabled) {
          _toggleSpeakMessage(offlineAnswer);
        }
      }
    } else {
      // Offline Academic Knowledge Engine with explicit attribution
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      String reply = _generateEducationalResponse(query, _currentMode);
      if (imageToSend != null) {
        reply =
            '📷 **Photo Captured for Analysis:**\n\nStudyMate has captured your study photo! To analyze handwritten questions, solve mathematical formulas from photos, and read textbook diagrams with Computer Vision, please activate your free Google Gemini API key by tapping the key 🔑 in the top right.\n\n---\n$reply';
      }
      setState(() {
        _messages.add(
          AiMessage(
            text: reply,
            isUser: false,
            isLiveAi: false,
            templateTag:
                'Offline Academic Engine • ${_getModeTitle(_currentMode)}',
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
      if (_autoSpeakEnabled) {
        _toggleSpeakMessage(reply);
      }
    }
  }

  String _generateEducationalResponse(String query, AiTaskMode mode) {
    return AcademicKnowledgeEngine.generateResponse(query, mode);
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
        return 'Quiz Generator';
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'StudyMate AI Tutor',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _isConfigured
                              ? AppColors.success
                              : const Color(0xFF3987F5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isConfigured
                            ? 'Gemini 1.5 Flash Online'
                            : 'Offline Academic Engine',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _isConfigured
                              ? AppColors.success
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.secondary),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _autoSpeakEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _autoSpeakEnabled ? AppColors.secondary : null,
            ),
            tooltip: _autoSpeakEnabled ? 'Auto-Voice: ON' : 'Auto-Voice: OFF',
            onPressed: () {
              setState(() {
                _autoSpeakEnabled = !_autoSpeakEnabled;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _autoSpeakEnabled
                        ? '🔊 Auto-Voice Tutor ON: AI answers will be read aloud'
                        : '🔇 Auto-Voice Tutor OFF',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.key_rounded,
              color: _isConfigured ? AppColors.success : AppColors.primary,
            ),
            tooltip: 'API Key Configuration',
            onPressed: () => _showApiKeyDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline Banner prompting user to enter key for live generative responses
          if (!_isConfigured)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Running offline engine. Add your free Google Gemini API key for live generative answers.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showApiKeyDialog(context),
                    child: const Text(
                      'Setup Key',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                GestureDetector(
                  onTap: () => context.push(AppRoutes.docExtractor),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.document_scanner_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Extract PDF ⚡',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                    _isConfigured
                        ? 'Gemini 1.5 Flash is thinking...'
                        : 'StudyMate Academic Engine analyzing...',
                    style: const TextStyle(
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

          // Input Bar with Multimodal Vision Camera & Gallery
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Attachment Preview Strip
                  if (_selectedImageBytes != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222533) : const Color(0xFFEFF3FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _selectedImageBytes!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '📷 Study Photo Attached',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Gemini 1.5 Flash Vision will read & solve this image',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              setState(() {
                                _selectedImageBytes = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  // Voice Listening Banner
                  if (_isListening)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Listening... Speak your question clearly',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleVoiceInput,
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      // Camera / Gallery Photo Picker Button
                      IconButton(
                        icon: const Icon(Icons.add_a_photo_outlined),
                        color: _selectedImageBytes != null
                            ? AppColors.success
                            : AppColors.primary,
                        tooltip: 'Attach question or textbook photo',
                        onPressed: _showImageSourceDialog,
                      ),

                      // Speech-to-Text Microphone Dictation Button
                      IconButton(
                        icon: Icon(
                          _isListening
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                        ),
                        color:
                            _isListening ? AppColors.error : AppColors.primary,
                        tooltip: _isListening
                            ? 'Stop listening'
                            : 'Dictate question by voice',
                        onPressed: _toggleVoiceInput,
                      ),
                      const SizedBox(width: 2),

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
                              hintText: _selectedImageBytes != null
                                  ? 'Ask question about this photo...'
                                  : 'Ask concept, paste code or notes...',
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
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage msg, bool isDark) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 240,
                    ),
                    child: Image.memory(
                      msg.imageBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 32),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isError
              ? (isDark ? const Color(0xFF3A1C1C) : const Color(0xFFFEE2E2))
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: msg.isError
                ? AppColors.error
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.templateTag != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: msg.isError
                      ? AppColors.error.withValues(alpha: 0.15)
                      : (msg.isLiveAi
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  msg.templateTag!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: msg.isError
                        ? AppColors.error
                        : (msg.isLiveAi
                            ? AppColors.success
                            : AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SelectableText(
              msg.text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            if (!msg.isError) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildBubbleActionButton(
                    icon: _currentlySpeakingMessageText == msg.text
                        ? Icons.stop_circle_rounded
                        : Icons.volume_up_rounded,
                    label: _currentlySpeakingMessageText == msg.text
                        ? 'Stop Voice'
                        : 'Listen 🔊',
                    color: _currentlySpeakingMessageText == msg.text
                        ? AppColors.secondary
                        : null,
                    onTap: () => _toggleSpeakMessage(msg.text),
                  ),
                  _buildBubbleActionButton(
                    icon: Icons.note_add_outlined,
                    label: 'Save Note',
                    onTap: () {
                      context.push(
                        AppRoutes.createNote,
                        extra: {
                          'initialTitle':
                              'AI Study Note: ${_getModeTitle(_currentMode)}',
                          'initialContent': msg.text,
                        },
                      );
                    },
                  ),
                  _buildBubbleActionButton(
                    icon: Icons.style_outlined,
                    label: 'Save Flashcard',
                    onTap: () => _showSaveFlashcardDialog(context, msg.text),
                  ),
                  _buildBubbleActionButton(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      AppDialogs.showSnackBar(
                        context,
                        message: 'Copied to clipboard',
                        isSuccess: true,
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBubbleActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final btnColor = color ?? AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: btnColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: btnColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: btnColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: btnColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveFlashcardDialog(
      BuildContext context, String responseText) async {
    final decksAsync = ref.read(flashcardDecksProvider);
    List<FlashcardDeckModel> decks = decksAsync.asData?.value ?? [];

    if (decks.isEmpty) {
      await ref.read(flashcardDecksProvider.notifier).createDeck(
            title: 'AI Study Deck',
            subject: 'AI Tutor',
            description: 'Generated flashcards from StudyMate AI',
          );
      final refreshed = ref.read(flashcardDecksProvider);
      decks = refreshed.asData?.value ?? [];
    }

    String selectedDeckId = decks.isNotEmpty ? decks.first.id : '';

    String frontDefault = _inputController.text.trim().isNotEmpty
        ? _inputController.text.trim()
        : 'Key Concept (${_getModeTitle(_currentMode)})';

    final lines =
        responseText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty && lines.first.startsWith('📌')) {
      frontDefault = lines.first.replaceAll('📌', '').trim();
    }

    final frontCtrl = TextEditingController(text: frontDefault);
    final backCtrl = TextEditingController(text: responseText);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.style_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Save as Flashcard',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (decks.isNotEmpty) ...[
                  const Text(
                    'Target Deck',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue:
                        selectedDeckId.isNotEmpty ? selectedDeckId : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: decks
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              '${d.title} (${d.subject})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedDeckId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Front (Question / Prompt)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: frontCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Newton\'s 2nd Law formula',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Back (Answer / Explanation)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: backCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'e.g. F = m * a',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (frontCtrl.text.trim().isEmpty ||
                    backCtrl.text.trim().isEmpty ||
                    selectedDeckId.isEmpty) {
                  return;
                }
                await ref.read(flashcardDecksProvider.notifier).addCardToDeck(
                      deckId: selectedDeckId,
                      front: frontCtrl.text.trim(),
                      back: backCtrl.text.trim(),
                    );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  AppDialogs.showSnackBar(
                    context,
                    message: '✅ Saved to your flashcards deck!',
                    isSuccess: true,
                  );
                }
              },
              child: const Text(
                'Save Card',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final keyCtrl = TextEditingController(text: _userApiKey);
    bool isObscured = true;
    bool isTesting = false;
    String? testResult;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gemini API Setup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connect Google Gemini AI to enable live generative tutoring, answers to any question, code debugging, and revision advice.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Get a free Gemini API key from Google AI Studio: https://aistudio.google.com/',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF333333)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: keyCtrl,
                  obscureText: isObscured,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'AIzaSy...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () {
                        setDialogState(() => isObscured = !isObscured);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (testResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: (testSuccess == true ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          testSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          size: 16,
                          color: testSuccess == true ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            testResult!,
                            style: TextStyle(
                              fontSize: 12,
                              color: testSuccess == true ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: isTesting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.bolt_rounded, size: 16),
                      label: Text(isTesting ? 'Testing...' : 'Test Key'),
                      onPressed: isTesting || keyCtrl.text.trim().isEmpty
                          ? null
                          : () async {
                              setDialogState(() {
                                isTesting = true;
                                testResult = null;
                              });
                              final isValid = await ref
                                  .read(geminiServiceProvider)
                                  .testApiKey(keyCtrl.text.trim());
                              setDialogState(() {
                                isTesting = false;
                                testSuccess = isValid;
                                testResult = isValid
                                    ? '✅ API key is valid and connected!'
                                    : '❌ Invalid API key or network error.';
                              });
                            },
                    ),
                    if (keyCtrl.text.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          keyCtrl.clear();
                          setDialogState(() {
                            testResult = null;
                            testSuccess = null;
                          });
                        },
                        child: const Text('Clear', style: TextStyle(color: AppColors.error, fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                await _saveApiKey(keyCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  AppDialogs.showSnackBar(
                    context,
                    message: keyCtrl.text.trim().isEmpty
                        ? 'Switched to Offline Academic Engine'
                        : '✅ Gemini API Key Saved and Activated!',
                    isSuccess: true,
                  );
                }
              },
              child: const Text(
                'Save & Activate',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
