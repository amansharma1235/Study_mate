# Privacy Policy & Google Play Data Safety Declaration

*Last Updated: October 2026*

This document provides both the user-facing Privacy Policy and the exact responses required for the Google Play Console Data Safety section for **StudyMate — Student Helper App** (`com.studymate.app`).

---

## 1. Google Play Console Data Safety Declaration

### Data Collection & Purpose Summary

| Data Category | Data Type | Collected? | Shared with Third Parties? | Purpose | Ephemeral or Stored? |
|:---|:---|:---|:---|:---|:---|
| **Personal Info** | Name | Yes (Optional) | No | Account functionality, personalization | Stored in Firestore / SQLite |
| **Personal Info** | Email address | Yes | No | Authentication, account management, password reset | Stored in Firebase Auth / Firestore |
| **App Activity** | In-app study actions | Yes (Anonymous) | No | Study statistics, focus minutes, Pomodoro history | Stored locally (SQLite) & synced to Firestore |
| **User Content** | Notes, Tasks, Exams, Timetable | Yes | No | Core app functionality | Stored locally (SQLite) & synced to Firestore |
| **Device or other IDs** | Push Notification token | Yes (If notifications allowed) | No | Delivering local & push reminders | Managed by Firebase / OS |

### Security Practices
- **Data Encrypted in Transit:** Yes. All data sent to Firebase is encrypted using modern TLS (HTTPS).
- **Data Encrypted at Rest:** Yes. Android sandbox local database encryption and Google Cloud AES-256 at rest.
- **Data Deletion Mechanism:** Yes. Users can request account and data deletion directly inside the app (`More` -> `Settings` -> `Delete Account`).

---

## 2. StudyMate Privacy Policy (Draft for Publication)

### Overview
StudyMate ("we", "our", or "the app") provides a digital study companion designed to help students organize their academic lives. We respect your privacy and are committed to safeguarding the personal data you share with us.

### Information We Collect
1. **Account Information:** When you create an account, we collect your email address and display name for identification and authentication.
2. **Academic Data:** You may choose to store notes, task lists, timetable entries, examination dates, and study timer logs. This data is private to your account and is never shared, sold, or used for advertising.
3. **Local Storage:** All academic entries are stored locally on your device in a private SQLite database and synchronized with your authenticated Firebase account when connected.

### Permissions Used
- **POST_NOTIFICATIONS / VIBRATE:** Used to alert you when a study timer completes or when an exam or task deadline approaches.
- **SCHEDULE_EXACT_ALARM:** Used to trigger precise study timers and timetable notifications.
- **INTERNET:** Used solely for cloud backup and user authentication.

### Data Retention & Deletion
You retain complete ownership of your data:
- **Export Data:** You can export all your notes, tasks, exams, and timetable entries to JSON at any time from within the app.
- **Delete Account:** When you request account deletion from inside the app, your local database is completely wiped and your remote Firebase records are purged immediately.

### Contact & Inquiries
For privacy questions, support, or bug reports, contact:
- **Developer / Support Email:** `support@studymate.app`
- **Application:** StudyMate — Student Helper App (`com.studymate.app`)
