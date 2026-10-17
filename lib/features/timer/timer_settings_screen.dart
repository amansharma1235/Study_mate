import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../data/local/preference_service.dart';
import 'pomodoro_controller.dart';

class TimerSettingsScreen extends ConsumerStatefulWidget {
  const TimerSettingsScreen({super.key});

  @override
  ConsumerState<TimerSettingsScreen> createState() =>
      _TimerSettingsScreenState();
}

class _TimerSettingsScreenState extends ConsumerState<TimerSettingsScreen> {
  late int _focusMinutes;
  late int _shortBreakMinutes;
  late int _longBreakMinutes;
  late int _sessionsBeforeLongBreak;
  late bool _soundEnabled;
  late bool _vibrationEnabled;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferenceServiceProvider);
    _focusMinutes = prefs.getPomodoroFocusMinutes();
    _shortBreakMinutes = prefs.getPomodoroShortBreakMinutes();
    _longBreakMinutes = prefs.getPomodoroLongBreakMinutes();
    _sessionsBeforeLongBreak = prefs.getSessionsBeforeLongBreak();
    _soundEnabled = prefs.isSoundEnabled();
    _vibrationEnabled = prefs.isVibrationEnabled();
  }

  Future<void> _saveSettings() async {
    final prefs = ref.read(preferenceServiceProvider);
    await prefs.setPomodoroFocusMinutes(_focusMinutes);
    await prefs.setPomodoroShortBreakMinutes(_shortBreakMinutes);
    await prefs.setPomodoroLongBreakMinutes(_longBreakMinutes);
    await prefs.setSessionsBeforeLongBreak(_sessionsBeforeLongBreak);
    await prefs.setSoundEnabled(_soundEnabled);
    await prefs.setVibrationEnabled(_vibrationEnabled);

    // Refresh timer controller state
    final controller = ref.read(pomodoroControllerProvider.notifier);
    final currentState = ref.read(pomodoroControllerProvider);
    controller.setMode(currentState.mode);

    if (mounted) {
      AppDialogs.showSnackBar(
        context,
        message: 'Timer settings saved!',
        isSuccess: true,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Timer Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDurationSlider(
              title: 'Focus Duration',
              value: _focusMinutes,
              min: 5,
              max: 90,
              unit: 'mins',
              onChanged: (val) => setState(() => _focusMinutes = val.toInt()),
              isDark: isDark,
            ),
            const SizedBox(height: AppDimensions.space20),

            _buildDurationSlider(
              title: 'Short Break Duration',
              value: _shortBreakMinutes,
              min: 1,
              max: 15,
              unit: 'mins',
              onChanged: (val) =>
                  setState(() => _shortBreakMinutes = val.toInt()),
              isDark: isDark,
            ),
            const SizedBox(height: AppDimensions.space20),

            _buildDurationSlider(
              title: 'Long Break Duration',
              value: _longBreakMinutes,
              min: 5,
              max: 45,
              unit: 'mins',
              onChanged: (val) =>
                  setState(() => _longBreakMinutes = val.toInt()),
              isDark: isDark,
            ),
            const SizedBox(height: AppDimensions.space20),

            _buildDurationSlider(
              title: 'Sessions Before Long Break',
              value: _sessionsBeforeLongBreak,
              min: 2,
              max: 8,
              unit: 'rounds',
              onChanged: (val) =>
                  setState(() => _sessionsBeforeLongBreak = val.toInt()),
              isDark: isDark,
            ),
            const SizedBox(height: AppDimensions.space20),

            SwitchListTile(
              value: _soundEnabled,
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Sound Alerts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Play chime when session concludes'),
              onChanged: (val) => setState(() => _soundEnabled = val),
            ),
            SwitchListTile(
              value: _vibrationEnabled,
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Vibration Feedback',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Vibrate device upon interval completion'),
              onChanged: (val) => setState(() => _vibrationEnabled = val),
            ),
            const SizedBox(height: AppDimensions.space32),

            AppButton(text: 'Save Preferences', onPressed: _saveSettings),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSlider({
    required String title,
    required int value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
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
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '$value $unit',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
