# Current Limitations

## Sprint 4 scope boundaries
- iOS native parity remains out of scope.
- Bundled native sound catalog is implemented; streaming/import catalogs remain out of scope.
- QR challenge is implemented in production path; steps challenge is deferred and non-selectable in production configuration.
- Legacy Flutter ringing route remains compatibility-only and emergency fallback is disabled by default.

## Sprint 5 scope boundaries
- Recurrence scope is core rules + exclusions; business-day adjustment remains deferred.
- Restore defaults to `Replace Existing`; custom merge policies are not yet exposed.
- Backup payload includes daily stats summaries, not full raw history.
- Widgets are deferred beyond Sprint 6.

## Sprint 6 release-hardening status
- Physical certification on all three required device families (Pixel, Samsung, aggressive OEM) is not yet complete in this workspace.
- Current connected physical device is an aggressive OEM (Infinix X658E); remaining matrix execution requires additional phones.
- Pre-launch report and Android vitals review must be run against an uploaded release candidate in Play Console.
- No crash telemetry SDK (Crashlytics/Sentry) is introduced in this sprint by design; monitoring relies on Play vitals + diagnostics export.

## Explicit policy in `shadow_native`
- Source of truth is native only: Room + native planner + native scheduler + native ring session state.
- Native ring execution pipeline is primary: `AlarmManager -> AlarmTriggerReceiver -> AlarmRingingService -> AlarmActivity`.
- Recovery ownership is app-native: boot/time/package/startup reconciliation routes through `RecoveryCoordinator`.
- Direct Boot is two-tier: pre-unlock minimal survivability restore, post-unlock full Room reconciliation.
- Legacy Flutter services are compatibility-only and non-authoritative for storage/scheduling.

## Known risks to monitor
- OEM battery managers can still aggressively kill or delay behavior despite correct platform APIs.
- Full-screen alarm launch behavior can vary by user/device policy and must be validated per device class.
- Force-stop and powered-off device behavior remain hard platform limits; reliability UI should continue to explain these constraints.
- Camera availability/permission denial can block QR challenge completion for challenge-gated alarms; product UX should continue to offer clear retry/fallback guidance.
