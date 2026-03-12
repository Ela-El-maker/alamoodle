import 'package:flutter/foundation.dart';

enum AlarmEngineMode { legacy, shadowNative }

const AlarmEngineMode kAlarmEngineMode = AlarmEngineMode.shadowNative;
const bool kNativeRingPipelineEnabled = true;
const bool kLegacyEmergencyRingFallbackEnabled = false;
const bool kLegacyDeliveryFallbackEnabled = false;
const bool kLegacyEmergencyRingFallbackDebugOverride = bool.fromEnvironment(
  'LEGACY_EMERGENCY_RING_FALLBACK',
  defaultValue: false,
);

bool get kEffectiveLegacyEmergencyRingFallbackEnabled =>
    kLegacyEmergencyRingFallbackEnabled ||
    (kDebugMode && kLegacyEmergencyRingFallbackDebugOverride);

bool get kUseNativeAlarmCore =>
    kAlarmEngineMode == AlarmEngineMode.shadowNative;
