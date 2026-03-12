# Android Deployment Runbook

## Scope
This runbook prepares and packages the Android app for Play Console deployment using a reproducible local command.

## Prerequisites
1. Release signing configured:
   - Copy `android/key.properties.example` to `android/key.properties`, then fill keystore values.
   - Or export:
     - `ANDROID_KEYSTORE_PATH`
     - `ANDROID_KEYSTORE_PASSWORD`
     - `ANDROID_KEY_ALIAS`
     - `ANDROID_KEY_PASSWORD`
2. Flutter SDK and Android toolchain installed.
3. Production package identity is finalized (`applicationId` should not stay under `com.example.*`).
4. Sprint 6 quality gates satisfied in:
   - [RELEASE_QUALITY_GATES.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/RELEASE_QUALITY_GATES.md)
   - [docs/evidence/sprint6/RESULTS.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/evidence/sprint6/RESULTS.md)

## One-command release prep
Run from repo root:

```bash
./scripts/release/prepare_android_deploy.sh
```

Optional (include physical future-event harness before packaging):

```bash
./scripts/release/prepare_android_deploy.sh --with-harness
```

Optional (not recommended for production):

```bash
./scripts/release/prepare_android_deploy.sh --skip-tests
```

## Outputs
Each run creates:

- `docs/evidence/release/<timestamp>/app-release.aab`
- `docs/evidence/release/<timestamp>/app-release.aab.sha256`
- `docs/evidence/release/<timestamp>/release_metadata.txt`
- `docs/evidence/release/<timestamp>/prepare_android_deploy.log`

## Play Console promotion sequence
1. Upload `app-release.aab` to **Internal testing**.
2. Verify install/upgrade on at least one physical phone.
3. Review pre-launch report (workflow: [PRELAUNCH_REPORT_WORKFLOW.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/PRELAUNCH_REPORT_WORKFLOW.md)).
4. Promote to **Closed testing** only if:
   - `P0 = 0`
   - no unresolved P1 in core ring path
   - critical device-family scenarios pass.
5. Follow staged rollout policy in [BETA_ROLLOUT_PLAN.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/BETA_ROLLOUT_PLAN.md).

## Deployment blockers
Do not deploy if any is true:
1. Signing is missing or fallback debug signing was used.
2. Preflight checks fail (`analyze`, `test`, `unit/integration compile`).
3. Sprint 6 quality gates are not met.
4. Open `P0` exists in [BUG_TRIAGE.md](/home/ela/Work-Force/Mobile-App/alamoodle/docs/BUG_TRIAGE.md).

## Troubleshooting
### Flutter watcher exception during AAB build
If bundle packaging fails or hangs with:

`Caught exception: Already watching path: /.../android`

run a clean release shell sequence:

```bash
./android/gradlew -p android --stop
flutter clean
flutter pub get
./scripts/release/prepare_android_deploy.sh
```

Important:
- Close any active `flutter run`/IDE Flutter daemon sessions before packaging.
- If the issue persists on the same machine, run the release packaging on a clean host/CI runner.
