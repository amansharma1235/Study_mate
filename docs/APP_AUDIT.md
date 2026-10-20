# StudyMate — Comprehensive Application Audit

**Date:** 2026-10-18  
**Auditor:** Senior Mobile Architect & QA Engineer  
**Project:** StudyMate (Flutter / Dart Mobile Application)  
**Status:** In Progress (Engineering Upgrade & Quality Hardening)

---

## 1. Project Structure & Environment Overview

- **SDK & Framework:** Flutter (Dart SDK `^3.13.5`)
- **State Management:** `flutter_riverpod: ^2.6.1`
- **Routing:** `go_router: ^18.1.0` (Declarative with `ShellRoute` bottom navigation)
- **Primary Database:** Local SQLite `sqflite: ^2.4.4+2` (`studymate.db`)
- **Cloud Backend:** Optional Firebase (`firebase_core: ^5.0.0`, `firebase_auth: ^7.0.0`, `cloud_firestore: ^7.0.0`)
- **Secure Storage:** `flutter_secure_storage: ^9.2.2` (Hardware-backed keystore/keychain for tokens and API keys)
- **Local Notifications:** `flutter_local_notifications: ^22.3.2`
- **Current Test Status:** 33 / 33 Unit & Widget Tests Passing (`flutter test`)
- **Static Analysis:** 0 errors, 0 warnings (`flutter analyze`)

---

## 2. Executive Summary of Audit Findings

| Category | Finding Description | Severity | Impact |
| :--- | :--- | :---: | :--- |
| **AI Study Tutor** | `AiAssistantScreen` used hardcoded string templates instead of connecting to a real Google Gemini API client even when user API keys were supplied. | **HIGH** | The AI assistant felt simulated rather than an authentic generative learning tutor. |
| **Notes Editor** | Lacks Markdown formatting bar (Bold, Italic, Headings, Bullet Lists, Checklists), autosave indicators, live word count, and draft exit protection. | **HIGH** | Note-taking experience felt basic and students risked losing long lecture notes if navigating away accidentally. |
| **Note Details UX** | Toggling the "Pin" icon in `NoteDetailScreen` executed `context.pop()`, forcing the user out of the screen. | **MEDIUM** | Disruptive navigation bug when organizing notes. |
| **Note & AI Synergy** | No bridge between saved notes and the AI tutor (unable to 1-tap summarize note, generate flashcards, or create MCQs from a note). | **HIGH** | Disconnected core value proposition of an AI-powered student productivity app. |
| **Home Dashboard** | While dynamic, dashboard lacked direct 1-tap shortcuts for "Ask AI Tutor" and "Quick Note", and empty states for new accounts needed clearer CTAs. | **MEDIUM** | New students faced underutilized dashboard cards before data was populated. |
| **Layout Overflows** | RenderFlex overflows across 13 files (dialogs, buttons, small screens) — *Resolved in Step 1*. | **RESOLVED** | App now runs without yellow-and-black RenderFlex stripes across all screen densities. |
| **Notification Integration** | NotificationService initializes correctly, but scheduled reminders for task due dates and exam countdowns needed hardening. | **MEDIUM** | Reminders must trigger at the designated local time without crashing. |

---

## 3. Detailed Component Audit

### 3.1 Authentication & Security (`lib/data/remote/auth_service.dart`)
- **Strengths:** Robust offline-first fallback. If Firebase native credentials are absent or the device is offline, a secure local session is saved in `FlutterSecureStorage`.
- **Integrity:** Passwords are never stored in plaintext. No private production secrets or API keys are committed to Git.
- **Improvements Needed:** Ensure profile updates reactively invalidate providers across both home and profile screens.

### 3.2 Notes Architecture (`lib/features/notes/`)
- **Storage:** Stored in SQLite table `notes` with columns: `id`, `userId`, `title`, `content`, `category`, `isPinned`, `createdAt`, `updatedAt`, `syncStatus`.
- **Weaknesses Identified:**
  1. No rich text / markdown formatting toolbar in `NoteCreateEditScreen`.
  2. No live word count / character count / reading time metric.
  3. No autosave indicator (`Saved`, `Saving...`, `Unsaved changes`).
  4. No dirty-state protection when tapping back.
  5. In `note_detail_screen.dart`, pin button executed `context.pop()`.
  6. Missing "Summarize with AI" and "Export / Share Note" actions.

### 3.3 AI Study Tutor (`lib/features/ai_assistant/`)
- **Current State:** Stores user API key in `FlutterSecureStorage` under `user_gemini_api_key`.
- **Flaws Identified:**
  1. `_sendMessage()` called `_generateEducationalResponse()` (static hardcoded switch-case) instead of executing a live Google Gemini REST API request (`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`).
  2. Lacks retry mechanism, network error handling, rate-limit indicators, or offline notice.
  3. Lacks direct feature to export AI-generated questions into the real Flashcard or Quiz database.

### 3.4 Home Dashboard (`lib/features/home/`)
- **Current State:** Dynamic through `homeDashboardProvider`. Displays real user greeting, real study streak, daily goal progress, upcoming exams, today's timetable, and recent notes.
- **Improvements Needed:**
  1. Add direct 1-tap "Ask AI Tutor" and "New Note" action cards.
  2. Improve empty states when a student has 0 tasks or 0 notes.
  3. Add active revision shortcut to jump directly into due flashcards.

### 3.5 Database & Repositories (`lib/data/local/app_database.dart`)
- **Strengths:** Fully typed schemas for 15+ models (`notes`, `tasks`, `timetable`, `exams`, `flashcards`, `habits`, `documents`, `job_applications`, `study_groups`).
- **Data Isolation:** Every table scopes records by `userId` to prevent data leakage between student accounts.

---

## 4. Priority Roadmap

1. **Priority 1 (P0): Real AI Service Engine**
   - Create a clean, production-grade Gemini API client service (`lib/data/remote/gemini_service.dart`).
   - Call live Google Gemini 1.5 Flash when API key is present.
   - Provide clear, honest offline educational engine fallback with honest status indicators when no key is entered (never simulate fake network success).
   - Add prompt templates for Concept Explanations, Note Summarization, Flashcard Generation, and Code Debugging.

2. **Priority 2 (P0): Complete Notes System Upgrade**
   - Add Markdown / Rich Formatting Toolbar to `NoteCreateEditScreen` (Bold, Italic, Bullet Lists, Checklists, Headings, Code block).
   - Add live word count & reading time chips.
   - Add autosave / save status indicator.
   - Add dirty-check warning on exit (`PopScope` / `WillPopScope`).
   - Fix `NoteDetailScreen` pin toggle bug (remove unwanted `context.pop()`).
   - Add "Summarize with AI" action from Note Details directly into the AI tutor.

3. **Priority 3 (P1): Home Dashboard Polish**
   - Add polished quick-action buttons for "Ask AI Tutor", "Take Notes", "Flashcard Revision".
   - Enhance empty states with 1-tap creation prompts.

4. **Priority 4 (P1): Documentation & Test Suite Expansion**
   - Write comprehensive unit tests for the Gemini service and Note formatting logic.
   - Complete `docs/IMPLEMENTATION_PLAN.md`, `docs/CHANGELOG.md`, `docs/TEST_REPORT.md`, and `docs/SETUP.md`.
