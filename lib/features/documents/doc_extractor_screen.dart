import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/local/preference_service.dart';
import '../../data/local/voice_study_service.dart';
import '../../data/remote/gemini_service.dart';
import '../flashcards/flashcards_controller.dart';
import '../gamification/gamification_controller.dart';

class DocExtractorScreen extends ConsumerStatefulWidget {
  final PlatformFile? initialFile;

  const DocExtractorScreen({
    super.key,
    this.initialFile,
  });

  @override
  ConsumerState<DocExtractorScreen> createState() => _DocExtractorScreenState();
}

class _DocExtractorScreenState extends ConsumerState<DocExtractorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textNotesController = TextEditingController();

  PlatformFile? _selectedFile;
  List<int>? _fileBytes;
  String _selectedSubject = 'Computer Science';
  bool _isProcessing = false;
  bool _isSpeakingSummary = false;

  Map<String, dynamic>? _extractedKit;

  final List<String> _subjects = [
    'Computer Science',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'General Studies',
    'Literature / Arts',
  ];

  void _showSnack(String msg, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.initialFile != null) {
      _applyPickedFile(widget.initialFile!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _textNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        _applyPickedFile(file);
      }
    } catch (e) {
      _showSnack('Error selecting file: $e', isSuccess: false);
    }
  }

  void _applyPickedFile(PlatformFile file) {
    setState(() {
      _selectedFile = file;
      _titleController.text =
          file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').replaceAll('_', ' ');

      if (file.bytes != null) {
        _fileBytes = file.bytes;
      } else if (file.path != null) {
        try {
          _fileBytes = File(file.path!).readAsBytesSync();
        } catch (_) {}
      }

      // If text file, pre-populate text field
      final ext = file.extension?.toLowerCase();
      if ((ext == 'txt' || ext == 'md') && _fileBytes != null) {
        try {
          _textNotesController.text = utf8.decode(_fileBytes!);
        } catch (_) {}
      }
    });
  }

  Future<void> _extractStudyKit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack(
        'Please provide a document title or upload a file.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final prefs = ref.read(preferenceServiceProvider);
      final geminiService = ref.read(geminiServiceProvider);
      final apiKey = prefs.getGeminiApiKey();

      String? mimeType;
      final ext = _selectedFile?.extension?.toLowerCase();
      if (ext == 'pdf') {
        mimeType = 'application/pdf';
      } else if (ext == 'png') {
        mimeType = 'image/png';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mimeType = 'image/jpeg';
      }

      final result = await geminiService.extractStudyKitFromDocument(
        documentTitle: title,
        subject: _selectedSubject,
        fileBytes: _fileBytes,
        mimeType: mimeType,
        textContent: _textNotesController.text.trim().isNotEmpty
            ? _textNotesController.text.trim()
            : null,
        apiKey: apiKey,
      );

      if (mounted) {
        setState(() {
          _extractedKit = result;
          _isProcessing = false;
        });

        // Award +30 Scholar XP for document extraction
        await ref.read(gamificationControllerProvider.notifier).awardXp(
              amount: 30,
              reason: 'AI Document Extracted',
              context: context,
            );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showSnack('Extraction notice: $e', isSuccess: false);
      }
    }
  }

  Future<void> _toggleSpeakSummary() async {
    final voiceService = ref.read(voiceStudyServiceProvider);
    if (_isSpeakingSummary) {
      await voiceService.stopSpeaking();
      setState(() {
        _isSpeakingSummary = false;
      });
      return;
    }

    final summaryList = (_extractedKit?['summary'] as List<dynamic>?) ?? [];
    if (summaryList.isEmpty) return;

    final fullText =
        'Summary of ${_titleController.text.trim()}.\n\n${summaryList.join('.\n\n')}';

    setState(() {
      _isSpeakingSummary = true;
    });

    await voiceService.speak(
      fullText,
      onComplete: () {
        if (mounted) {
          setState(() {
            _isSpeakingSummary = false;
          });
        }
      },
    );
  }

  void _saveAsStudyNote() {
    if (_extractedKit == null) return;

    final summary = (_extractedKit!['summary'] as List<dynamic>?)?.join('\n- ') ?? '';
    final questions = (_extractedKit!['questions'] as List<dynamic>?) ?? [];
    final cheatsheet = (_extractedKit!['cheatsheet'] as List<dynamic>?) ?? [];

    final buffer = StringBuffer();
    buffer.writeln('# ${_titleController.text.trim()}');
    buffer.writeln('**Subject:** $_selectedSubject\n');
    buffer.writeln('## Executive Summary\n- $summary\n');

    buffer.writeln('## Key Formulas & Definitions');
    for (final c in cheatsheet) {
      if (c is Map) {
        buffer.writeln('- **${c['term']}**: ${c['definition']}');
      }
    }
    buffer.writeln('');

    buffer.writeln('## Top 5 Expected Exam Questions');
    int i = 1;
    for (final q in questions) {
      if (q is Map) {
        buffer.writeln('### Q$i. ${q['question']} (${q['difficulty'] ?? 'Exam'})');
        buffer.writeln('**Answer:** ${q['answer']}\n');
        i++;
      }
    }

    context.push(
      AppRoutes.createNote,
      extra: {
        'initialTitle': 'AI Study Kit: ${_titleController.text.trim()}',
        'initialContent': buffer.toString(),
      },
    );
  }

  Future<void> _saveAsFlashcards() async {
    final questions = (_extractedKit?['questions'] as List<dynamic>?) ?? [];
    if (questions.isEmpty) return;

    final cards = questions.map((q) {
      final map = q as Map;
      return {
        'question': map['question']?.toString() ?? '',
        'answer': map['answer']?.toString() ?? '',
      };
    }).toList();

    final deck =
        await ref.read(flashcardDecksProvider.notifier).getOrCreateDeckForSubject(
              subject: _selectedSubject,
              title: 'AI Deck: ${_titleController.text.trim()}',
            );

    final addedCount = await ref
        .read(flashcardDecksProvider.notifier)
        .addMultipleCardsToDeck(deckId: deck.id, cards: cards);

    if (mounted) {
      _showSnack(
        'Saved $addedCount flashcards to "${deck.title}"! 🗂️',
        isSuccess: true,
      );
    }
  }

  void _copySummaryToClipboard() {
    final summaryList = (_extractedKit?['summary'] as List<dynamic>?) ?? [];
    if (summaryList.isEmpty) return;

    final text = 'Summary of ${_titleController.text}:\n\n- ${summaryList.join('\n- ')}';
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Summary copied to clipboard!', isSuccess: true);
  }

  void _exportAsPdfCheatsheet() {
    if (_extractedKit == null) return;

    final summary = (_extractedKit!['summary'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    final cheatsheetList =
        (_extractedKit!['cheatsheet'] as List<dynamic>?) ?? [];
    final formulas = <String>[];
    for (final c in cheatsheetList) {
      if (c is Map) {
        formulas.add('${c['term']}: ${c['definition']}');
      }
    }

    final questionsList =
        (_extractedKit!['questions'] as List<dynamic>?) ?? [];
    final questions = <Map<String, String>>[];
    for (final q in questionsList) {
      if (q is Map) {
        questions.add({
          'question': q['question']?.toString() ?? '',
          'answer': q['answer']?.toString() ?? '',
          'difficulty': q['difficulty']?.toString() ?? 'Medium',
        });
      }
    }

    context.push(
      AppRoutes.pdfCheatsheet,
      extra: {
        'title': _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Study Revision Kit',
        'subject': _selectedSubject,
        'summaryBullets': summary,
        'formulas': formulas,
        'questions': questions,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AI Document Extractor',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Intro Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.heroCardGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lecture Notes & PDF Extractor',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Upload lecture slides, chapters, or paste notes. AI will extract a 5-bullet summary, top 5 exam questions & formulas.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Document Upload Area
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 1: Select Lecture Notes or PDF',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDocument,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedFile != null
                            ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
                            : (isDark
                                ? AppColors.surfaceDark
                                : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedFile != null
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                          width: 1.5,
                        ),
                      ),
                      child: _selectedFile != null
                          ? Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getFileColor(_selectedFile!.extension)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getFileIcon(_selectedFile!.extension),
                                    color: _getFileColor(_selectedFile!.extension),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFile!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB • Tap to replace',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark
                                              ? AppColors.textMutedDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 22,
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to choose PDF, Notes or Image',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Supports .pdf, .txt, .md, .png, .jpg (Max 25MB)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Document Title Field
                  AppTextField(
                    controller: _titleController,
                    label: 'Document / Topic Title',
                    hint: 'e.g. Chapter 4: Thermodynamics & Carnot Cycle',
                  ),

                  const SizedBox(height: 12),

                  // Subject Selector
                  Row(
                    children: [
                      Text(
                        'Subject:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSubject,
                              isExpanded: true,
                              items: _subjects
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedSubject = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Extract Button
                  AppButton(
                    text: _isProcessing
                        ? 'Extracting Study Kit...'
                        : 'Extract Study Kit with AI ⚡ (+30 XP)',
                    isLoading: _isProcessing,
                    onPressed: _isProcessing ? null : _extractStudyKit,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Extracted Kit Results Studio
            if (_extractedKit != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    // Result Header & Live status
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded,
                                  color: AppColors.success, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Study Kit Ready',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (_extractedKit!['isLiveOnline'] == true
                                      ? AppColors.success
                                      : AppColors.secondary)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _extractedKit!['isLiveOnline'] == true
                                  ? '⚡ Gemini 1.5 Flash'
                                  : 'Offline Smart Engine',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _extractedKit!['isLiveOnline'] == true
                                    ? AppColors.success
                                    : AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textSecondaryLight,
                      labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                      tabs: const [
                        Tab(text: '5-Bullet Summary'),
                        Tab(text: 'Exam Q&A (5)'),
                        Tab(text: 'Cheatsheet'),
                      ],
                    ),

                    // Tab Content
                    SizedBox(
                      height: 380,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: 5-Bullet Summary
                          _buildSummaryTab(isDark),

                          // Tab 2: Top 5 Exam Questions
                          _buildQuestionsTab(isDark),

                          // Tab 3: Cheatsheet
                          _buildCheatsheetTab(isDark),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Bottom Quick Action Bar
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saveAsStudyNote,
                            icon: const Icon(Icons.note_add_outlined, size: 16),
                            label: const Text('Save as Note'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _saveAsFlashcards,
                            icon: const Icon(Icons.style_outlined, size: 16),
                            label: const Text('Make Flashcards'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _toggleSpeakSummary,
                            icon: Icon(
                              _isSpeakingSummary
                                  ? Icons.stop_circle_rounded
                                  : Icons.volume_up_rounded,
                              size: 16,
                            ),
                            label: Text(
                              _isSpeakingSummary ? 'Stop Audio' : 'Listen 🔊',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _exportAsPdfCheatsheet,
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: const Text('Export A4 PDF 🖨️'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488), // Teal
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            tooltip: 'Copy Summary',
                            onPressed: _copySummaryToClipboard,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(bool isDark) {
    final summaryList = (_extractedKit?['summary'] as List<dynamic>?) ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: summaryList.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark
                : AppColors.primaryLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  summaryList[index].toString(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionsTab(bool isDark) {
    final questions = (_extractedKit?['questions'] as List<dynamic>?) ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final q = questions[index] as Map;
        final difficulty = q['difficulty']?.toString() ?? 'Medium';
        Color diffColor = AppColors.secondary;
        if (difficulty.toLowerCase() == 'hard') diffColor = AppColors.error;
        if (difficulty.toLowerCase() == 'easy') diffColor = AppColors.success;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      difficulty,
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
                q['question']?.toString() ?? '',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q['answer']?.toString() ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.4,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheatsheetTab(bool isDark) {
    final cheatsheet = (_extractedKit?['cheatsheet'] as List<dynamic>?) ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cheatsheet.length,
      itemBuilder: (context, index) {
        final item = cheatsheet[index] as Map;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.functions_rounded,
                      size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item['term']?.toString() ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                item['definition']?.toString() ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.text_snippet_rounded;
    }
  }

  Color _getFileColor(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return AppColors.error;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return const Color(0xFF06B6D4);
      case 'doc':
      case 'docx':
        return AppColors.primary;
      default:
        return AppColors.secondary;
    }
  }
}
