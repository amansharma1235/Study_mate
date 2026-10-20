# StudyMate — Local Setup & Development Guide

This guide details how to set up, configure, and run StudyMate locally on Android, iOS, or desktop platforms.

---

## 1. Prerequisites

- **Flutter SDK:** Version `3.13.5` or later (`flutter --version`)
- **Dart SDK:** Version `3.1.0` or later
- **IDE:** Android Studio or Visual Studio Code with Flutter & Dart extensions
- **Platform Tooling:**
  - **Android:** Android Studio with Android SDK API 34+ and command-line tools
  - **iOS:** Xcode (macOS only) with CocoaPods
  - **Desktop (Windows):** Visual Studio 2022 with C++ desktop development workload

---

## 2. Project Installation

1. **Clone or Open the Repository:**
   ```bash
   cd "c:\Users\amans\Desktop\Study Mate"
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Environment Health:**
   ```bash
   flutter doctor
   ```

---

## 3. Configuration & Optional Integrations

StudyMate is engineered with a **zero-configuration offline-first architecture**. It runs out-of-the-box with local SQLite (`studymate.db`) and secure local session persistence without requiring any external keys.

### 3.1 Google Gemini AI Setup (Optional for Live Generative Tutoring)
1. Get a free Google Gemini API key from [Google AI Studio](https://aistudio.google.com/).
2. Launch StudyMate on your device/emulator.
3. Open **AI Tutor** from the Home dashboard.
4. Tap the **Key Icon** in the top right AppBar.
5. Paste your API key (starting with `AIzaSy...`) and tap **Save Key**.
6. The key is stored securely in your device's hardware-encrypted keystore/keychain via `FlutterSecureStorage`.
*(Note: If no API key is entered, StudyMate automatically uses its built-in Offline Academic Knowledge Engine with curated study frameworks.)*

### 3.2 Firebase Setup (Optional for Cross-Device Cloud Sync)
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication** (Email/Password) and **Cloud Firestore**.
3. Place `google-services.json` in `android/app/` (for Android) and `GoogleService-Info.plist` in `ios/Runner/` (for iOS).
4. Run `flutterfire configure` to generate `lib/firebase_options.dart`.
*(Note: If Firebase is not configured, StudyMate gracefully runs in complete offline mode with 100% feature availability locally.)*

---

## 4. Running the Application

### Debug Mode:
```bash
flutter run
```

### Run on a specific device:
```bash
# Check connected devices
flutter devices

# Run on selected device
flutter run -d <device_id>
```

---

## 5. Running Automated Tests & Quality Checks

### Run Static Analysis:
```bash
flutter analyze
```

### Run Full Test Suite:
```bash
flutter test
```

---

## 6. Building Production Release Bundles

### Build Release APK:
```bash
flutter build apk --release
```
*Output location:* `build/app/outputs/flutter-apk/app-release.apk`

### Build Android App Bundle (for Google Play Store):
```bash
flutter build appbundle --release
```
*Output location:* `build/app/outputs/bundle/release/app-release.aab`
