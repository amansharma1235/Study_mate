import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../data/local/preference_service.dart';
import '../../data/models/note_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/remote/gemini_service.dart';
import '../flashcards/flashcards_controller.dart';
import '../quiz/quiz_controller.dart';
import 'notes_controller.dart';
import 'widgets/audio_capsule_sheet.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final NoteModel note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late NoteModel _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
  }

  int get _wordCount {
    final text = _currentNote.content.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

  int get _charCount => _currentNote.content.length;

  int get _readingMinutes => (_wordCount / 200).ceil();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allNotes = ref.watch(notesControllerProvider).valueOrNull ?? [];
    _currentNote = allNotes.firstWhere(
      (n) => n.id == _currentNote.id,
      orElse: () => _currentNote,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Note Details'),
        actions: [
          // Pin Action with reactive state
          IconButton(
            icon: Icon(
              _currentNote.isPinned
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
            ),
            color: _currentNote.isPinned ? AppColors.primary : null,
            tooltip: _currentNote.isPinned ? 'Unpin Note' : 'Pin Note to Top',
            onPressed: () async {
              AppHaptics.light();
              await ref
                  .read(notesControllerProvider.notifier)
                  .togglePin(_currentNote);
              if (context.mounted) {
                AppDialogs.showSnackBar(
                  context,
                  message: _currentNote.isPinned
                      ? 'Note unpinned'
                      : 'Note pinned to top',
                  isSuccess: true,
                );
              }
            },
          ),

          // Ask AI Tutor to Summarize Note
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            color: AppColors.primary,
            tooltip: 'Summarize with AI Tutor',
            onPressed: () {
              AppHaptics.selection();
              context.push(
                AppRoutes.aiAssistant,
                extra:
                    'Please summarize this lecture note and give 3 high-yield review takeaways:\n\nTitle: ${_currentNote.title}\nCategory: ${_currentNote.category}\nContent:\n${_currentNote.content}',
              );
            },
          ),

          // Audio Revision Capsule
          IconButton(
            icon: const Icon(Icons.podcasts_rounded),
            color: AppColors.secondary,
            tooltip: 'Audio Revision Capsule 🎙️',
            onPressed: () {
              AppHaptics.selection();
              AudioCapsuleSheet.show(
                context,
                noteTitle: _currentNote.title,
                noteContent: _currentNote.content,
                category: _currentNote.category,
              );
            },
          ),

          // Edit Note
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Note',
            onPressed: () async {
              AppHaptics.selection();
              await context.push(AppRoutes.editNote, extra: _currentNote);
            },
          ),

          // More Options Menu (PDF Export, Flashcards, Copy, Delete)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More Actions',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (val) async {
              AppHaptics.selection();
              if (val == 'audio_capsule') {
                AudioCapsuleSheet.show(
                  context,
                  noteTitle: _currentNote.title,
                  noteContent: _currentNote.content,
                  category: _currentNote.category,
                );
              } else if (val == 'export_pdf') {
                _exportNoteAsPdf(context);
              } else if (val == 'flashcards') {
                _showGenerateFlashcardsSheet(context);
              } else if (val == 'quiz') {
                _showGenerateQuizSheet(context);
              } else if (val == 'copy') {
                Clipboard.setData(
                  ClipboardData(
                    text: '# ${_currentNote.title}\n\n${_currentNote.content}',
                  ),
                );
                AppDialogs.showSnackBar(
                  context,
                  message: 'Note copied to clipboard',
                  isSuccess: true,
                );
              } else if (val == 'delete') {
                final confirm = await AppDialogs.showConfirmDialog(
                  context: context,
                  title: 'Delete Note',
                  message:
                      'Are you sure you want to delete "${_currentNote.title}"? This action cannot be undone.',
                  confirmText: 'Delete',
                  isDestructive: true,
                );
                if (confirm == true) {
                  await ref
                      .read(notesControllerProvider.notifier)
                      .deleteNote(_currentNote.id);
                  if (context.mounted) {
                    AppDialogs.showSnackBar(
                      context,
                      message: 'Note deleted',
                      isSuccess: true,
                    );
                    context.pop();
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'audio_capsule',
                child: Row(
                  children: [
                    Icon(Icons.podcasts_rounded,
                        color: AppColors.secondary, size: 20),
                    SizedBox(width: 10),
                    Text('Audio Capsule 🎙️',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Export as PDF 📄',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'flashcards',
                child: Row(
                  children: [
                    Icon(Icons.style_outlined,
                        color: AppColors.secondary, size: 20),
                    SizedBox(width: 10),
                    Text('AI Flashcards ⚡',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'quiz',
                child: Row(
                  children: [
                    Icon(Icons.quiz_outlined,
                        color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Text('AI Quiz Test 📝',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, color: Colors.grey, size: 20),
                    SizedBox(width: 10),
                    Text('Copy Note 📋',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('Delete Note',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata & Category Tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _currentNote.category,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (_currentNote.isPinned) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin, size: 12, color: AppColors.primary),
                        SizedBox(width: 3),
                        Text(
                          'Pinned',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'Updated: ${DateFormatter.formatDateTime(_currentNote.updatedAt)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reading stats chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.6)
                    : const Color(0xFFF1F3F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.text_snippet_outlined,
                    size: 14,
                    color: AppColors.textMutedLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_wordCount words • $_charCount characters • ~$_readingMinutes min read',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Note Title
            Text(
              _currentNote.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                letterSpacing: -0.3,
              ),
            ),
            const Divider(height: 28),

            // Note Body Content
            SelectableText(
              _currentNote.content,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 32),

            // 1-Tap AI Action Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                    AppColors.secondary.withValues(alpha: isDark ? 0.15 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Study with AI Tutor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Generate flashcards, practice questions, or a high-yield summary of this note.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.style_rounded, size: 14, color: Colors.white),
                        label: const Text('Flashcards', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () => _showGenerateFlashcardsSheet(context),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.primary),
                        label: const Text('Ask AI', style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        onPressed: () {
                          context.push(
                            AppRoutes.aiAssistant,
                            extra:
                                'Please summarize this lecture note and generate 3 practice quiz questions from it:\n\nTitle: ${_currentNote.title}\nCategory: ${_currentNote.category}\nContent:\n${_currentNote.content}',
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.podcasts_rounded, size: 13, color: AppColors.secondary),
                        label: const Text('Audio 🎙️', style: TextStyle(color: AppColors.secondary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          side: const BorderSide(color: AppColors.secondary),
                        ),
                        onPressed: () {
                          AudioCapsuleSheet.show(
                            context,
                            noteTitle: _currentNote.title,
                            noteContent: _currentNote.content,
                            category: _currentNote.category,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateFlashcardsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isLoading = true;
    bool isSaving = false;
    List<Map<String, String>> generatedCards = [];
    String? selectedDeckId;
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          // Trigger generation on first build
          if (isLoading && generatedCards.isEmpty && errorMessage.isEmpty) {
            Future.microtask(() async {
              try {
                // Get API key from preferences or constants
                String apiKey = '';
                try {
                  apiKey = ref.read(preferenceServiceProvider).getGeminiApiKey();
                } catch (_) {}
                if (apiKey.isEmpty) {
                  apiKey = AppConstants.defaultGeminiApiKey;
                }

                final cards = await ref
                    .read(geminiServiceProvider)
                    .generateFlashcardsFromNote(
                      title: _currentNote.title,
                      content: _currentNote.content,
                      apiKey: apiKey,
                    );

                if (sheetCtx.mounted) {
                  setSheetState(() {
                    generatedCards = cards;
                    isLoading = false;
                  });
                }
              } catch (e) {
                if (sheetCtx.mounted) {
                  setSheetState(() {
                    errorMessage = 'Could not generate flashcards: $e';
                    isLoading = false;
                  });
                }
              }
            });
          }

          final decksAsync = ref.watch(flashcardDecksProvider);
          final existingDecks = decksAsync.value ?? [];

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.style_rounded, color: AppColors.secondary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Flashcards Generator',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                            ),
                            Text(
                              'Extracts high-yield Q&A pairs for active recall',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Loading State
                  if (isLoading) ...[
                    const Spacer(),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Analyzing "${_currentNote.title}"...',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Extracting definitions, formulas, and core takeaways',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ] else if (errorMessage.isNotEmpty) ...[
                    const Spacer(),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                          const SizedBox(height: 12),
                          Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ] else ...[
                    // Cards generated list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${generatedCards.length} Flashcards Generated',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          'Ready to add to deck',
                          style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Destination Deck Picker
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : const Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDeckId,
                          hint: Text(
                            'Create new deck: "${_currentNote.title}"',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                '📁 Auto: New deck ("${_currentNote.title}")',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            ...existingDecks.map((deck) {
                              return DropdownMenuItem<String>(
                                value: deck.id,
                                child: Text(
                                  '🗂️ ${deck.title} (${deck.cardCount} cards)',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setSheetState(() => selectedDeckId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Scrollable Cards Preview
                    Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        itemCount: generatedCards.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final card = generatedCards[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF222533) : const Color(0xFFF9FAFD),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Q${i + 1}',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setSheetState(() {
                                          generatedCards.removeAt(i);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  card['question'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                const Divider(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ans: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.success)),
                                    Expanded(
                                      child: Text(
                                        card['answer'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.4,
                                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                        label: Text(
                          isSaving
                              ? 'Saving to Deck...'
                              : 'Save ${generatedCards.length} Cards to Deck',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSaving || generatedCards.isEmpty
                            ? null
                            : () async {
                                setSheetState(() => isSaving = true);
                                try {
                                  final controller = ref.read(flashcardDecksProvider.notifier);
                                  String targetDeckId = selectedDeckId ?? '';

                                  if (targetDeckId.isEmpty) {
                                    final deck = await controller.getOrCreateDeckForSubject(
                                      subject: _currentNote.category,
                                      title: '${_currentNote.title} Flashcards',
                                    );
                                    targetDeckId = deck.id;
                                  }

                                  await controller.addMultipleCardsToDeck(
                                    deckId: targetDeckId,
                                    cards: generatedCards,
                                  );

                                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);

                                  if (context.mounted) {
                                    AppDialogs.showSnackBar(
                                      context,
                                      message: '✅ Added ${generatedCards.length} flashcards to deck!',
                                      isSuccess: true,
                                    );
                                  }
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (sheetCtx.mounted) {
                                    AppDialogs.showSnackBar(
                                      sheetCtx,
                                      message: 'Failed to save cards: $e',
                                      isError: true,
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGenerateQuizSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isLoading = true;
    List<QuizQuestion> generatedQuestions = [];
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          if (isLoading && generatedQuestions.isEmpty && errorMessage.isEmpty) {
            Future.microtask(() async {
              try {
                String apiKey = '';
                try {
                  apiKey = ref.read(preferenceServiceProvider).getGeminiApiKey();
                } catch (_) {}
                if (apiKey.isEmpty) {
                  apiKey = AppConstants.defaultGeminiApiKey;
                }

                final questions = await ref
                    .read(geminiServiceProvider)
                    .generateQuizFromNote(
                      title: _currentNote.title,
                      content: _currentNote.content,
                      category: _currentNote.category,
                      apiKey: apiKey,
                    );

                if (sheetCtx.mounted) {
                  setSheetState(() {
                    generatedQuestions = questions;
                    isLoading = false;
                  });
                }
              } catch (e) {
                if (sheetCtx.mounted) {
                  setSheetState(() {
                    errorMessage = 'Could not generate quiz: $e';
                    isLoading = false;
                  });
                }
              }
            });
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.quiz_rounded, color: Colors.orange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Quiz Generator',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                            ),
                            Text(
                              'High-yield MCQs generated from your lecture notes',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (isLoading) ...[
                    const Spacer(),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.orange),
                          const SizedBox(height: 16),
                          Text(
                            'Generating MCQs for "${_currentNote.title}"...',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'AI is crafting questions with multiple choices and explanations',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ] else if (errorMessage.isNotEmpty) ...[
                    const Spacer(),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                          const SizedBox(height: 12),
                          Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${generatedQuestions.length} Questions Ready',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Exam Mode',
                            style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        itemCount: generatedQuestions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final q = generatedQuestions[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF222533) : const Color(0xFFF9FAFD),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Q${i + 1}',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.orange),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        q.question,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(q.options.length, (optIdx) {
                                  final isCorrect = optIdx == q.correctIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                          size: 14,
                                          color: isCorrect ? AppColors.success : Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            q.options[optIdx],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isCorrect ? FontWeight.w700 : FontWeight.w400,
                                              color: isCorrect ? AppColors.success : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        label: Text(
                          'Start Quiz with ${generatedQuestions.length} Questions 🚀',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: generatedQuestions.isEmpty
                            ? null
                            : () {
                                ref.read(quizSessionControllerProvider.notifier).startCustomQuiz(
                                      _currentNote.title,
                                      generatedQuestions,
                                    );
                                Navigator.pop(sheetCtx);
                                context.push(AppRoutes.quizQuestions);
                              },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportNoteAsPdf(BuildContext context) async {
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context pwContext) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      _currentNote.title,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo50,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      _currentNote.category,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Generated via StudyMate • ${DateFormat('MMMM d, yyyy • hh:mm a').format(_currentNote.updatedAt)}',
              style:
                  const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 12),
            pw.Paragraph(
              text: _currentNote.content,
              style: const pw.TextStyle(fontSize: 11.5, lineSpacing: 2),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name:
            '${_currentNote.title.replaceAll(RegExp(r'[^\w\s]+'), '_')}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Failed to export PDF: $e',
          isError: true,
        );
      }
    }
  }
}
