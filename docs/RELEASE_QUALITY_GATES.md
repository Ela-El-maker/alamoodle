# Release Quality Gates — Sprint 6

## Hard Gates (Must Pass)
1. `P0 open = 0` in [BUG_TRIAGE.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/BUG_TRIAGE.md).
2. No unresolved `P1` in core path:
   - trigger -> receiver -> foreground service -> alarm activity -> dismiss/snooze.
3. `Critical` scenarios in [QA_MATRIX.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/QA_MATRIX.md) pass on all required devices (D1 Pixel + D2 Samsung + D3 aggressive OEM).
4. Pre-launch report high-severity issues triaged before promotion.
5. Automated checks pass:
   - `flutter analyze`
   - `flutter test`
   - `./android/gradlew -p android app:compileDebugKotlin app:testDebugUnitTest`
6. Reliability certification evidence exists for:
   - QA-003 (recents clear),
   - QA-020/QA-021 (reboot + locked-boot reconciliation),
   - QA-033/QA-039/QA-040 (startup sanity),
   - QA-034/QA-035/QA-036 (long-horizon persistence).

## Soft Gates (Track and Improve)
- Crash-free and ANR trends stable in testing period.
- OEM guidance validated on at least one aggressive OEM + Samsung.
- Support limitations published and linked from reliability surfaces.

## Release Hold Rules
- Any new `P0` during rollout -> pause rollout immediately.
- Significant regression in alarm firing reliability on required devices -> rollback candidate.
