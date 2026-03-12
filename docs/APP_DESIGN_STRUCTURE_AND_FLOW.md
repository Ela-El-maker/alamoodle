# Alarmmaster App: End-to-End Design Structure and Flow

## 1. Document Scope

This document describes the current Flutter application implementation in this repository end-to-end:

- architecture and module structure
- startup/boot lifecycle
- route/navigation flow
- alarm domain model and persistence
- notification scheduling and alarm trigger lifecycle
- screen-by-screen behavior
- platform integration (Android/iOS)
- known implementation boundaries (what is demo vs production-ready behavior)

Repository root analyzed: `/home/ela/Work-Force/Mobile-App/alamoodle`

---

## 2. High-Level Architecture

The app is a **single Flutter application** with a presentation-heavy structure and light service layer.

### Current Layering

- `lib/main.dart`
  - app bootstrap, global navigator key, error widget, orientation lock
- `lib/routes/app_routes.dart`
  - static named route registry
- `lib/presentation/**`
  - all feature screens and most state handling
- `lib/services/**`
  - notifications scheduling, local alarm storage, haptic patterns
- `lib/theme/app_theme.dart`
  - visual theme and shared colors/typography
- `lib/widgets/**`
  - shared UI primitives + error helpers

### Architectural Style in Practice

- Mostly **StatefulWidget + local state**.
- Business logic is split between screens and services.
- Alarm data is stored as untyped `Map<String, dynamic>` objects.
- No explicit repository/use-case/domain entities.

---

## 3. Codebase Structure

## `lib/`

- `main.dart` - app entry
- `core/app_export.dart` - re-export utility bundle
- `routes/app_routes.dart` - route constants + builder map
- `services/`
  - `alarm_notification_service.dart`
  - `alarm_storage_service.dart`
  - `haptic_service.dart`
- `presentation/`
  - `home_dashboard_screen/`
  - `alarm_creation_screen/`
  - `alarm_detail_screen/`
  - `alarm_ringing_screen/`
  - `challenge_screen/`
  - `sound_picker_screen/`
  - `reliability_settings_screen/`
  - `stats_dashboard_screen/`
  - `onboarding_flow_screen/`
- `theme/app_theme.dart`
- `widgets/`
  - `custom_bottom_bar.dart`
  - `app_error_widget.dart`
  - `custom_error_widget.dart`
  - `custom_image_widget.dart`
  - `custom_icon_widget.dart`

## Platform folders

- `android/` (Kotlin + manifest + Gradle KTS)
- `ios/` (Swift AppDelegate + Info.plist + Podfile)
- Also standard Flutter desktop/web folders (`linux/`, `macos/`, `windows/`, `web/`)

---

## 4. Bootstrap and Runtime Initialization Flow

## 4.1 `main()` flow

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `AlarmNotificationService.initialize()`
3. `AlarmNotificationService.requestPermissions()`
4. Register notification tap callback (`onNotificationTap`) that navigates to ringing screen.
5. Install custom `ErrorWidget.builder` with throttling.
6. Lock orientation to portrait with `SystemChrome.setPreferredOrientations([portraitUp])`.
7. `runApp(MyApp())`.

## 4.2 `MyApp` configuration

- Wrapped in `Sizer` for responsive sizing helpers (`w`, `h`, `sp`).
- `MaterialApp` uses:
  - `navigatorKey: rootNavigatorKey`
  - `routes: AppRoutes.routes`
  - `initialRoute: AppRoutes.initial` (`/`)
  - fixed `textScaler: 1.0` in `builder` (disables system text scaling impact)
- `themeMode` forced to `ThemeMode.light`, while many screens manually use dark colors.

---

## 5. Navigation and Route Graph

## 5.1 Route table

Defined in `lib/routes/app_routes.dart`:

- `/` -> `HomeDashboardScreen`
- `/alarm-creation-screen` -> `AlarmCreationScreen`
- `/home-dashboard-screen` -> `HomeDashboardScreen`
- `/alarm-ringing-screen` -> `AlarmRingingScreen`
- `/challenge-screen` -> `ChallengeScreen`
- `/alarm-detail-screen` -> `AlarmDetailScreen`
- `/sound-picker-screen` -> `SoundPickerScreen`
- `/reliability-settings-screen` -> `ReliabilitySettingsScreen`
- `/stats-dashboard-screen` -> `StatsDashboardScreen`
- `/onboarding-flow-screen` -> `OnboardingFlowScreen`

## 5.2 Nested navigator behavior

`HomeDashboardScreen` contains its own nested `Navigator` plus bottom bar. Tabs switch using `pushReplacementNamed` inside the nested navigator.

