import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/local/app_database.dart';
import '../../data/models/voice_note_model.dart';
import '../auth/auth_controller.dart';

class VoiceNotesScreen extends ConsumerStatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  ConsumerState<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends ConsumerState<VoiceNotesScreen> {
  List<VoiceNoteModel> _notes = [];
  bool _isLoading = true;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final user = ref.read(currentProfileProvider);
    final userId = user?.uid ?? 'guest';
    final db = ref.read(appDatabaseProvider);
    var list = await db.getVoiceNotes(userId);

    if (list.isEmpty) {
      final starter = [
        VoiceNoteModel(
          id: 'vn-1',
          userId: userId,
          title: 'Professor Lecture on AVL Rotations',
          subject: 'Computer Science',
          audioPath: '/audio/lecture_avl.m4a',
          durationSeconds: 142,
          transcription: 'Key note: Remember single rotation for LL/RR imbalances, double rotation for LR/RL.',
        ),
        VoiceNoteModel(
          id: 'vn-2',
          userId: userId,
          title: 'Physics Lab Viva Quick Summary',
          subject: 'Physics',
          audioPath: '/audio/physics_viva.m4a',
          durationSeconds: 78,
          transcription: 'Screw gauge pitch is 1mm with 100 divisions, least count 0.01mm.',
        ),
      ];
      for (final n in starter) {
        await db.insertVoiceNote(n);
      }
      list = starter;
    }

    if (mounted) {
      setState(() {
        _notes = list;
        _isLoading = false;
      });
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _recordingSeconds++);
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    final duration = _recordingSeconds;
    setState(() => _isRecording = false);
    _showSaveRecordingDialog(duration);
  }

  void _showSaveRecordingDialog(int duration) {
    final titleCtrl = TextEditingController(
      text: 'Voice Note ${_notes.length + 1}',
    );
    final subjectCtrl = TextEditingController(text: 'General');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Voice Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: titleCtrl,
                label: 'Note Title',
                hint: 'e.g. Chemistry Formula Recap',
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: subjectCtrl,
                label: 'Subject',
                hint: 'e.g. Chemistry',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final user = ref.read(currentProfileProvider);
              final userId = user?.uid ?? 'guest';
              final newNote = VoiceNoteModel(
                id: 'vn-${DateTime.now().millisecondsSinceEpoch}',
                userId: userId,
                title: titleCtrl.text.trim(),
                subject: subjectCtrl.text.trim(),
                audioPath:
                    '/audio/vn_${DateTime.now().millisecondsSinceEpoch}.m4a',
                durationSeconds: duration > 0 ? duration : 45,
              );
              await ref.read(appDatabaseProvider).insertVoiceNote(newNote);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadNotes();
            },
            child: const Text(
              'Save Recording',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          'Voice Notes & Lectures',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Active Recording Banner
                if (_isRecording)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Recording Audio... ${_formatSeconds(_recordingSeconds)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          icon: const Icon(
                            Icons.stop_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Stop',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: _stopRecording,
                        ),
                      ],
                    ),
                  ),

                // Recordings List
                Expanded(
                  child: _notes.isEmpty
                      ? Center(
                          child: Text(
                            'No voice notes recorded yet',
                            style: TextStyle(color: AppColors.textMutedLight),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          itemCount: _notes.length,
                          itemBuilder: (context, idx) {
                            final note = _notes[idx];
                            final isPlaying = _currentlyPlayingId == note.id;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // Play / Pause Circle
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.12),
                                      ),
                                      icon: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: AppColors.primary,
                                        size: 26,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _currentlyPlayingId = isPlaying
                                              ? null
                                              : note.id;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 12),

                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            note.title,
                                            style: GoogleFonts.inter(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.textPrimaryDark
                                                  : AppColors.textPrimaryLight,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Text(
                                                note.subject,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '• ${note.formattedDuration}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? AppColors
                                                            .textSecondaryDark
                                                      : AppColors
                                                            .textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (note
                                              .transcription
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '📝 ${note.transcription}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: isDark
                                                    ? AppColors.textMutedDark
                                                    : AppColors.textMutedLight,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Delete
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () async {
                                        await ref
                                            .read(appDatabaseProvider)
                                            .deleteVoiceNote(note.id);
                                        _loadNotes();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _isRecording ? AppColors.error : AppColors.primary,
        icon: Icon(
          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
        ),
        label: Text(
          _isRecording ? 'Stop Recording' : 'Record Audio Note',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        onPressed: () {
          if (_isRecording) {
            _stopRecording();
          } else {
            _startRecording();
          }
        },
      ),
    );
  }

  String _formatSeconds(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
