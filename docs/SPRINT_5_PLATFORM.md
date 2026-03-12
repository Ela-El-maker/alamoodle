# Sprint 5 Platform Status

## Scope lock
- Kotlin-first recurrence engine delivery.
- C++ recurrence seam is adapter-only (no runtime ownership).
- Widgets deferred to Sprint 6.
- Restore default: `Replace Existing`.
- DST policy: shift to next valid local minute for nonexistent times; first occurrence for ambiguous times.

## Implemented in this pass
- Extended typed bridge (`pigeons/guardian_api.dart`) with:
  - recurrence + reminder bundle fields on alarm DTOs,
  - template CRUD APIs,
  - backup import/export APIs,
  - OEM guidance API,
  - trigger preview API.
- Regenerated Pigeon bindings:
  - [`lib/platform/gen/guardian_api.g.dart`](/home/ela/Work-Force/Mobile-App/alamoodle/lib/platform/gen/guardian_api.g.dart)
  - [`android/app/src/main/kotlin/com/example/alarmmaster/bridge/gen/GuardianApi.g.kt`](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/bridge/gen/GuardianApi.g.kt)
- Added recurrence engine seam and Kotlin implementation:
  - [`android/app/src/main/kotlin/com/example/alarmmaster/alarm/recurrence/RecurrenceEngine.kt`](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/recurrence/RecurrenceEngine.kt)
  - [`android/app/src/main/kotlin/com/example/alarmmaster/alarm/recurrence/KotlinRecurrenceEngine.kt`](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/recurrence/KotlinRecurrenceEngine.kt)
  - [`android/app/src/main/kotlin/com/example/alarmmaster/alarm/recurrence/NativeRecurrenceEngineAdapter.kt`](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/recurrence/NativeRecurrenceEngineAdapter.kt)
- Added/extended native data services:
  - backup import path: [`android/app/src/main/kotlin/com/example/alarmmaster/alarm/data/BackupImporter.kt`](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/data/BackupImporter.kt)
  - backup export path: [`android/app/src/main/kotlin/com/example/alarmmaster/alarm/data/BackupExporter.kt`](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/data/BackupExporter.kt)
  - OEM guidance mapping: [`android/app/src/main/kotlin/com/example/alarmmaster/alarm/reliability/OemGuidanceProvider.kt`](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/reliability/OemGuidanceProvider.kt)
- Wired runtime/service/gateway/host implementation for new APIs:
  - [`android/app/src/main/kotlin/com/example/alarmmaster/alarm/core/AlarmRuntime.kt`](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/core/AlarmRuntime.kt)
  - [`android/app/src/main/kotlin/com/example/alarmmaster/alarm/bridge/AlarmCoreService.kt`](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/bridge/AlarmCoreService.kt)
  - [`android/app/src/main/kotlin/com/example/alarmmaster/alarm/bridge/AlarmCoreGateway.kt`](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/bridge/AlarmCoreGateway.kt)
  - [`android/app/src/main/kotlin/com/example/alarmmaster/alarm/bridge/GuardianAlarmHostApiImpl.kt`](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/bridge/GuardianAlarmHostApiImpl.kt)
- Updated Flutter platform and alarm model mapping for recurrence/reminder bundle fields and new APIs:
  - [`lib/alarm/shared/alarm_record.dart`](/home/ela/Work-Force/Mobile-App/alamoodle/lib/alarm/shared/alarm_record.dart)
  - [`lib/platform/guardian_platform_models.dart`](/home/ela/Work-Force/Mobile-App/alamoodle/lib/platform/guardian_platform_models.dart)
  - [`lib/platform/guardian_platform_api.dart`](/home/ela/Work-Force/Mobile-App/alamoodle/lib/platform/guardian_platform_api.dart)
- Flutter cutover in this pass:
  - alarm creation flow now supports template apply/save, reminder-bundle presets, recurrence exclusions, and native trigger preview:
    - [`lib/presentation/alarm_creation_screen/alarm_creation_screen.dart`](/home/ela/Work-Force/Mobile-App/alamoodle/lib/presentation/alarm_creation_screen/alarm_creation_screen.dart)
  - reliability screen now surfaces OEM guidance and backup import/export actions:
    - [`lib/presentation/reliability_settings_screen/reliability_settings_screen.dart`](/home/ela/Work-Force/Mobile-App/alamoodle/lib/presentation/reliability_settings_screen/reliability_settings_screen.dart)
  - onboarding permissions now includes native OEM guidance context:
    - [`lib/presentation/onboarding_flow_screen/widgets/onboarding_permissions_widget.dart`](/home/ela/Work-Force/Mobile-App/alamoodle/lib/presentation/onboarding_flow_screen/widgets/onboarding_permissions_widget.dart)
  - reliability repository/controller extended for backup and OEM guidance:
    - [`lib/features/reliability/domain/reliability_repository.dart`](/home/ela/Work-Force/Mobile-App/alamoodle/lib/features/reliability/domain/reliability_repository.dart)
    - [`lib/features/reliability/data/reliability_repository_platform_impl.dart`](/home/ela/Work-Force/Mobile-App/alamoodle/lib/features/reliability/data/reliability_repository_platform_impl.dart)
    - [`lib/features/reliability/state/reliability_controller.dart`](/home/ela/Work-Force/Mobile-App/alamoodle/lib/features/reliability/state/reliability_controller.dart)

## Verification
- `flutter analyze`
- `flutter test`
- `cd android && ./gradlew :app:compileDebugKotlin`
- `cd android && ./gradlew :app:testDebugUnitTest`
