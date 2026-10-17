# StudyMate Testing Strategy and Results

StudyMate includes automated unit and widget test suites covering state management, offline database models, calculations, and Pomodoro deadline timing logic.

---

## 1. Test Architecture

The tests are organized under the [`test/`](file:///c:/Users/amans/Desktop/Study%20Mate/test) directory:

| Test File | Target Under Test | Coverage Focus |
|:---|:---|:---|
| [`test/unit/calculator_test.dart`](file:///c:/Users/amans/Desktop/Study%20Mate/test/unit/calculator_test.dart) | Single & Multi-Subject Calculation | Division by zero prevention, percentage accuracy, multi-subject totals, weighted percentages. |
| [`test/unit/pomodoro_test.dart`](file:///c:/Users/amans/Desktop/Study%20Mate/test/unit/pomodoro_test.dart) | Deadline-based Timer Logic | Pause duration calculation, remaining seconds, background elapsed time resumption. |
| [`test/unit/models_test.dart`](file:///c:/Users/amans/Desktop/Study%20Mate/test/unit/models_test.dart) | Data Layer Serialization | `NoteModel`, `TaskModel`, `ExamModel` JSON and SQLite map serialization, roundtrip fidelity. |
| [`test/widget/onboarding_test.dart`](file:///c:/Users/amans/Desktop/Study%20Mate/test/widget/onboarding_test.dart) | UI & Riverpod Interaction | Onboarding screen rendering, slide transitions, Skip button, Get Started button. |

---

## 2. Running Automated Tests

To execute all tests from PowerShell or Command Prompt in the workspace root:

```powershell
flutter test
```

### Detailed Verbose Output:
```powershell
flutter test -v
```

### Running Specific Test Suites:
```powershell
flutter test test/unit/calculator_test.dart
flutter test test/unit/pomodoro_test.dart
flutter test test/unit/models_test.dart
flutter test test/widget/onboarding_test.dart
```

---

## 3. Actual Test Results

Executed via Flutter Toolchain (Flutter 3.47.7, Dart 3.13.5):

```text
00:00 +0: loading test\unit\calculator_test.dart
00:01 +4: Percentage Calculator Tests (4 tests passed)
00:01 +8: Multi-Subject Marks Calculator Tests (4 tests passed)
00:02 +11: Pomodoro deadline and duration calculation tests (3 tests passed)
00:02 +15: Data Models Serialization & Mapping Tests (4 tests passed)
00:04 +16: Onboarding Screen Widget Tests (1 test passed)
00:04 +16: All tests passed!
```

**Status:** 16 / 16 Passed (100% Pass Rate). 0 Failures, 0 Skips.

---

## 4. Manual QA Test Journeys

The following manual test scripts can be run directly on an Android device or emulator:

### Journey 1: Authentication & User Session
1. Launch app -> Splash screen loads -> Redirects to Onboarding.
2. Swipe through all 3 onboarding slides -> Tap "Get Started" -> Lands on Login.
3. Tap "Sign Up" -> Enter Name, Email, Password, Confirm Password -> Tap "Create Account".
4. Shows Email Verification notification -> Tap "Simulate / Verify Now" -> Lands on Home Dashboard with personalized greeting.

### Journey 2: Notes Management & Search
1. Open "Notes" from Bottom Navigation.
2. Tap floating "+" button -> Enter Title: "Data Structures", Category: "Computer Science", Content: "Trees, Graphs, and Heaps".
3. Tap Pin icon -> Save note.
4. Verify note appears pinned with indicator.
5. In search bar, type "Graphs" -> Verify note filters instantly.
6. Tap note -> Edit content -> Verify updated timestamp.
7. Tap delete -> Confirm deletion dialog.

### Journey 3: Pomodoro Study Session
1. Navigate to "More" -> "Pomodoro Timer".
2. Select subject (e.g., "Math").
3. Tap "Start" -> Circular countdown animates smoothly.
4. Press home button to background the app for 10 seconds.
5. Re-open app -> Timer accurately accounts for elapsed background seconds.
6. Tap "Skip" or finish countdown -> Prompt to record completed study session.
7. Check "Timer History" & "Study Statistics" -> Focus minutes increase accordingly.

### Journey 4: Marks & Percentage Calculation
1. Open "More" -> "Marks Calculator".
2. Switch to "Multi-Subject" tab.
3. Add subjects: Math (85/100), Physics (90/100), Chemistry (75/100).
4. Verify dynamic calculation: Total 250/300, 83.33%.
5. Tap "Copy Result" -> Toast indicates text copied to clipboard.

### Journey 5: Theme & Appearance
1. Open "More" -> "Appearance".
2. Select "Dark Mode" -> Theme changes immediately with smooth contrast transition.
3. Select "Light Mode" or "System Default" -> Re-renders seamlessly without flickering.
4. Kill and restart app -> Selected theme preference persists.
