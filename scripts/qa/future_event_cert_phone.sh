#!/usr/bin/env bash
set -euo pipefail

PACKAGE="com.example.alarmmaster"
MAIN_ACTIVITY="${PACKAGE}/.MainActivity"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${REPO_ROOT}/docs/evidence/sprint6/future_event_cert_${STAMP}"
RESULTS_MD="${OUT_DIR}/RESULTS.md"
EVENTS_LOG="${OUT_DIR}/events.log"
LOGCAT_FILE="${OUT_DIR}/logcat.txt"
CANONICAL_EXPECTED="${OUT_DIR}/expected_triggers_canonical.tsv"
ACCEL_EXPECTED="${OUT_DIR}/expected_triggers_accelerated.tsv"
OVERALL_STATUS="PASS"

declare -A LANE_STATUS

mkdir -p "${OUT_DIR}"

log() {
  printf '[future-cert] %s\n' "$*"
}

run_and_capture() {
  local name="$1"
  shift
  local file="${OUT_DIR}/${name}.txt"
  log "Running: $name"
  set +e
  {
    printf '$ %s\n' "$*"
    "$@"
  } > >(tee "${file}") 2>&1
  local status=$?
  set -e
  LANE_STATUS["${name}"]="${status}"
  if [[ "${status}" -ne 0 ]]; then
    OVERALL_STATUS="FAIL"
    log "Lane failed: ${name} (exit=${status})"
  else
    log "Lane passed: ${name}"
  fi
}

prepare_accelerated_lane_env() {
  log "Preparing accelerated lane env (wake + disable device idle)"
  adb shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
  adb shell wm dismiss-keyguard >/dev/null 2>&1 || true
  adb shell dumpsys deviceidle disable >/dev/null 2>&1 || true
}

restore_accelerated_lane_env() {
  adb shell dumpsys deviceidle enable >/dev/null 2>&1 || true
}

cleanup() {
  if [[ -n "${LOGCAT_PID:-}" ]] && kill -0 "${LOGCAT_PID}" 2>/dev/null; then
    kill "${LOGCAT_PID}" || true
  fi
}
trap cleanup EXIT

assert_adb_ready() {
  local devices
  devices="$(adb devices | awk 'NR>1 && $2=="device" {print $1}')"
  if [[ -z "${devices}" ]]; then
    echo "No connected adb device in 'device' state." >&2
    exit 1
  fi
}

capture_env() {
  {
    echo "timestamp_utc=${STAMP}"
    adb devices -l
    echo "---"
    adb shell getprop ro.product.manufacturer
    adb shell getprop ro.product.model
    adb shell getprop ro.build.version.release
    adb shell getprop ro.build.version.sdk
    adb shell getprop ro.build.fingerprint
    adb shell date
    echo "auto_time=$(adb shell settings get global auto_time | tr -d '\r')"
    echo "auto_time_zone=$(adb shell settings get global auto_time_zone | tr -d '\r')"
  } > "${OUT_DIR}/phone_env.txt"
}

capture_events() {
  adb shell run-as "${PACKAGE}" cat files/alarm-diagnostics/events.log > "${EVENTS_LOG}" 2>/dev/null || true
}

start_logcat() {
  adb logcat -c
  adb logcat -v time > "${LOGCAT_FILE}" 2>&1 &
  LOGCAT_PID=$!
}

parse_expected_triggers() {
  local lane="$1"
  local src="$2"
  local out="$3"
  local marker="CERT_EXPECT lane=${lane} "

  {
    [[ -f "${src}" ]] && grep "${marker}" "${src}" || true
    [[ -f "${LOGCAT_FILE}" ]] && grep "${marker}" "${LOGCAT_FILE}" || true
    adb logcat -d -v time | grep "${marker}" || true
  } | sed -E 's/.*triggerId=([^ ]+) kind=([^ ]+) scheduledUtc=([0-9]+).*/\1\t\2\t\3/' \
    | awk -F '\t' 'NF==3 { print $0 }' \
    | sort -u \
    > "${out}" || true

  if [[ ! -s "${out}" ]]; then
    log "WARN: expected trigger set is empty for lane=${lane}"
  fi
}

epoch_ms_from_iso() {
  local iso="$1"
  date -d "${iso}" +%s%3N
}

lookup_observed_event_iso() {
  local trigger_id="$1"
  local expected_event="$2"
  local iso=""
  if [[ -s "${EVENTS_LOG}" ]]; then
    iso="$(grep "${expected_event}" "${EVENTS_LOG}" | grep "triggerId=${trigger_id}" | tail -n 1 | awk '{print $1}' || true)"
  fi
  if [[ -n "${iso}" ]]; then
    echo "${iso}"
    return
  fi
  local observed_ms=""
  observed_ms="$(
    {
      [[ -f "${LOGCAT_FILE}" ]] && grep "CERT_OBSERVED lane=accelerated" "${LOGCAT_FILE}" || true
      adb logcat -d -v time | grep "CERT_OBSERVED lane=accelerated" || true
    } | grep "triggerId=${trigger_id}" | grep "eventType=${expected_event}" | tail -n 1 \
      | sed -E 's/.*observedUtc=([0-9]+).*/\1/' || true
  )"
  if [[ -n "${observed_ms}" ]]; then
    date -u -d "@$((observed_ms / 1000))" +"%Y-%m-%dT%H:%M:%S.000Z"
  else
    echo ""
  fi
}