Implication:

- feature screens opened with `rootNavigator: true` bypass nested stack for top-level overlays/details.

---

## 6. Alarm Domain Model and Data Contracts

The app uses map-based alarm records.

## 6.1 Stored alarm object shape

Used across dashboard/detail/storage:

```json
{
  "id": 1,
  "time": "06:30",
  "period": "AM",
  "name": "Morning Workout",
  "enabled": true,
  "repeatDays": ["Mon", "Tue", "Wed", "Thu", "Fri"],
  "sound": "Sunrise",
  "challenge": "Math Puzzle",
  "snoozeCount": 2,
  "snoozeDuration": 5,
  "vibration": true
}
```

## 6.2 Alarm creation result contract

`AlarmCreationScreen` pops:

```json
{
  "time": "TimeOfDay",
  "days": [true, false, ...],
  "sound": "Default Alarm",
  "challenge": "Math",
  "snoozeDuration": 5,
  "snoozeCount": 3,
  "label": "Morning",
  "repeatMode": "once|weekdays|everyday|custom",
  "enabled": true
}
```

Dashboard converts this into persisted alarm schema and normalizes challenge names.

## 6.3 Notification payload contract

Scheduled payload format:

- normal: `"alarmId|label|sound|challenge"`
- snooze: `"alarmId|label|sound|challenge|snooze"`

Notification tap parser in `main.dart` reads first 4 segments and navigates to ringing screen.

---

## 7. Core Services

## 7.1 `AlarmNotificationService`

Responsibilities:

- plugin initialization (`flutter_local_notifications`)
- timezone initialization (`timezone` + `flutter_timezone`)
- Android notification channel creation (`alarm_channel`)
- permission request wrapper (iOS + Android)
- exact alarm permission check (Android)
- schedule/cancel/snooze operations
- app-start rescheduling (`rescheduleAll`)

Scheduling modes:

- one-time: next instance of time
- daily: `matchDateTimeComponents: time`
- specific weekdays: one schedule per day using derived IDs

Notification ID strategy:

- base alarm id: `alarmId`
- weekday schedules: `1,000,000 + (alarmId * 10) + weekday`
- snooze schedules: `2,000,000 + alarmId`

Android mode used:

- `AndroidScheduleMode.exactAllowWhileIdle`

## 7.2 `AlarmStorageService`

- uses `SharedPreferences`
- key: `saved_alarms_v1`
- stores full alarm list as JSON string
- supports fallback seeding when storage is empty

## 7.3 `HapticService`

- centralized static haptic patterns
- separate methods for validation, buttons, snooze, challenge, ringing, dismiss

---

## 8. End-to-End Product Flows

## 8.1 App Launch -> Dashboard Load

1. App starts and initializes notification system.
2. Dashboard `initState` calls `_loadAlarms()`.
3. Loads alarms from storage with `_defaultAlarms` fallback seed.
4. Normalizes all alarm maps.
5. Calls `cancelAllAlarms()` then `rescheduleAll(activeAlarms)`.
6. Checks exact alarm permission and conditionally shows banner.
7. Renders:
  - header
  - permission banner (optional)
  - next alarm card
  - alarm list

## 8.2 Create Alarm Flow

1. Tap `Add Alarm` FAB or bottom tab.
2. `AlarmCreationScreen` captures time/repeat/label/sound/challenge/snooze.
3. Validation includes:
  - label length
  - custom repeat day requirement
  - warning for past time if one-time mode
4. Save returns creation payload to dashboard.
5. Dashboard converts to persisted schema (`_fromCreationResult`), assigns next id.
6. Persists and schedules notification if enabled.

## 8.3 Edit Alarm Flow

1. Tap alarm card (or slide edit action).
2. `AlarmDetailScreen` loads route args into local state.
3. Edit options via bottom sheets: repeat, label, sound, snooze, challenge, vibration.
4. Save pops updated map.
5. Dashboard replaces alarm, persists, cancels old schedule if needed, re-schedules when enabled.

## 8.4 Delete Alarm Flow

1. Swipe delete or delete in detail screen.
2. Dashboard removes item and cancels associated notifications.
3. Shows snackbar with Undo.
4. Undo re-inserts and re-schedules if enabled.

## 8.5 Toggle Alarm On/Off

1. Switch triggers `_toggleAlarm(id, value)`.
2. On enable: parse time -> schedule alarm via service.
3. On disable: cancel alarm via service.
4. Persist updated state.
5. Inline scheduling error flag shown per alarm when schedule fails.

## 8.6 Ringing Flow (notification tap path)

