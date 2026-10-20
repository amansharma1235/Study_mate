import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../data/local/voice_study_service.dart';

class AudioCapsuleSheet extends ConsumerStatefulWidget {
  final String noteTitle;
  final String noteContent;
  final String category;

  const AudioCapsuleSheet({
    super.key,
    required this.noteTitle,
    required this.noteContent,
    required this.category,
  });

  static void show(
    BuildContext context, {
    required String noteTitle,
    required String noteContent,
    required String category,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AudioCapsuleSheet(
        noteTitle: noteTitle,
        noteContent: noteContent,
        category: category,
      ),
    );
  }

  @override
  ConsumerState<AudioCapsuleSheet> createState() => _AudioCapsuleSheetState();
}

class _AudioCapsuleSheetState extends ConsumerState<AudioCapsuleSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isPlaying = false;
  double _playbackRate = 1.0;
  late String _podcastScript;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _preparePodcastScript();
  }

  void _preparePodcastScript() {
    final cleanContent = widget.noteContent
        .replaceAll(RegExp(r'\*\*|\*|__|###|##|#|---'), ' ')
        .replaceAll(RegExp(r'`{1,3}[^`]*`{1,3}'), 'code snippet')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    _podcastScript =
        'Welcome to your StudyMate Audio Revision Capsule for ${widget.noteTitle}. '
        'Subject: ${widget.category}. '
        'Here is your high-yield audio revision breakdown. '
        '$cleanContent. '
        'That concludes your quick audio revision for ${widget.noteTitle}. Keep learning and stay confident!';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    ref.read(voiceStudyServiceProvider).stopSpeaking();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    final voice = ref.read(voiceStudyServiceProvider);
    AppHaptics.selection();

    if (_isPlaying) {
      await voice.stopSpeaking();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      if (mounted) setState(() => _isPlaying = true);
      await voice.speak(
        _podcastScript,
        onStart: () {
          if (mounted) setState(() => _isPlaying = true);
        },
        onComplete: () {
          if (mounted) setState(() => _isPlaying = false);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.podcasts_rounded, color: AppColors.secondary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audio Revision Capsule 🎙️',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${widget.noteTitle} • Listen & Learn',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Podcast Waveform / Sound Capsule Hero
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
                    : [const Color(0xFFEEF2FF), const Color(0xFFFAF5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                // Animated sound icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = _isPlaying
                        ? 1.0 + (_pulseController.value * 0.15)
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: _isPlaying ? 0.45 : 0.2),
                              blurRadius: _isPlaying ? 24 : 12,
                              spreadRadius: _isPlaying ? 4 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying ? Icons.graphic_eq_rounded : Icons.headset_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  _isPlaying ? 'Audio Capsule Playing 🔊' : 'Ready to Listen',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying
                      ? 'Listen while on the move or resting your eyes'
                      : 'Tap play to listen to this note as an audio podcast',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Speed & Playback Controls Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rate toggle
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    AppHaptics.selection();
                    setState(() {
                      if (_playbackRate == 1.0) {
                        _playbackRate = 1.25;
                      } else if (_playbackRate == 1.25) {
                        _playbackRate = 1.5;
                      } else if (_playbackRate == 1.5) {
                        _playbackRate = 2.0;
                      } else {
                        _playbackRate = 1.0;
                      }
                    });
                  },
                  child: Text(
                    '${_playbackRate}x Speed',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 24),

                // Main Play/Pause Button
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Stop button
                IconButton.filledTonal(
                  icon: const Icon(Icons.stop_rounded),
                  onPressed: () {
                    ref.read(voiceStudyServiceProvider).stopSpeaking();
                    if (mounted) setState(() => _isPlaying = false);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Live Transcript View
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.article_rounded,
                  size: 16,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Transcript & Summary Points',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2337) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: SelectableText(
                  _podcastScript,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
