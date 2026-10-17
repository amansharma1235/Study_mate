import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/date_formatter.dart';
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
    }
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
          'Pomodoro Focus',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
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
              const SizedBox(height: AppDimensions.space32),

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
                          Text(
                            DateFormatter.formatDuration(
                              timerState.remainingSeconds,
                            ),
                            style: TextStyle(
                              fontSize: 52,
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
                              timerState.mode.displayName,
                              style: TextStyle(
                                fontSize: 13,
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
