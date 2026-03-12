# Future Event Certification Results

- Run: `20260311T135329Z`
- Package: `com.example.alarmmaster`
- Overall: **PASS**
- Device env: [phone_env.txt](phone_env.txt)
- Logcat: [logcat.txt](logcat.txt)
- Events: [events.log](events.log)

## Lane Status

| Lane | Exit Code | Verdict |
|---|---:|---|
| canonical_plan | 0 | PASS |
| canonical_persistence | 0 | PASS |
| accelerated_mirror | 0 | PASS |
| recovery_extension | 0 | PASS |
| clock_warp | 0 | PASS |

## Canonical Trigger Plan (Next Month)

| Trigger ID | Kind | Scheduled UTC (ms) | Verdict |
|---|---:|---:|---|
| `1773237333715-37333-main-0-1775815200000` | MAIN | 1775815200000 | PLAN_OK |
| `1773237333715-37333-pre-0-1775556000000` | PRE | 1775556000000 | PLAN_OK |
| `1773237333715-37333-pre-1-1775728800000` | PRE | 1775728800000 | PLAN_OK |
| `1773237333715-37333-pre-2-1775811600000` | PRE | 1775811600000 | PLAN_OK |

## Accelerated Delivery Validation

| Trigger ID | Kind | Scheduled UTC (ms) | Expected Event | Observed Event Time | Delay (ms) | Verdict |
|---|---:|---:|---|---|---:|---|
| - | - | - | - | - | - | NO_DATA |

## Lane Outputs

- Canonical plan: [canonical_plan.txt](canonical_plan.txt)
- Canonical persistence: [canonical_persistence.txt](canonical_persistence.txt)
- Accelerated mirror: [accelerated_mirror.txt](accelerated_mirror.txt)
- Recovery extension: [recovery_extension.txt](recovery_extension.txt)
- Clock warp: [clock_warp.txt](clock_warp.txt)
