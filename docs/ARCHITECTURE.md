# StudyMate — Architecture Documentation

## 1. Architectural Philosophy
StudyMate uses a **feature-first, offline-first architecture** with strict separation of concerns across presentation, domain models, business logic, and local/remote data sources.

```
lib/
├── app.dart                   # MaterialApp.router, Riverpod ProviderScope, and Themes
├── main.dart                  # Async initialization: storage, notifications & services
├── core/
│   ├── constants/             # Design system tokens (colors, dimensions, strings)
│   ├── errors/                # Typed domain exceptions (Auth, Database, Validation)
│   ├── routing/               # GoRouter definition, RouteNames, and ShellRoutes
│   ├── theme/                 # Light/Dark ThemeData with GoogleFonts & ThemeProvider
│   ├── utils/                 # Validators, DateFormatter, time utilities
│   └── widgets/               # Reusable UI components (AppButton, AppTextField, AppCard)
├── data/
│   ├── local/                 # AppDatabase (SQLite), PreferenceService, NotificationService
│   ├── models/                # Typed domain models (Note, Task, Timetable, Exam, Quiz, etc.)
│   ├── remote/                # FirebaseService, AuthService
│   └── repositories/          # Abstracted data access with background cloud sync
└── features/
    ├── auth/                  # Authentication controllers, login, register, reset password
    ├── calculator/            # Percentage & multi-subject marks calculators
    ├── exams/                 # Exam countdown lists, reminders, and CRUD
    ├── home/                  # Unified dashboard with streak, daily goals & timetable
    ├── navigation/            # Shell navigation scaffold with 4-tab bottom navigation
    ├── notes/                 # Notes list, categorization, search, pin, create/edit/view
    ├── onboarding/            # Splash screen & 3-step onboarding walkthrough
    ├── profile/               # Student profile view and editing
    ├── quiz/                  # Categorized MCQ quizzes, scoring, and answer review
    ├── settings/              # Tools hub, notification & appearance preferences, data export
    ├── statistics/            # Weekly study focus charts using fl_chart
    ├── study_tips/            # Curated study habits and offline saved tips
    ├── tasks/                 # Task manager with filters, priorities & reminders
    ├── timetable/             # Weekly class schedule with conflict detection
    └── timer/                 # Pomodoro focus timer with deadline-based timing
```

## 2. State Management with Riverpod
- **Declarative & Predictable**: Controllers extend `StateNotifier<T>` to manage complex interactive states (e.g., `PomodoroController`, `NotesController`, `TasksController`).
- **Reactive Derivation**: Filtered providers (`filteredNotesProvider`, `filteredTasksProvider`, `filteredTipsProvider`) reactively recompute UI presentations without mutation.
- **Dependency Injection**: Services and repositories are exposed as immutable `Provider<T>` singletons for easy mocking and testing.

## 3. Offline-First Data Synchronization
1. **Local SQLite Persistence**: Every student record is immediately committed to `studymate.db` via `sqflite`. The user never experiences network latency while taking notes, scheduling classes, or logging study sessions.
2. **Cloud Firestore Sync**: When internet connectivity and Firebase Authentication credentials are provided, updates are automatically synchronized to user-isolated Firestore collections (`/users/{uid}/*`).
3. **Optimistic Updates & SyncStatus**: Records track their sync lifecycle via `SyncStatus` (`synced`, `pendingSync`, `offlineOnly`).

## 4. Deadline-Based Timing Engine
Unlike toy timers that decrement a counter once per second (which freeze or desynchronize when the mobile OS background suspends the application), StudyMate records `targetEndTime`:
- On app pause or backgrounding: the target end time remains fixed.
- On app resume: `checkAppResumed()` calculates `difference = targetEndTime - now`. If the interval has elapsed, the session completes reliably, logs the focus minutes, and notifies the student.
- Duplicate prevention flags guarantee study statistics and streak calculations are never recorded twice.
