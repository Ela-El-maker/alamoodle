import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralized haptic feedback service with named patterns for different
/// interaction contexts throughout the alarm app.
class HapticService {
  HapticService._();

  // ─── Form Validation ────────────────────────────────────────────────────────

  /// Triggered when a form field has a validation error (e.g. label too short,
  /// no repeat days selected, past-time warning).
  static Future<void> formValidationError() async {
    if (kIsWeb) return;
    // Double vibrate pattern: short-pause-short to signal "wrong"
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Triggered when a form field warning appears (non-blocking, e.g. past time).
  static Future<void> formValidationWarning() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }

  // ─── Sound Preview ──────────────────────────────────────────────────────────

  /// Triggered when the user starts previewing a sound.
  static Future<void> soundPreviewPlay() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }

  /// Triggered when the user stops a sound preview.
  static Future<void> soundPreviewStop() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }

  /// Triggered when a sound is selected (row tap).
  static Future<void> soundSelected() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }

  // ─── Button Presses ─────────────────────────────────────────────────────────

  /// Light tap — for low-priority actions (cancel, close, chip select).
  static Future<void> buttonLight() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium tap — for standard actions (save, toggle, row tap).
  static Future<void> buttonMedium() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap — for critical actions (dismiss alarm, delete).
  static Future<void> buttonHeavy() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection click — for toggles, chips, and pickers.
  static Future<void> selectionClick() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }

  // ─── Snooze Feedback ────────────────────────────────────────────────────────

  /// Triggered when snooze is activated — gentle triple pulse.
  static Future<void> snoozeActivated() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Triggered on snooze success confirmation.
  static Future<void> snoozeSuccess() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.heavyImpact();
  }

  // ─── Challenge Interactions ─────────────────────────────────────────────────

  /// Triggered on each keypad tap in math/challenge screens.
  static Future<void> challengeKeyTap() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }

  /// Triggered when the user submits a correct challenge answer.
  static Future<void> challengeCorrect() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Triggered when the user submits a wrong challenge answer.
  static Future<void> challengeWrong() async {
    if (kIsWeb) return;
    // Rapid triple buzz to signal error
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.heavyImpact();
  }

  /// Triggered on memory tile flip.
  static Future<void> challengeTileFlip() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
  }

  /// Triggered on memory tile match.
  static Future<void> challengeTileMatch() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  // ─── Alarm Ringing ──────────────────────────────────────────────────────────

  /// Triggered when the alarm ringing screen opens.
  static Future<void> alarmRinging() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.heavyImpact();
  }

  /// Triggered when the alarm is dismissed.
  static Future<void> alarmDismissed() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
  }
}
