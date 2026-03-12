# Sprint 6 Physical Certification Results

## Status
- Matrix status: In Progress
- Required devices:
  - D1 Pixel (Android 14+): Pending
  - D2 Samsung (One UI recent): Pending
  - D3 Aggressive OEM: In Progress (Infinix X658E connected)

## Automated Verification
- `flutter analyze`: pass ([flutter_analyze.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/flutter_analyze.txt))
- `flutter test`: pass ([flutter_test.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/flutter_test.txt))
- `./android/gradlew -p android app:compileDebugKotlin app:testDebugUnitTest`: pass ([android_compile_and_unit_tests.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/android_compile_and_unit_tests.txt))
- Latest rerun (`2026-03-11`):
  - `flutter analyze`: pass ([flutter_analyze_latest.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/flutter_analyze_latest.txt))
  - `flutter test`: pass ([flutter_test_latest.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/flutter_test_latest.txt))
  - `./android/gradlew -p android app:compileDebugKotlin app:testDebugUnitTest`: pass ([android_compile_unit_latest.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/android_compile_unit_latest.txt))

## New Reliability Automation (debug + physical instrumentation)
- `FutureAlarmPhysicalSimulationTest` (pre + main trigger path): pass (Infinix X658E).
  - Evidence: [connected_future_alarm_simulation_20260310T230000Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/connected_future_alarm_simulation_20260310T230000Z_infinix_x658e.txt)
- `RecoveryReliabilityPhysicalTest` added for:
  - startup sanity repair missing registry rows,
  - stale registry cleanup,
  - process kill + relaunch persistence,
  - +30 day long-horizon persistence.
  - Evidence: [connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt)