1. Notification tap callback in `main.dart` navigates to `/alarm-ringing-screen`.
2. `AlarmRingingScreen` enters immersive UI mode.
3. User can:
  - Snooze: schedules snooze notification and routes back home with snooze args.
  - Dismiss: immediate dismiss if challenge off.
  - Dismiss with challenge: opens in-screen `ChallengeWidget` gate.
4. On dismiss, exits immersive mode and returns to dashboard.

## 8.7 Snooze Return Flow

1. Ringing screen passes:

```json
{
  "snoozed": true,
  "alarmId": 123,
  "snoozeCount": 2,
  "snoozeDuration": 5
}
```

2. Dashboard handles in `didChangeDependencies` once.
3. Updates `snoozeCount` and persists.
4. Shows success snackbar.

---

## 9. Screen-by-Screen Behavior Summary

## 9.1 Home Dashboard

Main orchestration screen:

- loads/persists alarms
- schedules/cancels alarms
- handles permission warning UI
- supports refresh, bulk off, delete undo

Primary widgets:

- `NextAlarmWidget`
- `AlarmCardWidget` (slidable edit/delete)
- `PermissionBannerWidget`
- `EmptyAlarmWidget`
- `AppErrorWidget`

## 9.2 Alarm Creation

Features:

- wheel-style time picker
- repeat presets + custom day chips
- alarm label field with validation
- challenge selector
- snooze stepper settings
- modal sound picker list

Returns creation payload to caller.

## 9.3 Alarm Detail

Features:

- parse and display existing alarm data
- mutable toggle + metadata
- bottom sheets for repeat/challenge/snooze/vibration/sound/label
- delete confirmation dialog
- returns either updated map or `{deleted: true, id: alarmId}`

## 9.4 Alarm Ringing

Features:

- animated time display and gradients
- immersive sticky system UI
- swipe gestures (up dismiss, down snooze)
- action buttons for snooze/dismiss
- optional challenge gating via in-screen `ChallengeWidget`

## 9.5 Dedicated Challenge Screen

Separate route (`/challenge-screen`) with challenge type switcher and four challenge modules:

- Math
- QR
- Steps
- Memory

Used as a standalone demo/challenge experience.

## 9.6 Sound Picker

Features:

- categorized static sound catalog
- row select + play/stop preview state UI
- now playing banner
- preview volume slider
- extra toggles (escalating volume, vibration)

Note: currently UI state only; no real audio engine playback integrated.

## 9.7 Reliability Settings

Features:

- static permission status list
- severity ordering (critical -> warning -> ok)
- fake re-check animation + snackbar
- per-item "Fix issue" modal with manual steps

Note: currently informational/demo; not querying live OS permission state in this screen.

## 9.8 Stats Dashboard

Features:

- static metrics cards
- streak banner
- toughest alarm block
- weekly overview bars

Note: metrics are hardcoded demo values, not computed from persisted alarm history.

## 9.9 Onboarding Flow

3-step non-scrollable PageView:

1. Welcome
2. Permissions
3. Test ring simulation

Note: permission step currently toggles local booleans only, not OS permission APIs.

---

## 10. Challenge Module Implementations

## Math challenge

- random operands/operators
- keypad input with delete/submit
- wrong answer triggers haptic + reset/regenerate

## Memory challenge

- 2x2 color tile sequence memory game
- progresses up to 3 rounds then solves

## QR challenge

- camera scan UI simulation
- flashlight toggle UI only
- "simulate scan" button calls solved callback

## Steps challenge

- circular progress visual
- tap-to-increment demo steps
- solve at target step count

Important: these are interaction simulations; no sensor/camera decode backend wired for production behavior.

---

## 11. Persistence and Resilience Behavior

## What persists

- full alarm list JSON in `SharedPreferences`

## What is reconstructed at startup

- all active schedules are rebuilt by:
  - cancelling all existing notifications
  - re-scheduling from persisted alarms

## Boot/time change handling

Android manifest registers plugin boot receiver with intents for:

- `BOOT_COMPLETED`
- `MY_PACKAGE_REPLACED`
- `TIME_SET`
- `TIMEZONE_CHANGED`
- quick boot actions

So scheduled notifications are intended to survive reboot/time changes via plugin receiver behavior.

---

## 12. Platform Configuration Summary

## 12.1 Android

### Manifest permissions present

- `POST_NOTIFICATIONS`
- `SCHEDULE_EXACT_ALARM`
- `RECEIVE_BOOT_COMPLETED`
- `WAKE_LOCK`
- `VIBRATE`
- `USE_FULL_SCREEN_INTENT`

