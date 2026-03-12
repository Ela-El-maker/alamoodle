# QA Matrix — Alarm Reliability Certification

## Purpose
Define end-to-end certification scenarios for alarm reliability across process death, app relaunch, reboot/recovery, power constraints, permissions, and long-horizon schedules.

## Pass Rules
- Every `Critical` scenario must pass on all required devices in [DEVICE_TEST_MATRIX.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/DEVICE_TEST_MATRIX.md).
- Any `Critical` failure is treated as `P0` until triaged.
- `P0` open count must be `0` before beta sign-off.
- No unresolved `P1` is allowed in core ring path (`trigger -> receiver -> service -> activity -> dismiss/snooze`).

## Procedure Harness (required for every scenario)
1. Capture device baseline (manufacturer/model/OS, local time, UTC time).
2. Start clean `logcat` capture.
3. Capture pre-state diagnostics export.
4. Execute scenario action steps.
5. Capture at-trigger evidence window (`T-30s` to `T+90s`).
6. Capture post-state diagnostics export.
7. Record pass/fail and triage ID (if failed) in results sheet.

Runbook and command references:
- [PHONE_TEST_RUNBOOK.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/PHONE_TEST_RUNBOOK.md)
- `adb shell pidof com.example.alarmmaster`
- `adb shell dumpsys alarm | rg com.example.alarmmaster`
- `adb shell dumpsys activity services | rg -n "AlarmRingingService|com.example.alarmmaster"`
- `adb shell cmd deviceidle force-idle` / `adb shell cmd deviceidle unforce`
- `adb shell am force-stop com.example.alarmmaster`
- `adb reboot`

## Scenario Matrix
| ID | Scenario | Category | Expected Result | Severity |
|---|---|---|---|---|
| QA-001 | One-time alarm rings when app open | Ring core | Receiver->service->activity executes, dismiss/snooze available | Critical |
| QA-002 | One-time alarm rings when app backgrounded | Ring core | Same as QA-001 | Critical |
| QA-003 | One-time alarm rings after app swiped from recents | Lifecycle | Same as QA-001 after process death | Critical |
| QA-004 | Alarm rings with screen locked | Lock screen | Full-screen or actionable notification controls available | Critical |
| QA-005 | Alarm rings with screen off | Power state | Wake + ring flow works | Critical |
| QA-006 | Recurring alarm fires next valid occurrence | Planner/scheduler | Correct next trigger generated and fired | Critical |
| QA-007 | Event reminder pre-alert fires before anchor | Planner/scheduler | Pre-alert trigger fires at expected offset | High |
| QA-008 | Event main trigger fires at anchor | Planner/scheduler | Main trigger fires at planned anchor time | Critical |
| QA-009 | Snooze 5/10/15 from notification | Session state | New snooze trigger created and rescheduled | Critical |
| QA-010 | Snooze 5/10/15 from activity | Session state | Behavior matches notification snooze | Critical |
| QA-011 | Dismiss from notification | Session state | Session ends, audio/vibration/FGS stop | Critical |
| QA-012 | Dismiss from activity | Session state | Behavior matches notification dismiss | Critical |
| QA-013 | Nag mode retry cadence | Policy | Retries respect policy and no burst storms | High |
| QA-014 | Challenge-gated dismiss (math/memory/qr) | UX integrity | Dismiss blocked until challenge success | High |
| QA-015 | Exact-alarm denied path | Reliability | Degraded state surfaced; actionable fix CTA | Critical |
| QA-016 | Notification denied path | Reliability | Degraded state surfaced; actionable fix CTA | Critical |
| QA-017 | Doze idle behavior | Power state | Exact alarm behavior matches platform limits | Critical |
| QA-018 | Battery saver enabled | Power state | Reliability reflects elevated risk; behavior validated | High |
| QA-019 | Restricted background mode | Power state | Reliability reflects risk and guidance displayed | High |
| QA-020 | Device reboot recovery | Recovery | Future alarms restored after boot | Critical |
| QA-021 | Locked boot then unlock reconciliation | Recovery | Pre-unlock restore + post-unlock reconciliation, no duplicates | Critical |
| QA-022 | Timezone change recovery | Recovery | Future triggers recomputed correctly | Critical |
| QA-023 | Manual time forward/backward recovery | Recovery | Stale/late/valid behavior classified correctly | Critical |
| QA-024 | App update (package replaced) recovery | Recovery | Schedules repaired, no duplicate storms | High |
| QA-025 | Backup export/import (replace existing) | Data integrity | Restored alarms/templates rescheduled correctly | Critical |
| QA-026 | Template create/apply flow | Authoring | Template policies carry over to new alarm | High |
| QA-027 | Sound preview then real ring profile | Audio | Selected profile used in actual ring | High |
| QA-028 | OEM guidance relevance | Trust UX | Manufacturer-appropriate guidance and CTAs | High |
| QA-029 | `am kill` process death with pending one-time alarm | Lifecycle | Alarm still fires at due time | Critical |
| QA-030 | Multiple recents clears before due time | Lifecycle | Alarm still fires once; no duplicate sessions | Critical |
| QA-031 | App cleared from recents during active ring session | Lifecycle | Active session remains service-owned and controllable | High |
| QA-032 | Process death immediately after schedule save | Lifecycle | Trigger remains registered and fires | Critical |
| QA-033 | Cold launch after process death runs startup sanity without drift | Recovery | Startup sanity runs; healthy schedule unchanged | High |
| QA-034 | One-time alarm at +30 days survives recents clear | Long horizon | Trigger identity and scheduled UTC remain stable | Critical |
| QA-035 | One-time alarm at +90 days survives app restart | Long horizon | Trigger remains scheduled and unchanged | Critical |
| QA-036 | One-time alarm at +180 days survives reboot | Long horizon | Trigger restored and retained | Critical |
| QA-037 | Weekday recurring alarm remains valid after 14-day idle usage window | Long horizon | Recurring chain continues without gaps/duplicates | High |
| QA-038 | Future event (+30d anchor, multi pre-offsets) survives package update | Long horizon | Trigger set remains consistent after update repair | High |
| QA-039 | Startup sanity repairs intentionally missing registry row | Recovery integrity | Missing schedule entry restored | Critical |
| QA-040 | Startup sanity removes intentionally stale registry row | Recovery integrity | Stale row removed without harming valid triggers | Critical |
| QA-041 | Startup sanity no-op on healthy schedule (no over-repair) | Recovery integrity | No unnecessary trigger churn | High |
| QA-042 | Locked-boot restore then unlock reconciliation does not duplicate | Recovery integrity | Single expected trigger delivery | Critical |
| QA-043 | DST spring-forward nonexistent local time | Time/DST | Shift to next valid local time | High |
| QA-044 | DST fall-back ambiguous local time | Time/DST | First occurrence selected | High |
| QA-045 | Timezone eastbound switch with future anchor | Timezone | Future trigger UTC recomputed correctly | Critical |
| QA-046 | Timezone westbound switch with future anchor | Timezone | Future trigger UTC recomputed correctly | Critical |
| QA-047 | Manual clock +2h near due time | Time change | Late-policy classification and no corruption | High |
| QA-048 | Manual clock -2h near due time | Time change | Duplicate prevention preserved | High |
| QA-049 | Exact alarm denied then re-enabled | Permission | Reliability state and scheduling recover correctly | Critical |
| QA-050 | Notification denied then re-enabled | Permission | Reliability state and alert visibility recover correctly | Critical |
| QA-051 | Battery saver + restricted mode + screen off | Power/OEM | Alarm behavior + guidance remain coherent | High |
| QA-052 | OEM autostart off/on guidance verification | OEM | Guidance matches actual settings behavior | High |
| QA-053 | Doze idle long-wait with spaced alarms | Power/OEM | Delivery consistent with idle constraints | High |
| QA-054 | Aggressive OEM memory cleaner after save | OEM | Future trigger survives or clear risk is surfaced | High |
| QA-055 | Backup import replace with future alarms/templates | Data | Restored entities rescheduled consistently | Critical |
| QA-056 | Import invalid payload cannot corrupt schedules | Data | Existing schedules remain intact | Critical |
| QA-057 | App update with in-flight upcoming alarm | Update | Trigger remains valid through package replace | High |
| QA-058 | DB migration upgrade retains future alarms | Data/migration | No trigger loss after migration | High |
| QA-059 | Low storage during restore/schedule repair | Storage | Fails safely with intact pre-existing schedules | High |
| QA-060 | 500 mixed alarms stress generation | Stress | Stable planner/scheduler behavior | High |
| QA-061 | 50 alarms in one-hour conflict window | Stress | Predictable overlap handling, no crashes | High |
| QA-062 | Rapid create/edit/delete loops | Stress | No stale trigger leaks | High |
| QA-063 | Repeated snooze chain under process churn | Stress | Session state remains correct | High |
| QA-064 | Long monkey run keeps next-alarm integrity | Stress | Next alarm remains valid after stress | High |
| QA-065 | Overnight soak (12h/24h periodic due alarms) | Soak | No drift, no missed sessions, no state corruption | Critical |

