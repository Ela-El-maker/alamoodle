import 'package:alarmmaster/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Legacy notification tap guardrail', () {
    test('native ring enabled + no legacy delivery fallback => disabled', () {
      final shouldHandle = shouldHandleLegacyNotificationTap(
        nativeRingPipelineEnabled: true,
        legacyDeliveryFallbackEnabled: false,
        legacyEmergencyRingFallbackEnabled: true,
      );
      expect(shouldHandle, isFalse);
    });

    test('legacy emergency fallback disabled => disabled', () {
      final shouldHandle = shouldHandleLegacyNotificationTap(
        nativeRingPipelineEnabled: false,
        legacyDeliveryFallbackEnabled: true,
        legacyEmergencyRingFallbackEnabled: false,
      );
      expect(shouldHandle, isFalse);
    });

    test('legacy mode compatible config can enable callback', () {
      final shouldHandle = shouldHandleLegacyNotificationTap(
        nativeRingPipelineEnabled: false,
        legacyDeliveryFallbackEnabled: true,
        legacyEmergencyRingFallbackEnabled: true,
      );
      expect(shouldHandle, isTrue);
    });
  });
}
