#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ANDROID_DIR="${REPO_ROOT}/android"
PACKAGE_GRADLE="${ANDROID_DIR}/app/build.gradle.kts"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${REPO_ROOT}/docs/evidence/release/${STAMP}"
LOG_FILE="${OUT_DIR}/prepare_android_deploy.log"

WITH_HARNESS=0
SKIP_TESTS=0

usage() {
  cat <<'EOF'
Usage: scripts/release/prepare_android_deploy.sh [options]

Options:
  --with-harness   Run scripts/qa/future_event_cert_phone.sh before release build.
  --skip-tests     Skip flutter/gradle test gates (not recommended for deployment).
  -h, --help       Show this help.

Required signing inputs (one of these methods):
  1) android/key.properties (recommended)
  2) Environment variables:
     ANDROID_KEYSTORE_PATH
     ANDROID_KEYSTORE_PASSWORD
     ANDROID_KEY_ALIAS
     ANDROID_KEY_PASSWORD
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-harness) WITH_HARNESS=1 ;;
    --skip-tests) SKIP_TESTS=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

mkdir -p "${OUT_DIR}"
exec > >(tee "${LOG_FILE}") 2>&1

cd "${REPO_ROOT}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd flutter
require_cmd sha256sum
require_cmd awk
require_cmd sed

has_key_properties=0
if [[ -f "${ANDROID_DIR}/key.properties" ]]; then
  has_key_properties=1
fi

has_env_signing=0
if [[ -n "${ANDROID_KEYSTORE_PATH:-}" && -n "${ANDROID_KEYSTORE_PASSWORD:-}" && -n "${ANDROID_KEY_ALIAS:-}" && -n "${ANDROID_KEY_PASSWORD:-}" ]]; then
  has_env_signing=1
fi

if [[ "${has_key_properties}" -eq 0 && "${has_env_signing}" -eq 0 ]]; then
  echo "Release signing is not configured."
  echo "Create android/key.properties from android/key.properties.example or export signing env vars."
  exit 1
fi

application_id="$(sed -nE 's/^[[:space:]]*applicationId[[:space:]]*=[[:space:]]*\"([^\"]+)\".*/\1/p' "${PACKAGE_GRADLE}" | head -n1)"
if [[ -z "${application_id}" ]]; then
  echo "Failed to detect applicationId from ${PACKAGE_GRADLE}" >&2
  exit 1
fi
echo "applicationId=${application_id}"
if [[ "${application_id}" == com.example.* ]]; then
  echo "WARNING: applicationId is still using com.example.* namespace. Update before production rollout."
fi

if [[ "${SKIP_TESTS}" -eq 0 ]]; then
  echo "==> Running release preflight checks"
  flutter pub get
  flutter analyze
  flutter test
  ./android/gradlew -p android app:compileDebugKotlin app:testDebugUnitTest
else
  echo "==> Skipping test gates (--skip-tests)"
fi

if [[ "${WITH_HARNESS}" -eq 1 ]]; then
  echo "==> Running future-event physical certification harness"
  ./scripts/qa/future_event_cert_phone.sh
fi

echo "==> Building Play Store bundle (AAB)"
flutter build appbundle --release

AAB_PATH="${REPO_ROOT}/build/app/outputs/bundle/release/app-release.aab"
if [[ ! -f "${AAB_PATH}" ]]; then
  echo "Expected AAB not found at ${AAB_PATH}" >&2
  exit 1
fi

cp "${AAB_PATH}" "${OUT_DIR}/app-release.aab"
sha256sum "${OUT_DIR}/app-release.aab" | tee "${OUT_DIR}/app-release.aab.sha256"

{
  echo "timestamp_utc=${STAMP}"
  echo "application_id=${application_id}"
  echo "aab_path=${OUT_DIR}/app-release.aab"
  echo "aab_sha256_file=${OUT_DIR}/app-release.aab.sha256"
  echo "with_harness=${WITH_HARNESS}"
  echo "skip_tests=${SKIP_TESTS}"
  flutter --version | head -n 1
} > "${OUT_DIR}/release_metadata.txt"

echo "==> Release artifact prepared"
echo "Evidence directory: ${OUT_DIR}"
echo "Next: upload ${OUT_DIR}/app-release.aab to Play Console internal testing."
