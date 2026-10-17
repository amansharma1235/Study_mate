import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/exam_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/timetable_model.dart';
import '../../features/auth/email_verification_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/reset_password_feedback_screen.dart';
import '../../features/calculator/multi_subject_calculator_screen.dart';
import '../../features/calculator/percentage_calculator_screen.dart';
import '../../features/exams/exam_create_edit_screen.dart';
import '../../features/exams/exams_list_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/navigation/main_scaffold_screen.dart';
import '../../features/notes/note_create_edit_screen.dart';
import '../../features/notes/note_detail_screen.dart';
import '../../features/notes/notes_list_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/quiz/answer_review_screen.dart';
import '../../features/quiz/quiz_categories_screen.dart';
import '../../features/quiz/quiz_questions_screen.dart';
import '../../features/quiz/quiz_results_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/settings/appearance_settings_screen.dart';
import '../../features/settings/data_export_screen.dart';
import '../../features/settings/delete_account_screen.dart';
import '../../features/settings/help_support_screen.dart';
import '../../features/settings/more_tools_screen.dart';
import '../../features/settings/notification_settings_screen.dart';
import '../../features/settings/privacy_policy_screen.dart';
import '../../features/settings/terms_conditions_screen.dart';
import '../../features/statistics/study_statistics_screen.dart';
import '../../features/study_tips/saved_tips_screen.dart';
import '../../features/study_tips/study_tips_screen.dart';
import '../../features/tasks/task_create_edit_screen.dart';
import '../../features/tasks/tasks_list_screen.dart';
import '../../features/timetable/timetable_create_edit_screen.dart';
import '../../features/timetable/timetable_screen.dart';
import '../../features/timer/pomodoro_screen.dart';
import '../../features/timer/timer_history_screen.dart';
import '../../features/timer/timer_settings_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordResetFeedback,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordFeedbackScreen(email: email);
        },
      ),

      // Shell Route for Bottom Navigation Bar
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffoldScreen(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.notes,
            builder: (context, state) => const NotesListScreen(),
          ),
          GoRoute(
            path: AppRoutes.tasks,
            builder: (context, state) => const TasksListScreen(),
          ),
          GoRoute(
            path: AppRoutes.more,
            builder: (context, state) => const MoreToolsScreen(),
          ),
        ],
      ),

      // Notes Subroutes
      GoRoute(
        path: AppRoutes.createNote,
        builder: (context, state) => const NoteCreateEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.editNote,
        builder: (context, state) {
          final note = state.extra as NoteModel?;
          return NoteCreateEditScreen(noteToEdit: note);
        },
      ),
      GoRoute(
        path: AppRoutes.noteDetail,
        builder: (context, state) {
          final note = state.extra as NoteModel;
          return NoteDetailScreen(note: note);
        },
      ),

      // Tasks Subroutes
      GoRoute(
        path: AppRoutes.createTask,
        builder: (context, state) => const TaskCreateEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.editTask,
        builder: (context, state) {
          final task = state.extra as TaskModel?;
          return TaskCreateEditScreen(taskToEdit: task);
        },
      ),

      // Timetable Subroutes
      GoRoute(
        path: AppRoutes.timetable,
        builder: (context, state) => const TimetableScreen(),
      ),
      GoRoute(
        path: AppRoutes.addClass,
        builder: (context, state) => const TimetableCreateEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.editClass,
        builder: (context, state) {
          final entry = state.extra as TimetableModel?;
          return TimetableCreateEditScreen(entryToEdit: entry);
        },
      ),

      // Timer Subroutes
      GoRoute(
        path: AppRoutes.timer,
        builder: (context, state) => const PomodoroScreen(),
      ),
      GoRoute(
        path: AppRoutes.timerSettings,
        builder: (context, state) => const TimerSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.timerHistory,
        builder: (context, state) => const TimerHistoryScreen(),
      ),

      // Exams Subroutes
      GoRoute(
        path: AppRoutes.exams,
        builder: (context, state) => const ExamsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.addExam,
        builder: (context, state) => const ExamCreateEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.editExam,
        builder: (context, state) {
          final exam = state.extra as ExamModel?;
          return ExamCreateEditScreen(examToEdit: exam);
        },
      ),

      // Quiz Subroutes
      GoRoute(
        path: AppRoutes.quizCategories,
        builder: (context, state) => const QuizCategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.quizQuestions,
        builder: (context, state) => const QuizQuestionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.quizResults,
        builder: (context, state) => const QuizResultsScreen(),
      ),
      GoRoute(
        path: AppRoutes.quizReview,
        builder: (context, state) => const AnswerReviewScreen(),
      ),

      // Calculator Subroutes
      GoRoute(
        path: AppRoutes.percentageCalculator,
        builder: (context, state) => const PercentageCalculatorScreen(),
      ),
      GoRoute(
        path: AppRoutes.multiSubjectCalculator,
        builder: (context, state) => const MultiSubjectCalculatorScreen(),
      ),

      // Study Tips Subroutes
      GoRoute(
        path: AppRoutes.studyTips,
        builder: (context, state) => const StudyTipsScreen(),
      ),
      GoRoute(
        path: AppRoutes.savedTips,
        builder: (context, state) => const SavedTipsScreen(),
      ),

      // Statistics
      GoRoute(
        path: AppRoutes.studyStatistics,
        builder: (context, state) => const StudyStatisticsScreen(),
      ),

      // Profile & Settings
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.appearanceSettings,
        builder: (context, state) => const AppearanceSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.termsConditions,
        builder: (context, state) => const TermsConditionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.dataExport,
        builder: (context, state) => const DataExportScreen(),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
    ],
  );
});
