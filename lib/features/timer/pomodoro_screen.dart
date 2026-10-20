import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/local/ambient_sound_service.dart';
import '../../data/models/pomodoro_session_model.dart';
import 'pomodoro_controller.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with WidgetsBindingObserver {
  final TextEditingController _subjectController = TextEditingController(
    text: 'General Study',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(pomodoroControllerProvider.notifier).checkAppResumed();
      _checkWitheredAlert();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(pomodoroControllerProvider.notifier).checkAppPaused();
    }
  }

  void _checkWitheredAlert() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final timerState = ref.read(pomodoroControllerProvider);
      if (timerState.hasWitheredAlert) {
        ref.read(pomodoroControllerProvider.notifier).clearWitheredAlert();
        _showWitheredTreeDialog();
      }
    });
  }

  void _showWitheredTreeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🥀 ', style: TextStyle(fontSize: 26)),
            Expanded(
              child: Text(
                'Focus Broken! Tree Withered',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You exited StudyMate while Strict Anti-Distraction Mode was active.\n\nYour seedling withered into dry branches in your Forest Sanctuary.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              '💡 Tip: Keep StudyMate open and resist social media temptations during deep study!',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('I will stay focused! 💪'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerState = ref.watch(pomodoroControllerProvider);
    final controller = ref.read(pomodoroControllerProvider.notifier);

    Color modeColor = AppColors.primary;
    switch (timerState.mode) {
      case PomodoroMode.focus:
        modeColor = AppColors.primary;
        break;
      case PomodoroMode.shortBreak:
        modeColor = AppColors.secondary;
        break;
      case PomodoroMode.longBreak:
        modeColor = AppColors.success;
        break;
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Pomodoro',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.park_rounded, color: AppColors.success),
            tooltip: 'Virtual Study Garden',
            onPressed: () => context.push(AppRoutes.studyGarden),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => context.push(AppRoutes.timerHistory),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.timerSettings),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space16,
          ),
          child: Column(
            children: [
              // Modern Segmented Mode Selector Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F3F9),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeTab(
                        'Focus',
                        PomodoroMode.focus,
                        timerState.mode,
                        controller,
                        isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildModeTab(
                        'Short Break',
                        PomodoroMode.shortBreak,
                        timerState.mode,
                        controller,
                        isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildModeTab(
                        'Long Break',
                        PomodoroMode.longBreak,
                        timerState.mode,
                        controller,
                        isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space20),

              // Subject Input / Selector
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.book_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _subjectController,
                        onChanged: (val) => controller.setSubject(val.trim()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Current Topic / Subject',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space12),

              // Virtual Forest Focus Banner
              InkWell(
                onTap: () => context.push(AppRoutes.studyGarden),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Text('🌱', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Growing your virtual tree • +10 Coins 🪙 on completion',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.success),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space24),

              // Circular Animated Progress Countdown
              Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular Background
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 14,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark
                                ? AppColors.surfaceDark
                                : AppColors.primaryLight.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      // Circular Active Progress
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: timerState.progress,
                          strokeWidth: 14,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(modeColor),
                        ),
                      ),
                      // Time Text & Status
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (timerState.mode == PomodoroMode.focus) ...[
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                timerState.progress < 0.25
                                    ? '🌱'
                                    : (timerState.progress < 0.6
                                        ? '🌿'
                                        : (timerState.progress < 0.9
                                            ? '🪴'
                                            : '🌳')),
                                key: ValueKey((timerState.progress * 4).floor()),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            DateFormatter.formatDuration(
                              timerState.remainingSeconds,
                            ),
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: modeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                            ),
                            child: Text(
                              '${timerState.mode.displayName} • ${(timerState.progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: modeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space20),

              // 4 Rounds Progress Dots (Mockup Screen 17)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final sessionNum = index + 1;
                  final isCompleted =
                      (timerState.completedFocusSessions % 4) >= sessionNum ||
                      (timerState.completedFocusSessions > 0 &&
                          (timerState.completedFocusSessions % 4) == 0);
                  final isCurrent =
                      ((timerState.completedFocusSessions % 4) + 1) ==
                      sessionNum;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.primary
                          : (isCurrent
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : (isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.borderLight)),
                      border: Border.all(
                        color: (isCompleted || isCurrent)
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$sessionNum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? Colors.white
                            : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppDimensions.space28),

              // Timer Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset Button
                  IconButton.filledTonal(
                    iconSize: 24,
                    padding: const EdgeInsets.all(14),
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => controller.reset(),
                  ),
                  const SizedBox(width: AppDimensions.space24),

                  // Main Start / Pause / Resume Button with Gradient Glow
                  GestureDetector(
                    onTap: () {
                      if (timerState.status == TimerStateStatus.running) {
                        controller.pause();
                      } else if (timerState.status == TimerStateStatus.paused) {
                        controller.resume();
                      } else {
                        controller.start();
                      }
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        timerState.status == TimerStateStatus.running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space24),

                  // Skip Button
                  IconButton.filledTonal(
                    iconSize: 24,
                    padding: const EdgeInsets.all(14),
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () => controller.skip(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space24),

              // Strict Deep Focus (Anti-Distraction Mode) Card
              Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.space16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: timerState.isStrictMode
                      ? AppColors.error.withValues(alpha: isDark ? 0.15 : 0.08)
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: timerState.isStrictMode
                        ? AppColors.error.withValues(alpha: 0.5)
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    width: timerState.isStrictMode ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: timerState.isStrictMode
                            ? AppColors.error.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        timerState.isStrictMode
                            ? Icons.shield_rounded
                            : Icons.shield_outlined,
                        color: timerState.isStrictMode
                            ? AppColors.error
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'Strict Focus Mode',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: timerState.isStrictMode
                                      ? AppColors.error
                                      : Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  timerState.isStrictMode ? 'STRICT' : 'OFF',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: timerState.isStrictMode
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timerState.isStrictMode
                                ? 'Leaving the app will wither your tree 🥀'
                                : 'Protect your focus sessions from app switching',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: timerState.isStrictMode,
                      activeThumbColor: AppColors.error,
                      onChanged: (val) {
                        controller.toggleStrictMode(val);
                      },
                    ),
                  ],
                ),
              ),

              // Ambient Focus Soundscapes Card (Phase 2 Feature)
              Builder(
                builder: (context) {
                  final ambientState = ref.watch(ambientSoundServiceProvider);
                  final ambientNotifier = ref.read(ambientSoundServiceProvider.notifier);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.headphones_rounded,
                                color: AppColors.secondary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ambient Focus Soundscape',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    ambientState.currentSound == AmbientSoundType.none
                                        ? 'Select background noise to enhance concentration'
                                        : (ambientState.isPlaying
                                            ? 'Playing • Enhances focus & calm'
                                            : 'Paused'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ambientState.isPlaying
                                          ? AppColors.success
                                          : (isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight),
                                      fontWeight: ambientState.isPlaying
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (ambientState.currentSound != AmbientSoundType.none)
                              IconButton(
                                icon: Icon(
                                  ambientState.isPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded,
                                ),
                                color: AppColors.secondary,
                                iconSize: 32,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => ambientNotifier.togglePlayPause(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: kAmbientTracks.map((track) {
                              final isSelected =
                                  ambientState.currentSound == track.type;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  avatar: Text(
                                    track.iconEmoji,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  label: Text(track.title),
                                  selected: isSelected,
                                  selectedColor: AppColors.secondary.withValues(
                                    alpha: 0.2,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.secondary
                                        : (isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight),
                                  ),
                                  onSelected: (_) {
                                    ambientNotifier.selectSound(track.type);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        if (ambientState.currentSound != AmbientSoundType.none) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.volume_mute_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                  ),
                                  child: Slider(
                                    value: ambientState.volume,
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: AppColors.secondary,
                                    onChanged: (v) =>
                                        ambientNotifier.setVolume(v),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.volume_up_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(
    String label,
    PomodoroMode mode,
    PomodoroMode current,
    PomodoroController controller,
    bool isDark,
  ) {
    final isSelected = mode == current;
    return GestureDetector(
      onTap: () => controller.setMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textPrimaryLight),
            ),
          ),
        ),
      ),
    );
  }
}
