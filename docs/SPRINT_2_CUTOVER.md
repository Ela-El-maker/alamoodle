# Sprint 2 Checklist (Final Production Version)

## Goal
- [x] Native trigger receiver path is primary.
- [x] Foreground service owns ring lifecycle.
- [x] Full-screen native alarm activity is in place (Compose).
- [x] Native dismiss/snooze/action flow is in place.
- [x] Flutter ringing route is demoted to legacy/emergency fallback.

## 1) Notification and action foundation
- [x] `ChannelRegistry` with stable IDs (`alarm_ringing`, `alarm_prealerts`, `alarm_service_status`, `alarm_diagnostics`).
- [x] Typed `AlarmAction` model (`DISMISS`, `SNOOZE_5`, `SNOOZE_10`, `SNOOZE_15`, `PRIMARY_ACTION`).
- [x] Action payload carries `alarmId`, `triggerId`, `sessionId`, `generation`.
- [x] `AlarmNotificationFactory` builds ongoing, full-screen, and pre-alert notifications.
- [x] `AlarmFullScreenLauncher` centralized and reusable.
- [x] `NotificationPermissionHelper` integrated into reliability snapshot.

## 2) Trigger receiver pipeline
- [x] `AlarmTriggerReceiver` validates trigger existence, parent enabled state, and generation.
- [x] Duplicate/stale/disabled/missing triggers are rejected with explicit logs.
- [x] `FIRED` history is recorded.
- [x] Receiver starts `AlarmRingingService` via `startForegroundService`.

## 3) Foreground ringing service
- [x] `AlarmRingingService` creates/owns ring session state.
- [x] Immediate foreground promotion and alarm notification posting.
- [x] Uses `AlarmWakeController` and `AlarmAudioController`.
- [x] Idempotent teardown releases audio, vibration, wake resources, and foreground status.
- [x] Overlap guard: rejects second active ring session.
- [x] Duplicate/stale action guard (`sessionId`/`generation` checks).

## 4) Native alarm UI
- [x] Compose `AlarmActivity` implemented.
- [x] Lock-screen-safe presentation and large native action controls.
- [x] Reopen-safe extras handling.
- [x] Activity routes actions to native service (not Flutter).

## 5) Native dismiss/snooze/action ownership
- [x] `AlarmActionReceiver` routes notification actions to service.
- [x] `DISMISS` path ends session and stops ring.
- [x] `SNOOZE_x` path creates/schedules native snooze trigger and ends current session.
- [x] `PRIMARY_ACTION` logs outcome and follows terminal state rules.
- [x] Duplicate action application to same in-memory session is blocked.

## 6) Flutter cutover
- [x] Feature flags added for native-primary ring policy.
- [x] `main.dart` no longer treats notification tap callback as primary in native mode.
- [x] Flutter `AlarmRingingScreen` demoted to legacy/fallback role.
- [x] Dashboard no longer assumes route-return ring ownership in native mode.

## 7) Logging and invariants
- [x] Ring path logs include `source=native`, `pipeline=native_ring`, `fallback_delivery=<bool>`.
- [x] Receiver/service/action outcomes are logged with explicit event types.
- [x] Native session/history repositories support ring outcome tracking.

## 8) Platform wiring
- [x] Manifest includes receiver/service/activity declarations for native ring path.
- [x] Foreground service permissions and type declaration are present.
- [x] Compose build setup is enabled and compiling.

## 9) Test coverage delivered
- [x] Android unit: `AlarmActionMappingTest`, `AlarmNotificationFactoryTest`, `RingSessionStateTest`, `AlarmTriggerValidatorTest`, `AlarmAudioControllerTest`.
- [x] Flutter: bootstrap guardrail tests and platform smoke tests.
- [x] Build checks pass for Android and Flutter.

## Verification commands (latest run)
- [x] `cd android && ./gradlew :app:compileDebugKotlin :app:testDebugUnitTest`
- [x] `flutter analyze`
- [x] `flutter test`

## Deferred to Sprint 3 (non-goals)
- [ ] Boot/timezone/direct-boot recovery execution.
- [ ] Full reliability dashboard wiring and diagnostics export UI.
- [ ] Full manual QA matrix evidence and instrumented `androidTest` suite.
