# Play Pre-launch Report Workflow — Sprint 6

## Candidate Cycle
1. Build release candidate (`RC`) and upload to Internal Testing.
2. Wait for pre-launch report execution.
3. Review report categories:
   - Stability (crash/ANR)
   - Performance
   - Accessibility
   - Device-specific behavior/screenshots
4. Create triage entries for all high-severity findings.
5. Re-upload `RC+1` if blockers found.

## Triage Standard
- Map each finding to `P0/P1/P2`.
- Link finding to `TRIAGE-XXX` entry and evidence log.
- Resolve or explicitly defer with owner + rationale.

## Promotion Rule
- Do not promote to Closed Testing unless high-severity findings are triaged and blockers resolved.