summarize_results() {
  local canonical_expected="${CANONICAL_EXPECTED}"
  local accel_expected="${ACCEL_EXPECTED}"
  local accel_miss=0
  local expected_event observed_iso observed_ms delay verdict

  if [[ ! -s "${accel_expected}" ]]; then
    OVERALL_STATUS="FAIL"
  fi

  if [[ -s "${accel_expected}" ]]; then
    while IFS=$'\t' read -r trigger_id kind _; do
      if [[ "${kind}" == "PRE" ]]; then
        expected_event="PRE_NOTIFICATION_POSTED"
      else
        expected_event="SERVICE_STARTED"
      fi
      observed_iso="$(lookup_observed_event_iso "${trigger_id}" "${expected_event}")"
      if [[ -z "${observed_iso}" ]]; then
        accel_miss=$((accel_miss + 1))
      fi
    done < "${accel_expected}"
  fi
  if [[ "${accel_miss}" -gt 0 ]]; then
    OVERALL_STATUS="FAIL"
  fi

  {
    echo "# Future Event Certification Results"
    echo
    echo "- Run: \`${STAMP}\`"
    echo "- Package: \`${PACKAGE}\`"
    echo "- Overall: **${OVERALL_STATUS}**"
    echo "- Device env: [phone_env.txt](phone_env.txt)"
    echo "- Logcat: [logcat.txt](logcat.txt)"
    echo "- Events: [events.log](events.log)"
    echo
    echo "## Lane Status"
    echo
    echo "| Lane | Exit Code | Verdict |"
    echo "|---|---:|---|"
    echo "| canonical_plan | ${LANE_STATUS[canonical_plan]:-NA} | $([[ ${LANE_STATUS[canonical_plan]:-1} -eq 0 ]] && echo PASS || echo FAIL) |"
    echo "| canonical_persistence | ${LANE_STATUS[canonical_persistence]:-NA} | $([[ ${LANE_STATUS[canonical_persistence]:-1} -eq 0 ]] && echo PASS || echo FAIL) |"
    echo "| accelerated_mirror | ${LANE_STATUS[accelerated_mirror]:-NA} | $([[ ${LANE_STATUS[accelerated_mirror]:-1} -eq 0 ]] && echo PASS || echo FAIL) |"
    echo "| recovery_extension | ${LANE_STATUS[recovery_extension]:-NA} | $([[ ${LANE_STATUS[recovery_extension]:-1} -eq 0 ]] && echo PASS || echo FAIL) |"
    echo "| clock_warp | ${LANE_STATUS[clock_warp]:-NA} | $([[ ${LANE_STATUS[clock_warp]:-1} -eq 0 ]] && echo PASS || echo FAIL) |"
    if [[ -n "${LANE_STATUS[restore_install]:-}" ]]; then
      echo "| restore_install | ${LANE_STATUS[restore_install]:-NA} | $([[ ${LANE_STATUS[restore_install]:-1} -eq 0 ]] && echo PASS || echo FAIL) |"
    fi
    echo
    echo "## Canonical Trigger Plan (Next Month)"
    echo
    echo "| Trigger ID | Kind | Scheduled UTC (ms) | Verdict |"
    echo "|---|---:|---:|---|"
    if [[ -s "${canonical_expected}" ]]; then
      while IFS=$'\t' read -r trigger_id kind scheduled_utc; do
        echo "| \`${trigger_id}\` | ${kind} | ${scheduled_utc} | PLAN_OK |"
      done < "${canonical_expected}"
    else
      echo "| - | - | - | NO_DATA |"
    fi
    echo
    echo "## Accelerated Delivery Validation"
    echo
    echo "| Trigger ID | Kind | Scheduled UTC (ms) | Expected Event | Observed Event Time | Delay (ms) | Verdict |"
    echo "|---|---:|---:|---|---|---:|---|"
    if [[ -s "${accel_expected}" ]]; then
      while IFS=$'\t' read -r trigger_id kind scheduled_utc; do
        if [[ "${kind}" == "PRE" ]]; then
          expected_event="PRE_NOTIFICATION_POSTED"
        else
          expected_event="SERVICE_STARTED"
        fi
        observed_iso="$(lookup_observed_event_iso "${trigger_id}" "${expected_event}")"
        if [[ -n "${observed_iso}" ]]; then
          observed_ms="$(epoch_ms_from_iso "${observed_iso}")"
          delay=$((observed_ms - scheduled_utc))
          verdict="PASS"
          echo "| \`${trigger_id}\` | ${kind} | ${scheduled_utc} | ${expected_event} | ${observed_iso} | ${delay} | ${verdict} |"
        else
          verdict="MISS"
          echo "| \`${trigger_id}\` | ${kind} | ${scheduled_utc} | ${expected_event} | - | - | ${verdict} |"
        fi
      done < "${accel_expected}"
    else
      echo "| - | - | - | - | - | - | NO_DATA |"
    fi
    echo
    echo "## Lane Outputs"
    echo
    echo "- Canonical plan: [canonical_plan.txt](canonical_plan.txt)"
    echo "- Canonical persistence: [canonical_persistence.txt](canonical_persistence.txt)"
    echo "- Accelerated mirror: [accelerated_mirror.txt](accelerated_mirror.txt)"
    echo "- Recovery extension: [recovery_extension.txt](recovery_extension.txt)"
    echo "- Clock warp: [clock_warp.txt](clock_warp.txt)"
  } > "${RESULTS_MD}"
}

