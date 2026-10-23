import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../data/local/preference_service.dart';
import '../../data/remote/auth_service.dart';
import '../auth/auth_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = const [
    {
      'title': 'Welcome to StudyMate',
      'desc':
          'Your all-in-one student companion for better learning and higher goals.',
      'image': 'assets/images/onboarding_1.png',
    },
    {
      'title': 'Stay Organized',
      'desc':
          'Manage your notes, tasks, timetable and more — all in one place.',
      'image': 'assets/images/onboarding_2.png',
    },
    {
      'title': 'Achieve Your Goals',
      'desc':
          'Track your progress, prepare for exams and become the best version of yourself.',
      'image': 'assets/images/onboarding_3.png',
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(preferenceServiceProvider);
    await prefs.setOnboardingDone(true);
    if (!mounted) return;

    final user = ref.read(currentProfileProvider) ??
        await ref.read(authServiceProvider).getCurrentUser();
    if (!mounted) return;
    if (user != null) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space16,
          ),
          child: Column(
            children: [
              // Top Spacing / Breathing room matching the master design
              const SizedBox(height: 12),

              // Page Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, idx) {
                    final item = _pages[idx];

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final maxImgHeight = (constraints.maxHeight * 0.46)
                            .clamp(180.0, 270.0);

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Mockup Illustration
                                Container(
                                  height: maxImgHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.25 : 0.06,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.asset(
                                      item['image'] as String,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.space32),

                                // Mockup Title (Heading 2: 24/32 Semibold / Bold)
                                Text(
                                  item['title'] as String,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.space12),

                                // Mockup Description
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    item['desc'] as String,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Page Indicator (Active dot: elongated pill matching mockup)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (idx) {
                  final isSelected = _currentPage == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 24 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.borderDark
                                : const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppDimensions.space28),

              // Primary Action Button (Next / Get Started)
              AppButton(
                width: double.infinity,
                height: 52,
                text: _currentPage == _pages.length - 1
                    ? 'Get Started'
                    : 'Next',
                variant: AppButtonVariant.primary,
                onPressed: () {
                  if (_currentPage == _pages.length - 1) {
                    _completeOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
              const SizedBox(height: 8),

              // Secondary Skip Button (Matching mockup screens 2 & 3)
              if (_currentPage < _pages.length - 1)
                TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                const SizedBox(height: 48), // Preserves button position without jump
            ],
          ),
        ),
      ),
    );
  }
}
