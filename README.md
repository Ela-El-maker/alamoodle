# Alarmmaster

Alarmmaster is a reliability-focused, Android-first alarm app designed to work even under process death, device reboot, and strict OEM background limits. Built with Flutter for cross-platform support.

---

## 🚀 Features

- Reliable alarm scheduling and ringing
- 12-hour & 24-hour time formats
- One-time and recurring alarms
- Custom labels, sounds, snooze, and nag mode
- Daily streak tracking and stats
- Modern, dark-themed UI

---

## 📱 Screenshots

<p align="center">
  <img src="docs/evidence/screenshots/photo_1_2026-03-12_19-09-30.jpg" alt="Alarm creation 24-hour" width="250" />
  <img src="docs/evidence/screenshots/photo_5_2026-03-12_19-09-30.jpg" alt="Alarm creation 12-hour with date" width="250" />
  <img src="docs/evidence/screenshots/photo_2_2026-03-12_19-09-30.jpg" alt="Alarm details full options" width="250" />
  <img src="docs/evidence/screenshots/photo_8_2026-03-12_19-09-30.jpg" alt="Alarm ringing screen" width="250" />
  <img src="docs/evidence/screenshots/photo_6_2026-03-12_19-09-30.jpg" alt="My Alarms list" width="250" />
  <img src="docs/evidence/screenshots/photo_3_2026-03-12_19-09-30.jpg" alt="Daily Streaks stats" width="250" />
</p>

---

## 🗂 Project Structure

- `lib/` — Flutter UI, controllers, bridge models
- `android/` — Native alarm domain, scheduler, service, recovery
- `scripts/qa/` — QA harnesses (future-event certification)
- `scripts/release/` — Release packaging automation
- `docs/` — Roadmap, QA matrices, release gates, runbooks

---

## 🛠 Local Setup

```bash
flutter pub get
flutter run
```

---

## ✅ Quality Gates

```bash
flutter analyze
flutter test
./android/gradlew -p android app:compileDebugKotlin app:testDebugUnitTest
```

---

## 🚀 Release Preparation

See `docs/DEPLOYMENT_RUNBOOK.md` and use:

```bash
./scripts/release/prepare_android_deploy.sh
```

---

## ⚠️ Support Limitations & Platform Constraints

### Hard Platform Limits

- Force-stopped apps may not receive alarm execution events until reopened.
- Powered-off devices cannot execute alarms until the OS is running again.
- OEM battery/background policies can delay alarms despite correct app settings.

### User Guidance

- Keep exact alarm and notification permissions enabled.
- Disable battery optimization for the app if reliability is degraded.
- Run a test alarm after changing device power settings.

### Support Playbook

- Request diagnostics export JSON from Reliability screen.
- Confirm device manufacturer/model and Android version.
- Check whether issue reproduces after app/device restart and settings validation.
