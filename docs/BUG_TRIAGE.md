# Bug Triage — Sprint 6

## Severity Policy
- `P0`: Release blocker. Alarm core reliability/security/data loss path broken.
- `P1`: High risk; can ship only with explicit approval and mitigation.
- `P2`: Non-blocking polish or low-risk functional issue.

## Routing Buckets
- Scheduler/planner
- Receiver/service/ring session
- Recovery/repair
- OEM/power-state
- Flutter UX/state
- Permissions/configuration
- Known platform limitation

## Triage Board Template
| ID | Severity | Bucket | Device | Scenario | Summary | Owner | Status | ETA | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| TRIAGE-001 | P2 | Startup/performance | Infinix X658E (Android 11) | QA-001 precheck | `adb am start -W` returns timeout/UNKNOWN launch state twice; app still launches. Requires startup perf profiling before beta signoff on aggressive OEM. | Android | Open | Sprint 6 | [device_launch_smoke.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/device_launch_smoke.txt) |
| TRIAGE-002 | P2 | Permissions/configuration | Infinix X658E (Android 11) | QA-022 precheck | `adb shell setprop persist.sys.timezone ...` fails on non-root build (`Failed to set property`). Recovery scenario must use manual Settings timezone change on certification devices. | Android | Open | Sprint 6 | [phone_lifecycle_20260310T192214Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/phone_lifecycle_20260310T192214Z_infinix_x658e.txt) |
| TRIAGE-003 | P1 | OEM/power-state | Infinix X658E (Android 11) | QA-003/QA-017 stress precheck | `adb monkey` run (`120` events) aborted at event `86` with ANR in `com.example.alarmmaster/.MainActivity` (`Input dispatching timed out`, no focused window during startup). Needs reproducibility check with non-monkey scripted launch loops and startup profiling before beta promotion on D3. | Android | Open | Sprint 6 | [monkey_20260310T192214Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/monkey_20260310T192214Z_infinix_x658e.txt), [logcat_monkey_20260310T192214Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/logcat_monkey_20260310T192214Z_infinix_x658e.txt) |
| TRIAGE-004 | P1 | Scheduler/planner | Infinix X658E (Android 11) | QA-001 diagnostic | Enabled alarms could remain active with `triggerCount=0` (no future trigger instances), causing silent “won't ring” behavior. Fixed by native `enableAlarm` guard: auto-revert to disabled + throw failure + history event `ENABLE_REJECTED_NO_FUTURE_TRIGGERS`. | Android | Closed | 2026-03-10 | [trigger_diagnostic_20260310T203433Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/trigger_diagnostic_20260310T203433Z_infinix_x658e.txt), [AlarmCoreService.kt](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/bridge/AlarmCoreService.kt:93), [AlarmCoreService.kt](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/bridge/AlarmCoreService.kt:360) |
| TRIAGE-005 | P1 | Recovery/repair | Infinix X658E (Android 11) | QA-040 instrumentation | Startup sanity did not clear stale `schedule_registry` rows when no future triggers existed (`repairFutureScheduleDetailed` returned early). Fixed by removing early return and always reconciling stale active registry entries; covered by unit test `removesStaleRegistryEntries_evenWhenNoFutureTriggersRemain` and instrumentation `startupSanity_removesStaleRegistryRow`. | Android | Closed | 2026-03-11 | [ScheduleRepairer.kt](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/main/kotlin/com/example/alarmmaster/alarm/scheduler/ScheduleRepairer.kt), [ScheduleRepairerTest.kt](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/test/kotlin/com/example/alarmmaster/alarm/scheduler/ScheduleRepairerTest.kt), [connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt) |
| TRIAGE-006 | P1 | OEM/power-state | Infinix X658E (Android 11) | Future Event Certification accelerated lane | Regression observed in final-round physical run (`2026-03-12`): accelerated lane crashed instrumentation process again and missed PRE#3 + MAIN stage (`MISS`), while canonical plan/persistence, recovery extension, clock-warp, and restore-install still passed. Requires dedicated repro/fix loop before final release signoff. | Android | Reopened | Sprint 6 | [future_event_cert_20260312T145215Z/RESULTS.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/future_event_cert_20260312T145215Z/RESULTS.md), [future_event_cert_20260312T145215Z/accelerated_mirror.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/future_event_cert_20260312T145215Z/accelerated_mirror.txt), [final_round_20260312T144634Z_future_event_harness.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/final_round_20260312T144634Z_future_event_harness.txt), [FutureEventCertificationTest.kt](/home/ela/Work-Force/Mobile-App/alamoodle/android/app/src/androidTest/kotlin/com/example/alarmmaster/alarm/FutureEventCertificationTest.kt), [future_event_cert_phone.sh](/home/ela/Work-Force/Mobile-App/alamoodle/scripts/qa/future_event_cert_phone.sh) |

## Exit Criteria
- `P0 = 0`
- Any open `P1` must have explicit release-owner signoff and mitigation entry.
