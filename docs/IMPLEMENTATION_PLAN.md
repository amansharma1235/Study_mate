# StudyMate — Engineering Upgrade & Redesign Implementation Plan

**Date:** 2026-10-18  
**Architecture:** Offline-First with Riverpod, SQLite, and Google Gemini Generative AI

---

## Stage 1: AI Study Tutor Engineering Upgrade (Phase 5)
- [x] Create `lib/data/remote/gemini_service.dart`:
  - Production-grade HTTP REST client calling `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`.
  - Typed request & response parsing.
  - Proper error classification: `InvalidApiKeyException`, `RateLimitException`, `NetworkException`, `QuotaExceededException`.
  - Securely loads and saves API key from `FlutterSecureStorage`.
  - Honest status indicator: Live Gemini Online vs Offline Curated Engine.
- [x] Integrate `GeminiService` into `lib/features/ai_assistant/ai_assistant_screen.dart`:
  - Real streaming/async queries with cancellation and retry on failure.
  - Quick action chips for concept explanation, note summarization, quiz generation, and code debugging.
  - Allow passing preloaded note text directly into AI Tutor for instant summarization.

## Stage 2: Notes System Upgrade & Data Integrity (Phase 4)
- [x] Enhance `NoteCreateEditScreen` (`lib/features/notes/note_create_edit_screen.dart`):
  - Add Markdown formatting toolbar: Bold (`**`), Italic (`*`), H1 (`# `), H2 (`## `), Bullet list (`- `), Task checkbox (`[ ] `), Code block (```` ``` ````).
  - Add live metrics: Word count, character count, and estimated reading time.
  - Add draft protection with `PopScope`: warns user if they have unsaved edits before discarding.
  - Add save status pill: "Saved", "Editing...", "Saving...".
- [x] Fix and enhance `NoteDetailScreen` (`lib/features/notes/note_detail_screen.dart`):
  - Fix Pin bug: do NOT pop navigation when pinning; toggle pin state reactively.
  - Add "Summarize with AI Tutor" action directly passing note content into `AiAssistantScreen`.
  - Add "Share / Copy Note" button for easy student collaboration.
  - Add word/character metrics chip header.

## Stage 3: Home Dashboard Personalization & Flow (Phase 3)
- [x] Enhance `HomeScreen` (`lib/features/home/home_screen.dart`):
  - Ensure dynamic greeting using student's actual authenticated name.
  - Add high-contrast Quick Actions row: "Ask AI Tutor" (direct 1-tap), "New Note", "Pomodoro Focus", "Flashcards Revision".
  - Refined empty states with actionable CTA buttons when no tasks or notes exist.

## Stage 4: Testing & Verification (Phases 8, 9, 10)
- [x] Add unit tests for `GeminiService` (payload serialization, error parsing).
- [x] Add unit tests for Note word counting and markdown helpers.
- [x] Run `flutter pub get`.
- [x] Run `flutter analyze` (ensure 0 issues).
- [x] Run `flutter test` (ensure all tests pass).

## Stage 5: Deliverables Documentation
- [x] Update `docs/APP_AUDIT.md`.
- [x] Create `docs/IMPLEMENTATION_PLAN.md`.
- [x] Create `docs/CHANGELOG.md`.
- [x] Create `docs/TEST_REPORT.md`.
- [x] Create `docs/SETUP.md`.
