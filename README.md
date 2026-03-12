# Alarmmaster

Android-first alarm app focused on reliability under process death, reboot, and OEM background constraints.

## Core Runtime Path

Primary alarm execution path:

`AlarmManager -> AlarmTriggerReceiver -> AlarmRingingService -> AlarmActivity`

Native (`shadow_native`) remains the source of truth for planning, scheduling, ringing, and recovery.

## Project Structure

- `lib/` Flutter UI, controllers, and bridge models.
- `android/app/src/main/kotlin/.../alarm/` native alarm domain, scheduler, service, recovery.
- `android/app/src/androidTest/` physical-device reliability instrumentation.
- `scripts/qa/` QA harnesses (including future-event certification).
- `scripts/release/` release packaging automation.
- `docs/` roadmap, QA matrices, release gates, and runbooks.

## Local Setup

```bash
flutter pub get
flutter run
```

## Quality Gates (Required Before Release)

```bash
flutter analyze
flutter test
./android/gradlew -p android app:compileDebugKotlin app:testDebugUnitTest
```

Optional physical future-event certification harness:

```bash
./scripts/qa/future_event_cert_phone.sh
```

## Release Preparation

Use the deployment runbook and release script:

- `docs/DEPLOYMENT_RUNBOOK.md`
- `./scripts/release/prepare_android_deploy.sh`

The script packages an Android App Bundle (`.aab`) and writes release evidence metadata.
For local RC builds, release minification can be toggled via Gradle property:

```bash
./android/gradlew -p android bundleRelease -PreleaseMinify=false
```

## Signing and Secrets

- Copy `android/key.properties.example` to `android/key.properties` and fill real signing values.
- `android/key.properties`, keystores, credential files, and generated evidence are ignored by `.gitignore`.

## Platform Limits

Known Android/OEM limits (force-stop behavior, powered-off behavior, OEM restrictions) are documented in:

- `docs/SUPPORT_LIMITATIONS.md`
