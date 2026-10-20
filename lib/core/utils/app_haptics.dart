import 'package:flutter/services.dart';

/// Centralized tactile haptic feedback service for professional touch delight
class AppHaptics {
  AppHaptics._();

  /// Very light subtle tap (e.g. checkbox toggle, micro clicks)
  static void light() => HapticFeedback.lightImpact();

  /// Standard button click or tab change
  static void selection() => HapticFeedback.selectionClick();

  /// Medium tactile feel (e.g. card flip, timer finish, badge unlock)
  static void medium() => HapticFeedback.mediumImpact();

  /// Firm vibration (e.g. level up, milestone achievement)
  static void heavy() => HapticFeedback.heavyImpact();

  /// Double-pulse celebration pattern for completed tasks / XP earned
  static void celebration() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    HapticFeedback.mediumImpact();
  }
}
