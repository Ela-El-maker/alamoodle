# Beta Rollout Plan — Sprint 6

## Track Progression
1. Internal Testing (team + QA)
2. Closed Testing (trusted external cohort)
3. Staged Production rollout

## Staged Rollout Percentages
- Stage 1: 5%
- Stage 2: 20%
- Stage 3: 50%
- Stage 4: 100%

Promotion requires all release quality gates to remain green.

## Rollback Triggers
- New `P0` in core alarm reliability path.
- Significant verified increase in missed alarms on certified devices.
- High-severity pre-launch/vitals issue without mitigation.

## On-call Ownership
- Release owner: Android engineer
- Backup owner: Flutter engineer
- Response SLA: acknowledge within 1 hour during rollout windows.
