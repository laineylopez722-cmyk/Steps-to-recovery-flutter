# Steps to Recovery (Flutter Rebuild)

Fresh rebuild of the app using Flutter + Dart.

The runnable Flutter project is the repo root. A nested `app/` folder exists as a preserved recovery snapshot and is not the canonical app.

## Stack

- Flutter 3.41.x
- Dart 3.11.x
- Material 3 + `go_router`
- Local persistence (`shared_preferences`)
- Local notifications scaffold (`flutter_local_notifications`)
- Remote sync scaffold (`http`)

## Included

- Home dashboard with streak + next action
- Daily check-in (morning/evening)
- Journal page
- Progress page
- Support page
- Emergency contacts editor
- Reminder toggles + schedule hooks
- Offline-first with pending sync queue
- Sync-now action with retry/backoff
- Background sync scheduler scaffold (`workmanager`, periodic task)

## Run

```powershell
./tool/flutterw.ps1 pub get
./tool/flutterw.ps1 run -d chrome
```

`tool/flutterw.ps1` resolves the Flutter SDK from `android/local.properties`, `FLUTTER_ROOT`, or `PATH`, so the project can be run even when `flutter` is not globally available in the shell.
Use `./tool/flutterw.ps1` as the canonical command path in this repo; direct `flutter` commands are optional only when Flutter is already on PATH.

Verified locally on March 21, 2026:

- `./tool/flutterw.ps1 analyze`
- `./tool/flutterw.ps1 test`
- `./tool/flutterw.ps1 build apk --debug`
- `./tool/flutterw.ps1 build web`

Windows desktop builds additionally require Visual Studio with the "Desktop development with C++" workload installed.

## Optional remote sync config

Pass backend values with dart-defines:

```powershell
./tool/flutterw.ps1 run `
  --dart-define=API_BASE_URL=https://your-api.example.com `
  --dart-define=API_AUTH_TOKEN=your_token_here
```

If `API_BASE_URL` is omitted, app runs fully offline/local.