- `Future Event Certification Harness` (`scripts/qa/future_event_cert_phone.sh`) latest run:
  - Evidence root: [future_event_cert_20260312T145215Z](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/future_event_cert_20260312T145215Z)
  - Verdict: `FAIL`
  - Lane status:
    - canonical plan: pass
    - canonical persistence: pass
    - accelerated mirror: fail (`MISS` for PRE#3 and MAIN + instrumentation process crash)
    - recovery extension: pass
    - clock-warp: pass
    - restore-install: pass
  - Summary: [RESULTS.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/future_event_cert_20260312T145215Z/RESULTS.md)
  - Prior pass (kept for audit trail): [future_event_cert_20260311T185023Z/RESULTS.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/future_event_cert_20260311T185023Z/RESULTS.md)
- Focused scheduled path rerun (`FutureAlarmPhysicalSimulationTest`) latest run:
  - Evidence: [connected_future_alarm_simulation_latest.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/connected_future_alarm_simulation_latest.txt)
  - Device test log: [test-results.log](/home/ela/Work-Force/Mobile-App/alamoodle/build/app/outputs/androidTest-results/connected/debug/Infinix%20X658E%20-%2011/testlog/test-results.log)
  - Verdict: pass (`OK (1 test)`)

## Early findings
- Command-level lifecycle pass completed (`2026-03-10T19:22:14Z` run id `20260310T192214Z_infinix_x658e`):
  - install/launch/force-stop/relaunch succeeded
  - doze command sequence succeeded
  - reboot and post-boot relaunch succeeded
  - no `FATAL EXCEPTION`/`AndroidRuntime` for `com.example.alarmmaster` in captured logs
- `TRIAGE-004` (enabled alarm with zero future triggers) is fixed and closed.
- `TRIAGE-006` is reopened after latest physical run regressed in accelerated mirror lane; final release signoff remains blocked until this lane is stable again.

## Scenario Results
Populate with evidence links per run. Scenario definitions live in [QA_MATRIX.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/QA_MATRIX.md).

| Scenario | D1 | D2 | D3 | Evidence | Notes |
|---|---|---|---|---|---|
| QA-001 | ☐ | ☐ | ☐ |  |  |
| QA-002 | ☐ | ☐ | ☐ |  |  |
| QA-003 | ☐ | ☐ | ☐ |  |  |
| QA-004 | ☐ | ☐ | ☐ |  |  |
| QA-005 | ☐ | ☐ | ☐ |  |  |
| QA-006 | ☐ | ☐ | ☐ |  |  |
| QA-007 | ☐ | ☐ | ☑ | [connected_future_alarm_simulation_20260310T230000Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/connected_future_alarm_simulation_20260310T230000Z_infinix_x658e.txt) | PRE trigger fired in physical simulation |
| QA-008 | ☐ | ☐ | ☑ | [connected_future_alarm_simulation_20260310T230000Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/connected_future_alarm_simulation_20260310T230000Z_infinix_x658e.txt) | MAIN trigger fired in physical simulation |
| QA-009 | ☐ | ☐ | ☐ |  |  |
| QA-010 | ☐ | ☐ | ☐ |  |  |
| QA-011 | ☐ | ☐ | ☐ |  |  |
| QA-012 | ☐ | ☐ | ☐ |  |  |
| QA-013 | ☐ | ☐ | ☐ |  |  |
| QA-014 | ☐ | ☐ | ☐ |  |  |
| QA-015 | ☐ | ☐ | ☐ |  |  |
| QA-016 | ☐ | ☐ | ☐ |  |  |
| QA-017 | ☐ | ☐ | ☐ |  |  |
| QA-018 | ☐ | ☐ | ☐ |  |  |
| QA-019 | ☐ | ☐ | ☐ |  |  |
| QA-020 | ☐ | ☐ | ☐ |  |  |
| QA-021 | ☐ | ☐ | ☐ |  |  |
| QA-022 | ☐ | ☐ | ☐ |  |  |
| QA-023 | ☐ | ☐ | ☐ |  |  |
| QA-024 | ☐ | ☐ | ☐ |  |  |
| QA-025 | ☐ | ☐ | ☐ |  |  |
| QA-026 | ☐ | ☐ | ☐ |  |  |
| QA-027 | ☐ | ☐ | ☐ |  |  |
| QA-028 | ☐ | ☐ | ☐ |  |  |
| QA-029 | ☐ | ☐ | ☑ | [connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt) | Process kill path verified by instrumentation |
| QA-030 | ☐ | ☐ | ☐ |  |  |
| QA-031 | ☐ | ☐ | ☐ |  |  |
| QA-032 | ☐ | ☐ | ☐ |  |  |
| QA-033 | ☐ | ☐ | ☑ | [connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt) | Startup sanity + relaunch persistence verified |
| QA-034 | ☐ | ☐ | ☑ | [connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt) | +30 day trigger identity persistence verified |
| QA-035 | ☐ | ☐ | ☐ |  |  |
| QA-036 | ☐ | ☐ | ☐ |  |  |
| QA-037 | ☐ | ☐ | ☐ |  |  |
| QA-038 | ☐ | ☐ | ☐ |  |  |
| QA-039 | ☐ | ☐ | ☑ | [connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt) | Missing registry row repair verified |
| QA-040 | ☐ | ☐ | ☑ | [connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/connected_recovery_reliability_20260310T225959Z_infinix_x658e.txt) | Stale registry cleanup verified |
| QA-041 | ☐ | ☐ | ☐ |  |  |
| QA-042 | ☐ | ☐ | ☐ |  |  |
| QA-043 | ☐ | ☐ | ☐ |  |  |
| QA-044 | ☐ | ☐ | ☐ |  |  |
| QA-045 | ☐ | ☐ | ☐ |  |  |
| QA-046 | ☐ | ☐ | ☐ |  |  |
| QA-047 | ☐ | ☐ | ☐ |  |  |
| QA-048 | ☐ | ☐ | ☐ |  |  |
| QA-049 | ☐ | ☐ | ☐ |  |  |
| QA-050 | ☐ | ☐ | ☐ |  |  |
| QA-051 | ☐ | ☐ | ☐ |  |  |
| QA-052 | ☐ | ☐ | ☐ |  |  |
| QA-053 | ☐ | ☐ | ☐ |  |  |
| QA-054 | ☐ | ☐ | ☐ |  |  |
| QA-055 | ☐ | ☐ | ☐ |  |  |
| QA-056 | ☐ | ☐ | ☐ |  |  |
| QA-057 | ☐ | ☐ | ☐ |  |  |
| QA-058 | ☐ | ☐ | ☐ |  |  |
| QA-059 | ☐ | ☐ | ☐ |  |  |
| QA-060 | ☐ | ☐ | ☐ |  |  |
| QA-061 | ☐ | ☐ | ☐ |  |  |
| QA-062 | ☐ | ☐ | ☐ |  |  |
| QA-063 | ☐ | ☐ | ☐ |  |  |
| QA-064 | ☐ | ☐ | ☐ |  |  |
| QA-065 | ☐ | ☐ | ☐ |  |  |