## Core Proof Procedures (must be executed verbatim)
| Scenario | Exact Steps | Expected | Failure Signals | Must Collect |
|---|---|---|---|---|
| QA-003 recents clear one-time | schedule `T+2m`, verify in diagnostics, swipe app from recents, confirm PID gone, wait due | receiver->service->ring occurs | no ring, no `FIRED`, stale ignored unexpectedly | logcat, pre/post diagnostics, video |
| QA-034 long-horizon recents persistence | schedule `+30d`, export diagnostics, swipe recents, relaunch app, export diagnostics again | trigger remains identical/scheduled | missing/changed triggerId/requestCode/generation | two diagnostics exports + `dumpsys alarm` |
| QA-033 app restart + startup sanity | schedule `T+3m`, run `am kill`, relaunch app, verify startup sanity event, wait due | alarm fires once, no duplicate | missing fire or double fire | startup logs, history, ring evidence |
| QA-039 startup repair missing row | create alarm, remove one registry row via debug hook, relaunch or run startup sanity | missing row restored | row still missing | recovery event + registry snapshot |
| QA-020 reboot recovery | schedule `T+5m`, reboot, reconnect ADB, do not recreate alarm, wait due | boot recovery restores and alarm rings | no post-boot trigger/ring | boot logs + diagnostics + ring proof |
| QA-021 locked boot + unlock | schedule `T+6m`, reboot, keep locked 3m, unlock, wait due | locked-boot restore + unlock reconciliation, single fire | duplicate or missing fire | LOCKED_BOOT + USER_UNLOCKED evidence |

## Required Evidence Per Scenario
- Device + OS build
- Exact local + UTC timestamp
- Observed result
- Pass/fail
- Log excerpt or screenshot/video link
- If fail: triage ID in [BUG_TRIAGE.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/BUG_TRIAGE.md)
