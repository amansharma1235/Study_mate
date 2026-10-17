import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.size = 80,
    this.onTap,
    this.showEditBadge = false,
  });

  static const Map<String, ({String emoji, String title})> avatarPresets = {
    'avatar:scholar': (emoji: '🎓', title: 'Scholar'),
    'avatar:rocket': (emoji: '🚀', title: 'Achiever'),
    'avatar:spark': (emoji: '⚡', title: 'Prodigy'),
    'avatar:coder': (emoji: '💻', title: 'Coder'),
    'avatar:brain': (emoji: '🧠', title: 'Mastermind'),
    'avatar:artist': (emoji: '🎨', title: 'Creative'),
    'avatar:reader': (emoji: '📚', title: 'Bookworm'),
    'avatar:leader': (emoji: '🦁', title: 'Leader'),
  };

  @override
  Widget build(BuildContext context) {
    final cleanPhoto = photoUrl?.trim();
    final isPreset =
        cleanPhoto != null && avatarPresets.containsKey(cleanPhoto);
    final isNetworkUrl =
        cleanPhoto != null &&
        (cleanPhoto.startsWith('http://') || cleanPhoto.startsWith('https://'));

    Widget avatarContent;

    if (isPreset) {
      final preset = avatarPresets[cleanPhoto]!;
      avatarContent = Center(
        child: Text(
          preset.emoji,
          style: TextStyle(
            fontSize: size * 0.48,
            height: 1.1,
          ),
        ),
      );
    } else if (isNetworkUrl) {
      avatarContent = ClipOval(
        child: Image.network(
          cleanPhoto,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(),
        ),
      );
    } else {
      avatarContent = _buildFallbackInitial();
    }

    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: avatarContent,
    );

    if (showEditBadge) {
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildFallbackInitial() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.44,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