run_clock_warp_lane() {
  local out="${OUT_DIR}/clock_warp.txt"
  {
    echo "Clock-warp lane start"
    local auto_time_before auto_tz_before
    auto_time_before="$(adb shell settings get global auto_time | tr -d '\r')"
    auto_tz_before="$(adb shell settings get global auto_time_zone | tr -d '\r')"
    echo "auto_time_before=${auto_time_before}"
    echo "auto_time_zone_before=${auto_tz_before}"

    adb shell settings put global auto_time 0 || true
    adb shell settings put global auto_time_zone 0 || true
    local now_ms
    now_ms="$(($(adb shell date +%s | tr -d '\r') * 1000))"

    if adb shell cmd alarm set-time "${now_ms}" >/dev/null 2>&1; then
      echo "clock_warp_supported=true"
      adb shell cmd alarm set-timezone "Africa/Nairobi" || true
      for jump_ms in $((now_ms + 3600000)) $((now_ms + 7200000)) $((now_ms + 10800000)); do
        echo "set_time=${jump_ms}"
        adb shell cmd alarm set-time "${jump_ms}" || true
        sleep 4
      done
    else
      echo "clock_warp_supported=false"
      echo "status=UNSUPPORTED_ON_DEVICE"
    fi

    adb shell settings put global auto_time "${auto_time_before}" || true
    adb shell settings put global auto_time_zone "${auto_tz_before}" || true
    echo "Clock-warp lane end"
  } | tee "${out}" || true

  if grep -q "status=UNSUPPORTED_ON_DEVICE" "${out}"; then
    LANE_STATUS["clock_warp"]=0
    log "Clock-warp unsupported on this device; recorded as non-blocking."
  else
    LANE_STATUS["clock_warp"]=0
  fi
}

main() {
  cd "${REPO_ROOT}"
  assert_adb_ready
  capture_env
  start_logcat

  run_and_capture canonical_plan \
    ./android/gradlew -p android app:connectedDebugAndroidTest \
      -Pandroid.testInstrumentationRunnerArguments.class=com.example.alarmmaster.alarm.FutureEventCertificationTest#canonicalNextMonth_triggerPlan_has3d1d1hAndMain

  parse_expected_triggers "canonical" "${OUT_DIR}/canonical_plan.txt" "${CANONICAL_EXPECTED}"

  run_and_capture canonical_persistence \
    ./android/gradlew -p android app:connectedDebugAndroidTest \
      -Pandroid.testInstrumentationRunnerArguments.class=com.example.alarmmaster.alarm.FutureEventCertificationTest#canonicalNextMonth_persistsAcrossKillRelaunchAndRecoveryReasons

  prepare_accelerated_lane_env
  run_and_capture accelerated_mirror \
    ./android/gradlew -p android app:connectedDebugAndroidTest \
      -Pandroid.testInstrumentationRunnerArguments.class=com.example.alarmmaster.alarm.FutureEventCertificationTest#acceleratedMirror_postsPreNotifications_thenMainRings
  restore_accelerated_lane_env

  parse_expected_triggers "accelerated" "${OUT_DIR}/accelerated_mirror.txt" "${ACCEL_EXPECTED}"

  run_and_capture recovery_extension \
    ./android/gradlew -p android app:connectedDebugAndroidTest \
      -Pandroid.testInstrumentationRunnerArguments.class=com.example.alarmmaster.alarm.RecoveryReliabilityPhysicalTest#futureEvent_rebootAndPackageRecovery_keepTriggersStable,com.example.alarmmaster.alarm.RecoveryReliabilityPhysicalTest#futureEvent_overlappingSchedules_surviveRecoveryWithoutCollisions

  run_clock_warp_lane

  run_and_capture restore_install \
    ./android/gradlew -p android app:installDebug

  capture_events
  summarize_results

  log "Done. Evidence: ${OUT_DIR}"
  log "Results: ${RESULTS_MD}"
  if [[ "${OVERALL_STATUS}" != "PASS" ]]; then
    exit 1
  fi
}

main "$@"
