# Future Event Certification Results

- Run: `20260311T180659Z`
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
| `1773252507679-52507-main-0-1775815200000` | MAIN | 1775815200000 | PLAN_OK |
| `1773252507679-52507-pre-0-1775556000000` | PRE | 1775556000000 | PLAN_OK |
| `1773252507679-52507-pre-1-1775728800000` | PRE | 1775728800000 | PLAN_OK |
| `1773252507679-52507-pre-2-1775811600000` | PRE | 1775811600000 | PLAN_OK |

## Accelerated Delivery Validation

| Trigger ID | Kind | Scheduled UTC (ms) | Expected Event | Observed Event Time | Delay (ms) | Verdict |
|---|---:|---:|---|---|---:|---|
| `1773252647932-52647-main-0-1773253080000` | MAIN | 1773253080000 | SERVICE_STARTED | - | - | MISS |
| `1773252647932-52647-pre-0-1773252720000` | PRE | 1773252720000 | PRE_NOTIFICATION_POSTED | 2026-03-11T18:12:00.000Z | 0 | PASS |
| `1773252647932-52647-pre-1-1773252900000` | PRE | 1773252900000 | PRE_NOTIFICATION_POSTED | - | - | MISS |
| `1773252647932-52647-pre-2-1773253020000` | PRE | 1773253020000 | PRE_NOTIFICATION_POSTED | - | - | MISS |

## Lane Outputs

- Canonical plan: [canonical_plan.txt](canonical_plan.txt)
- Canonical persistence: [canonical_persistence.txt](canonical_persistence.txt)
- Accelerated mirror: [accelerated_mirror.txt](accelerated_mirror.txt)
- Recovery extension: [recovery_extension.txt](recovery_extension.txt)
- Clock warp: [clock_warp.txt](clock_warp.txt)
