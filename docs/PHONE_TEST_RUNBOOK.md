# Phone Test Runbook — Alarm Reliability Certification

## Preconditions
- Physical device connected with USB debugging enabled.
- Target package: `com.example.alarmmaster`.
- Installed build: debug or release candidate.
- Timezone and date/time state documented before each run.

## Universal Procedure Harness
1. Capture environment snapshot.
2. Start clean log capture and keep it running for the scenario.
3. Capture pre-state diagnostics export.
4. Execute scenario action steps.
5. Capture trigger window evidence (`T-30s` to `T+90s`).
6. Capture post-state diagnostics export.
7. Update results sheet with scenario ID, verdict, evidence links, and triage ID if failed.

## Environment Snapshot
```bash
adb devices -l
adb shell getprop ro.product.manufacturer
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.sdk
adb shell date
```

## Log Capture
```bash
adb logcat -c
adb logcat -v time | tee docs/evidence/sprint6/logcat_<device>_<run>.txt
```

## Launch / Kill / Stop / Reinstall
```bash
adb shell am start -n com.example.alarmmaster/.MainActivity
adb shell am kill com.example.alarmmaster
adb shell am force-stop com.example.alarmmaster
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Scheduler and Service Probes
```bash
adb shell pidof com.example.alarmmaster
adb shell dumpsys alarm | rg com.example.alarmmaster
adb shell dumpsys activity services | rg -n "AlarmRingingService|com.example.alarmmaster"
```

## Doze / Idle Commands (test only)
```bash
adb shell dumpsys battery unplug
adb shell cmd deviceidle force-idle
adb shell cmd deviceidle step
adb shell cmd deviceidle unforce
adb shell dumpsys battery reset
```

## Permission / Settings Shortcuts
```bash
# Notification permission revoke
adb shell pm revoke com.example.alarmmaster android.permission.POST_NOTIFICATIONS

# App settings page
adb shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:com.example.alarmmaster

# Exact alarm request settings
adb shell am start -a android.settings.REQUEST_SCHEDULE_EXACT_ALARM -d package:com.example.alarmmaster
```

## Reboot / Timezone / Time Change
```bash
adb reboot
adb shell setprop persist.sys.timezone Africa/Nairobi
# If setprop fails on non-root builds, use Settings -> Date & time manually and document it.
```

## Core Scenario Procedures

### QA-003 Recents clear one-time alarm
1. Schedule one-time alarm for `T+2m`.
2. Verify it appears in app diagnostics.
3. Swipe app from recents.
4. Confirm process is gone (`adb shell pidof` returns nothing).
5. Wait until due.
6. Verify ring path executes and controls work.

### QA-033 Process kill + relaunch startup sanity
1. Schedule one-time alarm for `T+3m`.
2. Run `adb shell am kill com.example.alarmmaster`.
3. Relaunch app.
4. Verify startup sanity recovery event in history/diagnostics.
5. Wait until due and verify single ring (no duplicate).

### QA-020 Reboot recovery
1. Schedule one-time alarm for `T+5m`.
2. Reboot with `adb reboot`.
3. Reconnect and do not recreate alarm.
4. Wait until due.
5. Verify ring + recovery evidence.

### QA-021 Locked boot then unlock
1. Schedule alarm for `T+6m`.
2. Reboot device and keep locked for 3 minutes.
3. Unlock device and wait.
4. Verify single trigger path (no duplicate).

### QA-034 Long-horizon persistence (+30 days)
1. Schedule anchored event for `+30d`.
2. Export diagnostics snapshot #1.
3. Swipe recents or `am kill`, relaunch app.
4. Export diagnostics snapshot #2.
5. Verify trigger ID, generation, request code, and scheduled UTC remain stable.

## Force-stop Validation (platform-limit proof)
1. Schedule one-time alarm for `T+2m`.
2. Run `adb shell am force-stop com.example.alarmmaster`.
3. Wait through due time.
4. Reopen app.
5. Verify platform-limit messaging is shown and classification is correct.

Expected: no guaranteed delivery while force-stopped.

## Instrumentation Reliability Commands
```bash
# Physical simulation of future event pre/main firing
./android/gradlew -p android app:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.class=com.example.alarmmaster.alarm.FutureAlarmPhysicalSimulationTest

# Recovery + long-horizon persistence validation
./android/gradlew -p android app:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.class=com.example.alarmmaster.alarm.RecoveryReliabilityPhysicalTest
```

## One-Command Future Event Certification Harness
```bash
./scripts/qa/future_event_cert_phone.sh
```

Outputs:
- Evidence folder: `docs/evidence/sprint6/future_event_cert_<timestamp>/`
- Trigger expectation extraction from instrumentation (`CERT_EXPECT ...`)
- Parsed event verification with delay metrics
- Aggregated markdown verdict: `RESULTS.md`

## Required Evidence Checklist
- Scenario ID
- Device + OS
- Local and UTC timestamps
- Pass/fail
- Screenshot/video and log file references
- Diagnostics export references (pre/post)
- Triage ID for failures
