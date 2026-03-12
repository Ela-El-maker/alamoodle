# Sprint 3 Hardening

## Delivered
- Recovery coordinator and app-owned lifecycle receivers for boot/locked-boot/time/package/user-unlock.
- Two-tier Direct Boot policy implemented using device-protected recovery index and post-unlock reconciliation.
- Non-destructive schedule repair expanded to reconcile DB future triggers with active registry.
- Reliability snapshot expanded with direct-boot/channel/full-screen/battery/registry/recovery metadata.
- Native settings navigator and test-alarm runner exposed over typed platform API.
- Diagnostics exporter added with native alarms/triggers/reliability/history payload.
- Flutter reliability screen switched from demo values to native snapshot + native history + fix/test actions.

## API surface updates
- `ReliabilitySnapshotDto` now includes:
  - `directBootReady`
  - `channelHealth`
  - `fullScreenReady`
  - `batteryOptimizationRisk`
  - `scheduleRegistryHealth`
  - `lastRecoveryReason`
  - `lastRecoveryAtUtcMillis`
  - `lastRecoveryStatus`
- New host API methods:
  - `getRecentHistory(limit, alarmId)`
  - `exportDiagnostics()`
  - `runTestAlarm()`
  - `openSystemSettings(target)`

## Remaining non-goals (Sprint 4+)
- Full stats dashboard replacement with native aggregates.
- Onboarding simulation replacement.
- OEM guidance wizard and broader analytics productization.
