# Flutter Project Setup Guide

## Prerequisites

Before running this Flutter project, make sure the following tools are installed.

### 1. Flutter SDK

**Windows:**

```powershell
# Download Flutter: https://docs.flutter.dev/get-started/install/windows
# Extract to C:\src\flutter (or your preferred location)
# Add Flutter to PATH (new terminals only)
setx PATH "%PATH%;C:\src\flutter\bin"
```

**Verify installation:**

```powershell
flutter doctor
```

### 2. Android Studio (for Android development)

1. Download: <https://developer.android.com/studio>
2. Install Android Studio
3. Open **Android Studio → Tools → SDK Manager**
4. Install:
   - Android SDK Platform (API 33 or higher)
   - Android SDK Build-Tools
   - Android Emulator
5. Accept Android licenses:

```powershell
flutter doctor --android-licenses
```

### 3. VS Code (recommended IDE)

1. Download: <https://code.visualstudio.com/>
2. Install the **Flutter** extension
3. Install the **Dart** extension

## Project Setup

> **Command convention:** Use `./tool/flutterw.ps1` as the canonical way to run Flutter commands in this repo. Direct `flutter` usage is optional only when Flutter is already available on your PATH.

### 1. Navigate to the project directory

```powershell
cd C:\Users\H\Steps-to-recovery-flutter
```

### 2. Get dependencies

```powershell
./tool/flutterw.ps1 pub get
```

### 3. Run the app

```powershell
# Run on connected device or emulator
./tool/flutterw.ps1 run

# Debug mode
./tool/flutterw.ps1 run --debug

# Release mode (for production-like testing)
./tool/flutterw.ps1 run --release
```

## Build Outputs

### Debug APK

```powershell
./tool/flutterw.ps1 build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK

```powershell
./tool/flutterw.ps1 build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Split APKs (smaller APKs per ABI)

```powershell
./tool/flutterw.ps1 build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/` (multiple ABI-specific APK files)

### Android App Bundle (Play Store upload)

```powershell
./tool/flutterw.ps1 build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Run on Different Platforms

### Android

```powershell
./tool/flutterw.ps1 run -d android
```

### iOS (macOS only)

```powershell
./tool/flutterw.ps1 run -d ios
```

### Web

```powershell
./tool/flutterw.ps1 run -d chrome
```

### Windows

```powershell
./tool/flutterw.ps1 run -d windows
```

## Common Issues & Solutions

### Issue: No devices found

**Solution:**

- Connect an Android device via USB and enable USB debugging
- Or start an Android emulator from Android Studio

### Issue: Gradle build failed

**Solution (macOS/Linux):**

```powershell
cd android
./gradlew clean
cd ..
./tool/flutterw.ps1 clean
./tool/flutterw.ps1 pub get
./tool/flutterw.ps1 run
```

**Solution (Windows):**

```powershell
cd android
gradlew.bat clean
cd ..
./tool/flutterw.ps1 clean
./tool/flutterw.ps1 pub get
./tool/flutterw.ps1 run
```

### Issue: Package conflicts

**Solution:**

```powershell
./tool/flutterw.ps1 clean
./tool/flutterw.ps1 pub get
```

### Issue: Android licenses not accepted

**Solution:**

```bash
flutter doctor --android-licenses
```

## Development Tips

### Hot Reload

Press `r` in the terminal while the app is running.

### Hot Restart

Press `R` in the terminal.

### Toggle debug paint / console overlay

Press `p` in the terminal.

### Quit app

Press `q` in the terminal.

## Project Structure

```text
lib/
├── core/                   # Core functionality
│   ├── constants/          # App constants and step prompts
│   ├── models/             # Data models
│   ├── services/           # Services (DB, encryption, etc.)
│   ├── theme/              # Design system
│   └── utils/              # Utility functions
├── features/               # Feature modules
│   ├── ai_companion/       # AI chat
│   ├── auth/               # Login/signup
│   ├── challenges/         # Recovery challenges
│   ├── craving_surf/       # Craving management
│   ├── crisis/             # Emergency features
│   ├── emergency/          # Danger zone
│   ├── gratitude/          # Gratitude journal
│   ├── home/               # Home dashboard
│   ├── inventory/          # Step 10 inventory
│   ├── journal/            # Journal feature
│   ├── meetings/           # Meeting finder
│   ├── onboarding/         # Onboarding flow
│   ├── profile/            # User profile
│   ├── progress/           # Progress tracking
│   ├── readings/           # Daily readings
│   ├── safety_plan/        # Safety plan
│   ├── sponsor/            # Sponsor management
│   └── steps/              # 12-step work
├── navigation/             # Routing
├── widgets/                # Reusable widgets
└── main.dart               # App entry point
```

## Testing

### Run all tests

```powershell
./tool/flutterw.ps1 test
```

### Run a specific test file

```powershell
./tool/flutterw.ps1 test test/my_test.dart
```

### Run with coverage

```powershell
./tool/flutterw.ps1 test --coverage
```

## Static Analysis

```powershell
./tool/flutterw.ps1 analyze
```

## Code Generation

If using code generation (`freezed`, `json_serializable`, etc.):

```powershell
dart run build_runner build
dart run build_runner watch
```

## Environment Configuration

Create a `.env` file for API keys (do not commit it to git):

```env
GOOGLE_AI_API_KEY=your_key_here
SUPABASE_URL=your_url_here
SUPABASE_ANON_KEY=your_key_here
```

## Performance Tips

1. Use `const` constructors where possible
2. Use `Key` for list items that can be reordered
3. Avoid unnecessary widget rebuilds
4. Use `ListView.builder` for long lists
5. Profile with:

```powershell
./tool/flutterw.ps1 run --profile
```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Pub.dev](https://pub.dev/) - Flutter packages
