# Future Event Certification Results

- Run: `20260312T145215Z`
- Package: `com.example.alarmmaster`
- Overall: **FAIL**
- Device env: [phone_env.txt](phone_env.txt)
- Logcat: [logcat.txt](logcat.txt)
- Events: [events.log](events.log)

## Lane Status

| Lane | Exit Code | Verdict |
|---|---:|---|
| canonical_plan | 0 | PASS |
| canonical_persistence | 0 | PASS |
| accelerated_mirror | 1 | FAIL |
| recovery_extension | 0 | PASS |
| clock_warp | 0 | PASS |
| restore_install | 0 | PASS |

## Canonical Trigger Plan (Next Month)

| Trigger ID | Kind | Scheduled UTC (ms) | Verdict |
|---|---:|---:|---|
| `1773327276316-27276-main-0-1775815200000` | MAIN | 1775815200000 | PLAN_OK |
| `1773327276316-27276-pre-0-1775556000000` | PRE | 1775556000000 | PLAN_OK |
| `1773327276316-27276-pre-1-1775728800000` | PRE | 1775728800000 | PLAN_OK |
| `1773327276316-27276-pre-2-1775811600000` | PRE | 1775811600000 | PLAN_OK |

## Accelerated Delivery Validation

| Trigger ID | Kind | Scheduled UTC (ms) | Expected Event | Observed Event Time | Delay (ms) | Verdict |
|---|---:|---:|---|---|---:|---|
| `1773327417632-27417-main-0-1773327840000` | MAIN | 1773327840000 | SERVICE_STARTED | - | - | MISS |
| `1773327417632-27417-pre-0-1773327480000` | PRE | 1773327480000 | PRE_NOTIFICATION_POSTED | 2026-03-12T14:58:00.000Z | 0 | PASS |
| `1773327417632-27417-pre-1-1773327660000` | PRE | 1773327660000 | PRE_NOTIFICATION_POSTED | 2026-03-12T15:01:00.000Z | 0 | PASS |
| `1773327417632-27417-pre-2-1773327780000` | PRE | 1773327780000 | PRE_NOTIFICATION_POSTED | - | - | MISS |

## Lane Outputs

- Canonical plan: [canonical_plan.txt](canonical_plan.txt)
- Canonical persistence: [canonical_persistence.txt](canonical_persistence.txt)
- Accelerated mirror: [accelerated_mirror.txt](accelerated_mirror.txt)
- Recovery extension: [recovery_extension.txt](recovery_extension.txt)
- Clock warp: [clock_warp.txt](clock_warp.txt)
