# Firebase Setup Guide for StudyMate

StudyMate is built with an **Offline-First, Graceful Fallback Architecture**. The application runs completely without an active Firebase project using encrypted local SQLite storage and local authentication simulation. However, to enable multi-device cloud synchronization, real-time cloud backups, and Firebase Authentication, follow this setup guide.

---

## 1. Create a Firebase Project

1. Navigate to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** (or **Create a project**).
3. Name your project (e.g., `studymate-app`).
4. (Optional) Choose whether to enable Google Analytics.
5. Click **Create project** and wait for provisioning to complete.

---

## 2. Register Android Application

1. In your Firebase Project Overview page, click the **Android** icon to add an Android app.
2. Enter the exact Android package name configured in StudyMate:
   ```text
   com.studymate.app
   ```
3. Set the App nickname (e.g., `StudyMate Android`).
4. **Debug signing certificate SHA-1**:
   To obtain your local debug SHA-1 fingerprint on Windows PowerShell:
   ```powershell
   cd android
   ./gradlew signingReport
   ```
   Locate `Variant: debug` -> `SHA1` (e.g. `XX:XX:XX:...`) and paste it into Firebase.
5. Click **Register app**.

---

## 3. Download and Install `google-services.json`

1. Download `google-services.json` from the Firebase Console registration step.
2. Place the file directly in the `android/app/` directory:
   ```text
   Study Mate/
   └── android/
       └── app/
           ├── build.gradle.kts
           └── google-services.json   <-- PLACE HERE
   ```

*(Note: `.gitignore` is already pre-configured to keep `google-services.json` safe from being accidentally committed into version control).*

---

## 4. Enable Authentication Providers

1. In the Firebase Console sidebar, go to **Build** > **Authentication**.
2. Click **Get Started**.
3. In the **Sign-in method** tab:
   - **Email/Password**: Click Edit, toggle **Enable**, and click **Save**.
   - **Google** (Optional): Click Edit, toggle **Enable**, choose your project support email, and save.

---

## 5. Enable Cloud Firestore Database

1. In the Firebase Console sidebar, go to **Build** > **Firestore Database**.
2. Click **Create database**.
3. Select your Database ID (use `(default)`).
4. Choose a Cloud Firestore location closest to your users (e.g., `asia-south1` or `us-central1`).
5. Choose **Start in production mode** (or test mode).
6. Click **Create**.

---

## 6. Deploy Security Rules

StudyMate includes strict, production-ready Firestore Security Rules defined in [`firestore.rules`](file:///c:/Users/amans/Desktop/Study%20Mate/firestore.rules).
Every user document is restricted so that users can only read and write their own data.

### Option A: Via Firebase CLI (Recommended)
```bash
# Install Firebase Tools globally if not installed
npm install -g firebase-tools

# Login to your Google account
firebase login

# Initialize or link project
firebase use --add

# Deploy security rules
firebase deploy --only firestore:rules
```

### Option B: Copy-Paste via Firebase Console
1. In the Firebase Console, go to **Firestore Database** > **Rules** tab.
2. Replace the contents of the editor with the contents of [`firestore.rules`](file:///c:/Users/amans/Desktop/Study%20Mate/firestore.rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```
3. Click **Publish**.

---

## 7. Enabling Firebase in Flutter

In [`lib/data/remote/firebase_service.dart`](file:///c:/Users/amans/Desktop/Study%20Mate/lib/data/remote/firebase_service.dart):
- By default, `FirebaseService` safely catches if Firebase isn't initialized and uses SQLite local storage.
- Once `google-services.json` is placed, uncomment the FlutterFire initialization in `main.dart`:
```dart
// await Firebase.initializeApp(
//   options: DefaultFirebaseOptions.currentPlatform,
// );
```
- Flutter will now seamlessly connect to your live Firebase backend!
