import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/local/app_database.dart';
import '../auth/auth_controller.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Permanently Delete Account?',
      message: 'This will delete your user profile, notes, tasks, exams, and study logs forever. This action cannot be reversed.',
      confirmText: 'Delete Permanently',
      isDestructive: true,
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentProfileProvider);
      final userId = user?.uid ?? '';

      // Clear local database records
      if (userId.isNotEmpty) {
        await ref.read(appDatabaseProvider).clearAllUserData(userId);
      }

      // Delete Firebase/local account
      await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(password: _passwordController.text);

      if (!mounted) return;
      AppDialogs.showSnackBar(context, message: 'Account permanently deleted.');
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnackBar(context, message: e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Delete Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Warning: Account deletion is permanent and cannot be undone.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space24),
              Text(
                'Please confirm your password to authenticate account deletion:',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                label: 'Password',
                hint: '••••••••',
                controller: _passwordController,
                isPassword: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: AppDimensions.space32),

              AppButton(
                text: 'Confirm & Delete Account',
                variant: AppButtonVariant.danger,
                isLoading: _isLoading,
                onPressed: _handleDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
