# StudyMate — Student Helper App

[![Flutter](https://img.shields.io/badge/Flutter-3.47.7-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.13.5-teal.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)]()

> **Tagline:** *Study. Plan. Achieve.*  
> **Package ID:** `com.studymate.app`  
> **Target OS:** Android-first (Compatible with iOS & Web)

---

## 📖 About StudyMate

**StudyMate** is a comprehensive, production-grade Android application crafted for students. Built with Flutter, Riverpod, SQLite, and Firebase, it combines academic organization with focus tools to maximize learning productivity.

---

## ✨ Key Features & Screen Inventory (40 Screens)

1. **Brand & Onboarding:**
   - Animated Splash Screen with auto-navigation.
   - 3-step interactive onboarding with smooth page indicators.
2. **Authentication & Security:**
   - Email/password registration, login, and password visibility toggle.
   - Password reset flow with actionable feedback screen.
   - Email verification check with simulated test bypass.
   - Secure account deletion with re-authentication safeguards.
3. **Smart Home Dashboard:**
   - Dynamic personalized greeting & date display.
   - Daily study streak counter & daily study goal progress bar.
   - Weekly study hours chart (`fl_chart` bar chart).
   - Today's tasks completion progress.
   - Upcoming classes with real-time next-class indicator.
   - Nearest upcoming exams countdown widget.
   - Recently modified notes carousel.
   - Quick tool access grid.
4. **Notes Management:**
   - Full CRUD operations with color categories and tags.
   - Real-time search across title and body.
   - Pin / favorite notes support.
   - Offline persistence via SQLite.
5. **Task & Assignment Manager:**
   - Priority tagging (Low, Medium, High).
   - Due date and time pickers.
   - Filter tabs: All, Today, Upcoming, and Completed.
   - Completion toggle directly updating dashboard metrics.
6. **Weekly Timetable:**
   - Monday to Sunday day-by-day scheduler.
   - Subject, room number, instructor, and time range.
   - Schedule conflict detection before saving.
7. **Production Pomodoro Timer:**
   - Deadline-based timing logic (accurate across backgrounding and device sleep).
   - Focus (25m), Short Break (5m), Long Break (15m) modes.
   - Custom interval settings in preferences.
   - Session history logging with subject breakdown.
   - Circular countdown progress ring.
8. **Exam Countdown:**
   - Days, hours, and minutes remaining countdown.
   - Nearest exam sorting.
   - Categorization by subject.
9. **MCQ & Quiz System:**
   - Computer Science topics (Data Structures, Algorithms, OS, Networking).
   - 4-choice questions with real-time answer selection.
   - Instant score calculation, results summary, and detailed review with explanations.
10. **Calculators & Academic Utilities:**
    - Single-subject percentage calculator with division-by-zero protection.
    - Multi-subject aggregate marks & percentage calculator.
    - Clipboard copy and export for calculation results.
11. **Study Tips & Habits:**
    - 8 curated scientific study techniques (Pomodoro, Feynman, Active Recall, Leitner).
    - Offline JSON data bundling with bookmarking/favorite capability.
12. **Analytics, Profile & Settings:**
    - Study statistics with focus distribution.
    - User profile editing.
    - Dark mode, light mode, and system theme switching.
    - One-click JSON data export.
    - Full privacy policy and terms of service viewers.

---

## 🎨 Design System

- **Primary Accent:** `#6258E8` (Electric Indigo)
- **Secondary Accent:** `#3987F5` (Vibrant Azure)
- **Light Background:** `#F7F7FC`
- **Dark Background:** `#111327`
- **Typography:**
  - Headings: `GoogleFonts.outfit()`
  - Body & UI: `GoogleFonts.inter()`
- **Components:** Reusable `AppButton`, `AppTextField`, `AppCard`, `EmptyState`, `LoadingSkeleton`, `AppDialogs`.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.47.0`
- Dart SDK `^3.13.0`
- Android Studio / VS Code with Flutter extension
- Android SDK 34+

### Installation & Execution

1. **Clone or open the workspace:**
   ```powershell
   cd "C:\Users\amans\Desktop\Study Mate"
   ```

2. **Install dependencies:**
   ```powershell
   flutter pub get
   ```

3. **Run automated test suite:**
   ```powershell
   flutter test
   ```

4. **Run static code analysis:**
   ```powershell
   flutter analyze
   ```

5. **Launch on an Android device or emulator:**
   ```powershell
   flutter run
   ```

---

## 📦 Building for Release

### Android APK (Debug / Test Build)
```powershell
flutter build apk --debug
```

### Production Android App Bundle (.aab)
```powershell
flutter build appbundle --release
```
See [`docs/PLAY_STORE_RELEASE.md`](file:///c:/Users/amans/Desktop/Study%20Mate/docs/PLAY_STORE_RELEASE.md) for signing and Play Console upload steps.

---

## 📚 Project Documentation

- [Architecture Overview](file:///c:/Users/amans/Desktop/Study%20Mate/docs/ARCHITECTURE.md)
- [Firebase Setup Guide](file:///c:/Users/amans/Desktop/Study%20Mate/docs/FIREBASE_SETUP.md)
- [Testing & Quality Assurance](file:///c:/Users/amans/Desktop/Study%20Mate/docs/TESTING.md)
- [Google Play Store Release Checklist](file:///c:/Users/amans/Desktop/Study%20Mate/docs/PLAY_STORE_RELEASE.md)
- [Privacy Policy & Data Safety Form](file:///c:/Users/amans/Desktop/Study%20Mate/docs/PRIVACY_AND_DATA.md)

---

## 🛡️ Security & Privacy

- Strict UID-isolated Cloud Firestore rules configured in [`firestore.rules`](file:///c:/Users/amans/Desktop/Study%20Mate/firestore.rules).
- Offline-first SQLite database with user-isolated records.
- Zero tracking or advertising SDKs.
