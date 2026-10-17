# Google Play Store Release Guide for StudyMate

This guide provides instructions for building, signing, and releasing StudyMate to the Google Play Console for internal testing or production release.

---

## 1. Application Identification & Requirements

- **Application ID:** `com.studymate.app`
- **Minimum SDK:** 23 (Android 6.0 Marshmallow)
- **Target SDK / Compile SDK:** 34 or higher (Android 14)
- **App Name:** StudyMate — Student Helper
- **Current Version:** `1.0.0+1` (Version name `1.0.0`, Version code `1`)
- **Package Format:** Android App Bundle (`.aab`)

---

## 2. Generating a Release Upload Keystore

Run the following command in PowerShell on Windows to create an upload key:

```powershell
keytool -genkey -v -keystore C:\Users\amans\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

> **Security Warning:**
> 1. Store `upload-keystore.jks` in a secure location outside the repository (such as your user home directory).
> 2. Make a secure offline backup of this keystore. If lost, Google Play App Signing key reset will be required.

---

## 3. Configuring Signing Credentials

Create a file named `key.properties` in `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\amans\\upload-keystore.jks
```

> **Note:** `android/key.properties` and all `*.jks`/`*.keystore` files are already excluded in `.gitignore` to prevent credential exposure.

Update `android/app/build.gradle.kts` to reference this keystore for release builds:

```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

## 4. Building the Production Android App Bundle (.aab)

Run the following build command:

```powershell
flutter build appbundle --release
```

The generated bundle will be located at:
```text
build\app\outputs\bundle\release\app-release.aab
```

---

## 5. Google Play Console Listing Checklist

### App Details
- **Title (<= 30 chars):** StudyMate — Student Helper
- **Short description (<= 80 chars):** Study planner, Pomodoro focus timer, timetable, notes, and exam countdowns.
- **Full description (<= 4000 chars):**
  StudyMate is your all-in-one academic companion designed to help students organize their studies, stay focused, and achieve higher grades.
  
  Key Features:
  • Smart Home Dashboard: Daily study streak, completion metrics, and upcoming timetable at a glance.
  • Pomodoro Study Timer: Customizable focus intervals, short/long breaks, and session analytics.
  • Notes & Categorization: Color-coded rich notes with instant search and favorites.
  • Task Manager: Categorized priorities, due date reminders, and completion tracking.
  • Weekly Timetable: Schedule classes Monday through Sunday with conflict warning.
  • Exam Countdown: Exact days and hours countdown to all upcoming examinations.
  • Computer Science MCQs & Quizzes: Real tests with in-depth answer explanations.
  • Marks & Percentage Calculators: Single and multi-subject aggregate percentage calculator.
  • Offline-First: Works seamlessly without internet connectivity.

### Graphical Assets
- **App Icon:** 512 x 512 px, 32-bit PNG with alpha channel.
- **Feature Graphic:** 1024 x 500 px, JPG or 24-bit PNG (no alpha).
- **Screenshots:** At least 2 phone screenshots (recommended 4-8), minimum 1080 x 1920 px (16:9 or 9:16 aspect ratio).

---

## 6. Play Console Data Safety Form

Refer to [`docs/PRIVACY_AND_DATA.md`](file:///c:/Users/amans/Desktop/Study%20Mate/docs/PRIVACY_AND_DATA.md) for the exact responses required in the Play Console Data Safety questionnaire.
