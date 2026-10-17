import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialogs.dart';
import 'auth_controller.dart';

class EmailVerificationScreen extends ConsumerWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go(AppRoutes.login),
        ),
        title: Text(
          'Email Verification',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Illustration (Matching Mockup Screen 7)
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space28),

              Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "We've sent a verification link to:\n${user?.email ?? 'your email'}\n\nPlease check your inbox and click the link to activate your account.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space32),

              AppButton(
                width: double.infinity,
                height: 50,
                text: 'Continue to Dashboard',
                variant: AppButtonVariant.primary,
                onPressed: () => context.go(AppRoutes.home),
              ),
              const SizedBox(height: AppDimensions.space12),

              AppButton(
                width: double.infinity,
                height: 50,
                text: 'Resend Email',
                variant: AppButtonVariant.outline,
                onPressed: () async {
                  await ref
                      .read(authControllerProvider.notifier)
                      .sendEmailVerification();
                  if (context.mounted) {
                    AppDialogs.showSnackBar(
                      context,
                      message: 'Verification link resent!',
                      isSuccess: true,
                    );
                  }
                },
              ),
              const SizedBox(height: AppDimensions.space16),

              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(
                    'Back to Login',
                    style: GoogleFonts.inter(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
