# Build Roadmap (Sprint 1-6)

## Objective
Introduce a native Android alarm core behind the existing Flutter UI while keeping Flutter notification ringing as temporary fallback.

## Engine modes
- `legacy`: Flutter notifications/storage path only.
- `shadow_native`: Flutter UI backed by native Room + AlarmManager, with Flutter notification ringing fallback.

Sprint default from Sprint 1 onward: `shadow_native`.

## Migration boundaries
- Flutter still owns: onboarding/dashboard/create/edit/detail/reliability/stats UI.
- Native Android now owns: typed alarm persistence, trigger planning, exact scheduling, reliability snapshot source.
- Flutter legacy ringing remains until Sprint 2 native receiver->service->alarm activity ring pipeline.

## Sprint 2 state
- Native ring execution pipeline is primary (`receiver -> foreground service -> native alarm activity`).
- Flutter ringing route is retained only for emergency/manual fallback.

## Sprint 3 state
- Recovery/repair ownership is native and coordinated via `RecoveryCoordinator`.
- App-owned receivers handle boot, locked boot, timezone/time, package replaced, and user-unlock reconciliation.
- Reliability and history surfaces now read native diagnostics/state instead of static demo assumptions.

## Sprint 4 state
- Native bundled sound catalog is exposed to Flutter with real preview controls.
- Alarm creation/detail now persist sound/policy fields through typed native APIs.
- Stats dashboard is native-backed via materialized daily aggregates.
- Onboarding permission/test ring flow is native-truth based (no simulation path).
- Legacy emergency ring fallback defaults to disabled (debug override only).

## Sprint 5 state
- Recurrence and reminder-bundle fields are part of typed alarm DTOs and persisted in native storage.
- Planner integrates a Kotlin-first recurrence engine with a sealed native adapter seam.
- Template, backup/restore (replace-existing default), OEM guidance, and planned-trigger preview APIs are exposed over Pigeon.
- Native backup payload includes alarms, templates, settings-adjacent policy fields, and daily stats summaries.
- Flutter alarm authoring flow supports template apply/save, reminder-bundle offsets, recurrence exclusions, and planned-trigger preview from native planning.
- Reliability and onboarding surfaces include native OEM guidance, plus backup export/import actions through native APIs.

## Sprint 6 state
- Release hardening and physical-device certification docs are now in place:
  - QA matrix, device matrix, triage board, quality gates, runbook, prelaunch workflow, vitals monitoring, rollout plan, support limits.
- Diagnostics export now includes trace + build + device metadata for support triage correlation.
- OEM guidance copy is tuned for non-absolute trust messaging and includes Transsion-class device guidance.
- Reliability/onboarding explicitly communicate hard platform limits (force-stop, powered-off, OEM restrictions).