### Receivers present

- `ScheduledNotificationReceiver`
- `ScheduledNotificationBootReceiver` with boot/time/timezone actions

### Build config

- namespace/applicationId: `com.example.alarmmaster`
- Java/Kotlin target: 17
- AGP: `8.11.1`
- Kotlin plugin: `2.2.20`
- desugaring enabled

### Kotlin entrypoints in repo

- active MainActivity: `android/app/src/main/kotlin/com/example/alarmmaster/MainActivity.kt` (`FlutterActivity`)
- extra legacy file also exists: `android/app/src/main/kotlin/com/flutter_template/app/MainActivity.kt` (`FlutterFragmentActivity`), not aligned with current namespace

## 12.2 iOS

### App delegate

- default `FlutterAppDelegate`
- plugin registration in `didFinishLaunchingWithOptions`

### Info.plist

- standard Flutter defaults
- supports portrait + landscape (runtime still locked to portrait in Flutter)
- no explicit `UIBackgroundModes` entries for alarm background audio/service behavior

### Podfile

- iOS deployment target: `12.0`

---

## 13. Theming and UI System

- Central colors and theme tokens in `AppTheme`.
- Typography uses `GoogleFonts.inter` for app-wide theme text.
- Many feature screens also directly use `GoogleFonts.manrope` and hardcoded color constants.
- Sizer package used extensively (`w`, `h`, `sp`) for adaptive sizing.

Implication: visual style is a hybrid of theme-driven + per-screen hardcoded styling.

---

## 14. Error Handling and User Feedback

- Global render error fallback: `CustomErrorWidget` via `ErrorWidget.builder`.
- Feature-level error surfaces:
  - `AppErrorWidget` full/compact states
  - snackbars (`showError`, `showSuccess`)
- Haptic feedback integrated broadly across tap, validation, challenge, snooze, dismiss events.

---

## 15. Current Testing Coverage

`test/widget_test.dart` includes one smoke test:

- pumps `MyApp`
- checks `My Alarms` and `Add Alarm` text present

No unit tests currently for:

- scheduling logic
- alarm map normalization
- storage serialization/deserialization
- route argument contracts
- challenge success/failure paths

---

## 16. End-to-End Runtime Sequence (ASCII)

```text
App Launch
  -> main(): init notifications + permissions + callbacks
  -> HomeDashboard initial page
      -> load alarms (SharedPreferences or defaults)
      -> normalize alarm records
      -> cancel all scheduled notifications
      -> reschedule enabled alarms
      -> check exact-alarm permission
      -> render dashboard

User Creates Alarm
  -> AlarmCreationScreen (form)
  -> pop result map
  -> dashboard transforms map -> alarm schema
  -> save to storage
  -> schedule notification

Notification Fires
  -> user taps notification
  -> callback parses payload
  -> navigate to AlarmRingingScreen
      -> snooze: schedule snooze notification -> return home with args
      -> dismiss: direct or challenge-gated -> return home

Home receives snooze args
  -> update snooze count
  -> persist
  -> show confirmation
```

---

## 17. Current Implementation Boundaries (Important)

These are not missing files; they are current behavior boundaries in this codebase:

- Alarm sound playback in ringing screen is not implemented in Dart UI (notification sound handled by system notification behavior).
- Sound picker preview is visual state only (no actual audio playback engine connected).
- Reliability screen statuses are static/demo values; it does not live-query all OS permission states.
- Onboarding permission cards are simulated toggles; they do not request real platform permissions there.
- Stats dashboard values are hardcoded demo metrics.
- Challenge modules (QR/steps) are simulation-first rather than sensor/camera decoding implementations.

---

## 18. Dependency Snapshot (App-Relevant)

Primary runtime packages used by current code paths:

- `flutter_local_notifications`
- `timezone`, `flutter_timezone`
- `shared_preferences`
- `sizer`
- `google_fonts`
- `flutter_svg`
- `flutter_slidable`

Additional declared packages exist but are minimally or not actively used in current alarm flow screens (for example `camera`, `record`, `dio`, etc.).

---

## 19. Suggested Next Documentation Files

If you want this doc split into maintainable docs, create:

1. `docs/ARCHITECTURE.md` (layers + module ownership)
2. `docs/ALARM_LIFECYCLE.md` (scheduling and payload contracts)
3. `docs/ROUTES_AND_NAVIGATION.md` (arguments + return contracts)
4. `docs/PLATFORM_CONFIGURATION.md` (Android/iOS requirements)
5. `docs/KNOWN_LIMITATIONS.md` (demo vs production behavior)

