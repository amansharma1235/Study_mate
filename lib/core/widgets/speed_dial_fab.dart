import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../routing/route_names.dart';
import '../utils/app_haptics.dart';

/// Animated Speed-Dial Floating Action Button for rapid student actions
class SpeedDialFab extends StatefulWidget {
  const SpeedDialFab({super.key});

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    AppHaptics.selection();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      _toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Backdrop click to dismiss
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),

        // Speed Dial Items
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isOpen) ...[
                _buildSpeedDialItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Scan & Solve 📸',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    _close();
                    context.push(AppRoutes.aiAssistant, extra: 'SCAN_PHOTO');
                  },
                  isDark: isDark,
                  offsetIndex: 4,
                ),
                const SizedBox(height: 12),
                _buildSpeedDialItem(
                  icon: Icons.timer_rounded,
                  label: 'Focus Timer',
                  color: const Color(0xFFEC4899),
                  onTap: () {
                    _close();
                    context.push(AppRoutes.timer);
                  },
                  isDark: isDark,
                  offsetIndex: 3,
                ),
                const SizedBox(height: 12),
                _buildSpeedDialItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'New Task',
                  color: AppColors.success,
                  onTap: () {
                    _close();
                    context.push(AppRoutes.createTask);
                  },
                  isDark: isDark,
                  offsetIndex: 2,
                ),
                const SizedBox(height: 12),
                _buildSpeedDialItem(
                  icon: Icons.style_rounded,
                  label: 'New Flashcards',
                  color: const Color(0xFF0D9488),
                  onTap: () {
                    _close();
                    context.push(AppRoutes.createDeck);
                  },
                  isDark: isDark,
                  offsetIndex: 1,
                ),
                const SizedBox(height: 12),
                _buildSpeedDialItem(
                  icon: Icons.edit_note_rounded,
                  label: 'Quick Note',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    _close();
                    context.push(AppRoutes.createNote);
                  },
                  isDark: isDark,
                  offsetIndex: 0,
                ),
                const SizedBox(height: 16),
              ],

              // Main Toggle FAB
              FloatingActionButton(
                heroTag: 'main_speed_dial_fab',
                backgroundColor: AppColors.primary,
                elevation: 6,
                onPressed: _toggle,
                child: RotationTransition(
                  turns: _rotateAnimation,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    required int offsetIndex,
  }) {
    return ScaleTransition(
      scale: _expandAnimation,
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
