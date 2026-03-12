# Alarm Reliability Certification Plan

## Goal
Prove alarm delivery reliability across process death, app relaunch, reboot/recovery, permissions, power constraints, and long-horizon schedules.

Pipeline under test:
`AlarmManager -> AlarmTriggerReceiver -> AlarmRingingService -> AlarmActivity`

## Failure Surface Analysis
| Surface | Failure Mode | Primary Cause | Detection Signal |
|---|---|---|---|
| Planner | Trigger never created | recurrence/offset/timezone bug | no future trigger in diagnostics |
| Scheduler | Trigger not registered | exact alarm denied, scheduler bug | missing schedule registry and no `dumpsys alarm` entry |
| Trigger delivery | Receiver never invoked | OS policy, force-stop, PendingIntent mismatch | no `FIRED` or receiver logs at due time |
| Receiver validation | Trigger rejected | stale generation/disabled/duplicate | `TRIGGER_STALE` or `TRIGGER_IGNORED_*` |
| Service start | No ring after fire | `startForegroundService` failure | `TRIGGER_SERVICE_START_FAILED` |
| Foreground promotion | Service dropped | no timely foreground promotion | missing ongoing ring notification |
| Audio/vibration | Silent ring | focus/route/resource failure | `SERVICE_STARTED` without audible/vibrate output |
| Full-screen surface | No alarm UI | OEM policy/lock-screen constraints | notification present without activity |
| Session state | Double/invalid transitions | idempotency defect | duplicate dismiss/snooze anomalies |
| Startup sanity | Missing schedules persist | repair path not reconciling | no `REPAIR_PERFORMED` when expected |
| Reboot recovery | Alarm loss | boot receiver/coordinator defect | post-boot no future schedules |
| Direct Boot | Pre-unlock restore miss | device-protected index defect | missed expected trigger pre-unlock |
| Time changes | Wrong fire instant | DST/timezone/manual time handling issue | shifted/misaligned trigger |
| Package replace | Schedule loss | package replace path missing or partial | post-update future alarms absent |
| Data integrity | Duplicate/stale storms | import/repair mismatch | repeated trigger IDs/request codes |
| Permission degradation | Silent degraded mode | snapshot/classification defect | UI says healthy while denied |
| Power/OEM | Delayed/missed delivery | Doze/battery saver/OEM freezer | delayed triggers + elevated risk state |
| App lifecycle | Recents regression | process-death handling defect | only rings while app alive |
| Force-stop | User expectation mismatch | Android hard stop policy | no trigger until reopen |

## Verification Model
For each scenario, collect proof for all four checkpoints:
1. Planning proof: future trigger exists in storage.
2. Scheduling proof: trigger appears in scheduler registry / `dumpsys alarm`.
3. Delivery proof: `FIRED` + receiver path evidence.
4. Ring proof: service foreground + ring controls available.

Required artifacts:
- device snapshot
- continuous logcat
- diagnostics export pre/post
- screenshot/video for UI/ring paths
- scenario verdict row in results sheet

## Long-Horizon and Extreme Testing
Required long-term scenarios are tracked in [QA_MATRIX.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/QA_MATRIX.md):
- `+30d`, `+90d`, `+180d` persistence
- recurring chain continuity
- package-update + future event persistence
- overnight soak
- high-volume stress (500 alarms)

Extreme edge coverage:
- DST spring/fall behavior
- timezone east/west date-boundary shifts
- manual time forward/backward near due windows
- low storage + repair/restore behavior
- aggressive OEM autostart/background controls

## Debug Testability Hooks (debug-build only)
Implemented in native `AlarmCoreService` for deterministic QA:
- `debugListFutureTriggers()`
- `debugListScheduleRegistry()`
- `debugCorruptSchedule(triggerId)`
- `debugInsertStaleScheduleRegistryEntry(...)`
- `debugRunStartupSanity()`

These hooks are test-only and guarded by `BuildConfig.DEBUG`.

## Acceptance Gate
- All critical scenarios in `QA-001..QA-065` pass on required device set.
- `P0=0`, no unresolved `P1` in core ring path.
- Reboot, locked-boot/unlock, startup sanity, recents clear, and long-horizon persistence are evidenced.
- Native remains sole authority in `shadow_native`.
