import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/local/preference_service.dart';
import '../auth/auth_controller.dart';
import '../home/home_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _goalController;
  String? _selectedAvatar;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentProfileProvider);
    final prefs = ref.read(preferenceServiceProvider);
    _nameController = TextEditingController(text: user?.displayName ?? '');
    final currentGoal = (user?.dailyGoalMinutes != null && user!.dailyGoalMinutes > 0)
        ? user.dailyGoalMinutes
        : prefs.getDailyGoalMinutes(user?.uid);
    _goalController = TextEditingController(
      text: currentGoal.toString(),
    );
    _selectedAvatar = user?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final photoString = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedAvatar = photoString;
        });
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Unable to select image from gallery: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final goalMins = int.tryParse(_goalController.text.trim()) ?? 0;
      final currentUser = ref.read(currentProfileProvider);

      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            displayName: _nameController.text.trim(),
            photoUrl: _selectedAvatar,
            dailyGoalMinutes: goalMins,
          );

      await ref.read(preferenceServiceProvider).setDailyGoalMinutes(goalMins, currentUser?.uid);
      ref.invalidate(homeDashboardProvider);

      if (!mounted) return;
      AppDialogs.showSnackBar(
        context,
        message: 'Profile updated and synced to cloud!',
        isSuccess: true,
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnackBar(
        context,
        message: 'Failed to update profile: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentProfileProvider);
    final currentName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (user?.displayName ?? 'Student');

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Preview & Selector
              Center(
                child: Column(
                  children: [
                    UserAvatar(
                      photoUrl: _selectedAvatar,
                      name: currentName,
                      size: 92,
                      showEditBadge: true,
                      onTap: _pickImageFromGallery,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text(
                        'Choose from Gallery',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Or choose a preset student avatar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Avatar Chips Selection
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildAvatarChip(
                            label: 'Gallery',
                            emoji: '🖼️',
                            isSelected: _selectedAvatar != null &&
                                !UserAvatar.avatarPresets
                                    .containsKey(_selectedAvatar) &&
                                _selectedAvatar!.isNotEmpty,
                            onTap: _pickImageFromGallery,
                            isDark: isDark,
                          ),
                          // Initial / Reset chip
                          _buildAvatarChip(
                            label: 'Initials',
                            emoji: (currentName.isNotEmpty ? currentName[0] : 'S')
                                .toUpperCase(),
                            isSelected: _selectedAvatar == null ||
                                _selectedAvatar!.isEmpty,
                            onTap: () {
                              setState(() => _selectedAvatar = null);
                            },
                            isDark: isDark,
                          ),
                          ...UserAvatar.avatarPresets.entries.map((entry) {
                            final isSelected = _selectedAvatar == entry.key;
                            return _buildAvatarChip(
                              label: entry.value.title,
                              emoji: entry.value.emoji,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() => _selectedAvatar = entry.key);
                              },
                              isDark: isDark,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space28),

              AppTextField(
                label: 'Student Name',
                hint: 'e.g. Alex Morgan',
                controller: _nameController,
                prefixIcon: Icons.person_outline_rounded,
                onChanged: (_) => setState(() {}),
                validator: (v) => Validators.validateRequired(v, 'Name'),
              ),
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                label: 'Email (Linked Account)',
                initialValue: user?.email ?? '',
                readOnly: true,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                label: 'Daily Study Goal (Minutes)',
                hint: 'e.g. 120',
                controller: _goalController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.timer_outlined,
                validator: (v) =>
                    Validators.validatePositiveNumber(v, 'Goal minutes'),
              ),
              const SizedBox(height: AppDimensions.space32),

              AppButton(
                text: 'Save & Sync Profile',
                isLoading: _isLoading,
                icon: Icons.cloud_done_rounded,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarChip({
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
