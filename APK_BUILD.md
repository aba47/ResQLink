# Android APK Build Guide & SDK Setup

This document provides instructions for setting up the Android SDK toolchain and building the DisasterReady APK.

---

## 1. Current Build Status

| Command | Output / Status |
| :--- | :--- |
| `flutter analyze` | **PASS (0 issues)** |
| `flutter test` | **PASS (36/36 tests)** |
| `flutter build apk --debug` | **PASS** (`build\app\outputs\flutter-apk\app-debug.apk`) |

The host development machine has:
- Flutter 3.47.5 (Dart 3.13.4) installed at `D:\flutter`.
- Java 25.0.2 installed at `C:\Program Files\Java\jdk-25` (`JAVA_HOME` set).
- Android SDK (API 34, 35, 36) & Android NDK (28.2.13676358) configured.
- Android APK compiled successfully without warnings.

---

## 2. Setting Up Android SDK on Windows

To compile the APK on this or any Windows workstation:

### Step 1: Install Android Command-Line Tools or Android Studio
- Download **Android Studio** or **Command line tools only** from [developer.android.com/studio](https://developer.android.com/studio).
- Recommended install path: `C:\Users\<username>\AppData\Local\Android\Sdk`.

### Step 2: Set Environment Variables
In Windows System Properties $\rightarrow$ Environment Variables:
1. Add `ANDROID_HOME`:
   ```
   ANDROID_HOME=C:\Users\<username>\AppData\Local\Android\Sdk
   ```
2. Add to `PATH`:
   ```
   %ANDROID_HOME%\cmdline-tools\latest\bin
   %ANDROID_HOME%\platform-tools
   ```

### Step 3: Accept Android SDK Licenses
Open PowerShell or Command Prompt:
```powershell
flutter doctor --android-licenses
```
Type `y` to accept each license.

### Step 4: Verify with Flutter Doctor
```powershell
flutter doctor
```
Ensure `[✓] Android toolchain` is green.

---

## 3. Building the APK

Once the Android SDK is configured:

### Debug APK (for testing):
```powershell
cd d:\APP\ResQLink
flutter build apk --debug
```
- **Output Location**: `build\app\outputs\flutter-apk\app-debug.apk`

### Release APK (optimized for production):
```powershell
flutter build apk --release
```
- **Output Location**: `build\app\outputs\flutter-apk\app-release.apk`

### Install on Connected Device:
```powershell
flutter install
# or
adb install -r build\app\outputs\flutter-apk\app-release.apk
```
