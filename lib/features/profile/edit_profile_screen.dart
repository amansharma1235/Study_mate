import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/app_text_field.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentProfileProvider);
    final prefs = ref.read(preferenceServiceProvider);
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _goalController = TextEditingController(
      text: (user?.dailyGoalMinutes ?? prefs.getDailyGoalMinutes()).toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final goalMins = int.tryParse(_goalController.text.trim()) ?? 120;

      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            displayName: _nameController.text.trim(),
            dailyGoalMinutes: goalMins,
          );

      await ref.read(preferenceServiceProvider).setDailyGoalMinutes(goalMins);
      ref.invalidate(homeDashboardProvider);

      if (!mounted) return;
      AppDialogs.showSnackBar(
        context,
        message: 'Profile updated successfully!',
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

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Student Name',
                hint: 'e.g. Alex Morgan',
                controller: _nameController,
                validator: (v) => Validators.validateRequired(v, 'Name'),
              ),
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                label: 'Email (Read Only)',
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
                validator: (v) =>
                    Validators.validatePositiveNumber(v, 'Goal minutes'),
              ),
              const SizedBox(height: AppDimensions.space32),

              AppButton(
                text: 'Save Changes',
                isLoading: _isLoading,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
