# Android Vitals Monitoring Plan — Sprint 6

## Signals Tracked
- Crash rate
- ANR rate
- User-perceived LMK trend

## Ownership
- Primary: Android engineer on release duty.
- Secondary: Flutter engineer for user-visible regressions.

## Cadence
- Daily during Internal Testing week.
- Daily for first 7 days of Closed Testing.
- Twice daily during staged production rollout.

## Escalation Thresholds
- Any sudden crash/ANR spike in alarm flow -> open `P0` triage.
- Repeated LMK-related reliability complaints -> open `P1` investigation.
- Any regression tied to core alarm execution path -> rollout hold until reviewed.

## Incident Workflow
1. Capture vitals signal and affected versions.
2. Export in-app diagnostics from affected devices.
3. Link to `TRIAGE-XXX`.
4. Decide: hotfix, rollback, or continue with mitigation.
