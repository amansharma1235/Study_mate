class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String passwordResetFeedback = '/password-reset-feedback';

  // Shell Tabs
  static const String home = '/home';
  static const String notes = '/notes';
  static const String tasks = '/tasks';
  static const String more = '/more';

  // Notes
  static const String createNote = '/notes/create';
  static const String noteDetail = '/notes/detail';
  static const String editNote = '/notes/edit';

  // Tasks
  static const String createTask = '/tasks/create';
  static const String editTask = '/tasks/edit';

  // Timetable
  static const String timetable = '/timetable';
  static const String addClass = '/timetable/add';
  static const String editClass = '/timetable/edit';

  // Timer
  static const String timer = '/timer';
  static const String timerSettings = '/timer/settings';
  static const String timerHistory = '/timer/history';

  // Exams
  static const String exams = '/exams';
  static const String addExam = '/exams/add';
  static const String editExam = '/exams/edit';

  // Quiz
  static const String quizCategories = '/quiz';
  static const String quizQuestions = '/quiz/play';
  static const String quizResults = '/quiz/results';
  static const String quizReview = '/quiz/review';

  // Calculator
  static const String percentageCalculator = '/calculator/percentage';
  static const String multiSubjectCalculator = '/calculator/multi-subject';
  static const String cgpaCalculator = '/calculator/cgpa';

  // Smart Study Planner
  static const String planner = '/planner';
  static const String createPlan = '/planner/create';

  // Flashcards & Spaced Repetition
  static const String flashcards = '/flashcards';
  static const String flashcardsReview = '/flashcards/review';
  static const String createDeck = '/flashcards/create-deck';

  // Syllabus & Revision Tracker
  static const String syllabus = '/syllabus';
  static const String addSyllabusTopic = '/syllabus/add';

  // AI Study Assistant
  static const String aiAssistant = '/ai-assistant';

  // Documents & PDF Tools
  static const String documents = '/documents';

  // Voice Notes
  static const String voiceNotes = '/voice-notes';

  // Habits & Productivity
  static const String habits = '/habits';
  static const String createHabit = '/habits/create';

  // Coding Practice Center
  static const String coding = '/coding';
  static const String codingRoadmap = '/coding/roadmap';

  // Career Center
  static const String career = '/career';
  static const String resumeBuilder = '/career/resume';
  static const String jobTracker = '/career/jobs';

  // Study Groups & Collaborative Sharing
  static const String studyGroups = '/groups';

  // Study Tips
  static const String studyTips = '/study-tips';
  static const String savedTips = '/study-tips/saved';

  // Statistics
  static const String studyStatistics = '/statistics';

  // Profile & Settings
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String notificationSettings = '/settings/notifications';
  static const String appearanceSettings = '/settings/appearance';
  static const String privacyPolicy = '/settings/privacy-policy';
  static const String termsConditions = '/settings/terms-conditions';
  static const String helpSupport = '/settings/help-support';
  static const String about = '/settings/about';
  static const String dataExport = '/settings/data-export';
  static const String deleteAccount = '/settings/delete-account';
}
