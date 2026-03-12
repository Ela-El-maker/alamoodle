# Sprint 4 Hardening

## Delivered
- Native sound catalog is now exposed over typed platform API:
  - `getSoundCatalog()`
  - `previewSound(soundId)`
  - `stopSoundPreview()`
- Flutter sound picker was cut over from static/fake data to native catalog + native preview commands.
- Sound picker now writes escalation `startVolume` from UI into native `escalationPolicy` payload (no fake preview-volume contract).
- Alarm create/edit flows now persist native sound and policy fields in typed alarm commands:
  - `vibrationProfileId`
  - `escalationPolicy`
  - `nagPolicy`
  - `primaryAction`
  - `challengePolicy`
- Alarm create/edit UI now exposes production controls for:
  - `nagPolicy` (interval/window/max retries)
  - `primaryAction` (URL / maps payload)
- Native ringing runtime now parses `nagPolicy` and schedules safe delayed nag retries (idle-safe cadence via `NagPlanner`) when a ring session ends without a terminal user action.
- Added Flutter architecture cutover layers for Sprint 4:
  - `features/settings` sound repository + controller
  - `features/history` stats repository + controller
  - sound picker/stats dashboard now consume those controllers instead of direct platform calls
- Legacy emergency fallback is disabled by default and only available via debug override.
- Native QR challenge path is implemented and manifest/dependencies are wired (`CameraX` + ML Kit scanner).
- Native challenge gating is active in the ring activity for `math`, `memory`, and `qr` policies.
- Steps challenge is explicitly deferred from production selectors.
- Native stats materialization is integrated (`daily_alarm_stats` + `StatsAggregationService`).
- Flutter stats dashboard is now native-backed (`getStatsSummary`, `getStatsTrends`) and no longer hardcoded.
- Onboarding permission/test-ring flow now uses live native checks and real `runTestAlarm()`.
- Reliability snapshot now includes `legacyFallbackDefaultEnabled` and is surfaced in reliability UI.

## API and schema updates
- Pigeon host methods added:
  - `getSoundCatalog`
  - `previewSound`
  - `stopSoundPreview`
  - `getStatsSummary`
  - `getStatsTrends`
  - `getOnboardingReadiness`
- DTO additions:
  - `SoundProfileDto`
  - `StatsSummaryDto`
  - `StatsTrendPointDto`
  - `OnboardingReadinessDto`
- `ReliabilitySnapshotDto` extended with `legacyFallbackDefaultEnabled`.
- Room schema bumped to v2:
  - Added policy/profile columns to `alarm_plans`.
  - Added `daily_alarm_stats` table.

## Tests added/updated
- Android:
  - `SoundCatalogRepositoryTest`
  - `AlarmEscalationControllerTest`
  - `NagPlannerTest`
  - `PrimaryActionLauncherTest`
  - `ChallengeCoordinatorTest`
  - `StatsAggregationServiceTest`
  - Updated `GuardianAlarmHostApiImplTest` for new gateway methods/DTO fields.
  - Updated `DiagnosticsExporterTest` for reliability DTO extension.
- Flutter:
  - Extended `guardian_platform_api_test.dart` to cover sound/stats/onboarding typed mapping.
  - Updated reliability test fixtures with new snapshot field.
  - Added policy-field mapping assertion in `alarm_record_anchor_test.dart`.
  - Added `sound_controller_test.dart` and `stats_controller_test.dart`.

## Verification commands
- `flutter analyze`
- `flutter test`
- `cd android && ./gradlew :app:compileDebugKotlin :app:testDebugUnitTest`

## Remaining for Sprint 5+
- Full production challenge UX parity (beyond current native gate implementation).
- Advanced sound import/streaming catalogs.
- Broader onboarding polish and ecosystem features (widgets/wearables/cloud/assistant).
