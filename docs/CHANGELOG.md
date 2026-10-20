# StudyMate — Changelog & Engineering Upgrade Record

## [Version 2.0.0] - 2026-10-18

### 🌟 AI Study Tutor (Google Gemini Generative AI)
- **Added:** `lib/data/remote/gemini_service.dart` providing direct, production-grade REST communication with Google Gemini 1.5 Flash (`generativelanguage.googleapis.com`).
- **Added:** Robust error classification for Gemini queries (`InvalidApiKeyException`, `RateLimitException`, `NetworkException`, `ServerException`).
- **Added:** Secure API Key management stored in hardware-encrypted keystore/keychain via `FlutterSecureStorage`.
- **Added:** Direct Note-to-AI Summarizer bridge allowing students to 1-tap transfer lecture notes into the AI Tutor for instant extraction of high-yield study points.
- **Added:** Mode selector chips for Concept Explainer, Notes Summarizer, Quiz Generator, Code Debugger, and Spaced-Repetition Revision Strategy.
- **Added:** Direct "Save Note" action button on every AI response allowing students to 1-tap save explanations and summaries straight into their local notebook with prefilled title and markdown.
- **Added:** Direct "Save Flashcard" modal dialog bridge with prefilled question & answer, deck selection (auto-creating an "AI Study Deck" if needed), and instant insertion into SQLite for spaced-repetition revision.
- **Added:** Copy response to clipboard functionality with instant feedback.
- **Improved:** Clear, honest status indicator in AppBar distinguishing between `● Gemini 1.5 Flash Online` and `⚡ Offline Academic Engine`.

### 📝 Notes System & Rich Markdown Editor
- **Added:** Rich text & Markdown toolbar in `NoteCreateEditScreen` for Bold (`**`), Italic (`*`), H1 (`#`), H2 (`##`), Bullet Lists (`•`), Task Checklists (`- [ ]`), Code Snippets (`` ` ``), and Blockquotes (`>`).
- **Added:** Live note statistics header computing real-time word count, character count, and estimated reading time.
- **Added:** Unsaved changes protection via `PopScope` to prevent accidental data loss when navigating away.
- **Added:** Real-time note save status indicator (`Saved`, `Unsaved Edits`, `Saving...`).
- **Added:** In-editor pin toggle to pin important notes directly during drafting.
- **Fixed:** `NoteDetailScreen` pin toggle bug where toggling the pin previously executed `context.pop()`. Pin state now updates reactively without disrupting reading.
- **Added:** Note Details copy-to-clipboard button and direct "Study with AI Tutor" callout card.

### 🏠 Home Dashboard
- **Improved:** Featured "AI Tutor" and "Flashcards" directly in the primary 8-tool Quick Tools grid.
- **Improved:** Maintained dynamic greeting, real study streak from session history, live daily focus progress, and upcoming exams.
- **Enhanced:** Actionable empty states prompting student action when 0 notes or 0 tasks exist.

### 🛡️ Layout & Rendering Overflows
- **Fixed:** Overflows across 13 core files:
  - `lib/core/widgets/app_button.dart`: Button labels wrapped in `Flexible` with `TextOverflow.ellipsis`.
  - `lib/features/auth/forgot_password_screen.dart`: Wrapped in `SingleChildScrollView` to prevent keyboard bottom overflow.
  - `lib/features/auth/reset_password_feedback_screen.dart`: Wrapped in `SingleChildScrollView` for small/landscape screens.
  - `lib/features/groups/study_groups_screen.dart`: Wrapped bottom card member and notes count in responsive `Wrap`.
  - `lib/features/career/career_screen.dart`: Wrapped company names, resume headers, and stipend details in `Expanded` and `Wrap`.
  - `lib/features/coding/coding_screen.dart`: Wrapped roadmap titles and exercises in `Expanded`.
  - `lib/features/home/home_screen.dart`: Wrapped section titles in `Expanded` and adjusted grid aspect ratio.
  - `lib/features/tasks/tasks_list_screen.dart`: Constrained long subject titles with `Expanded`.
  - `lib/features/syllabus/syllabus_screen.dart`: Converted mini-stats to `Wrap` and topic chapter tag to `Flexible`.
  - `lib/features/flashcards/flashcard_review_screen.dart`: Wrapped front and back question/answer text in `Expanded` + `SingleChildScrollView` to eliminate vertical card clipping.
  - `lib/features/onboarding/onboarding_screen.dart`: Wrapped slides in `ConstrainedBox` + `SingleChildScrollView`.
  - `lib/features/ai_assistant/ai_assistant_screen.dart`: Wrapped dialog content in `SingleChildScrollView`.
  - `lib/features/quiz/quiz_categories_screen.dart`: Constrained category titles with `Expanded`.

### 🧪 Test Suite & Verification
- **Added:** `test/unit/gemini_service_and_note_test.dart` validating Gemini key validation, response parsing, word counting algorithms, and model copyWith integrity.
- **Result:** 37 / 37 unit and widget tests passing with 0 failures.
- **Static Analysis:** `flutter analyze` passing with 0 warnings and 0 errors.
