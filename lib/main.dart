import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import './alarm/config/alarm_engine_mode.dart';
import './core/app_export.dart';
import './services/alarm_notification_service.dart';
import './widgets/custom_error_widget.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

bool shouldHandleLegacyNotificationTap({
  required bool nativeRingPipelineEnabled,
  required bool legacyDeliveryFallbackEnabled,
  required bool legacyEmergencyRingFallbackEnabled,
}) {
  if (!legacyEmergencyRingFallbackEnabled) return false;
  if (nativeRingPipelineEnabled && !legacyDeliveryFallbackEnabled) return false;
  return true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final shouldInitLegacyNotifications =
      kAlarmEngineMode == AlarmEngineMode.legacy ||
      kLegacyDeliveryFallbackEnabled ||
      kEffectiveLegacyEmergencyRingFallbackEnabled;
  if (shouldInitLegacyNotifications) {
    await AlarmNotificationService.instance.initialize();
    await AlarmNotificationService.instance.requestPermissions();
  }

  AlarmNotificationService.instance.onNotificationTap = (payload) {
    // Sprint 2 cutover: native receiver/service/activity is the primary ring path.
    // This callback is retained only for emergency legacy fallback routing.
    if (!shouldHandleLegacyNotificationTap(
      nativeRingPipelineEnabled: kNativeRingPipelineEnabled,
      legacyDeliveryFallbackEnabled: kLegacyDeliveryFallbackEnabled,
      legacyEmergencyRingFallbackEnabled:
          kEffectiveLegacyEmergencyRingFallbackEnabled,
    )) {
      return;
    }

    final parts = payload.split('|');
    final int alarmId = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final String label = parts.length > 1 ? parts[1] : 'Alarm';
    final String sound = parts.length > 2 ? parts[2] : 'Default Alarm';
    final String challenge = parts.length > 3 ? parts[3] : 'None';

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushNamed(
      AppRoutes.alarmRinging,
      arguments: {
        'id': alarmId,
        'name': label,
        'label': label,
        'sound': sound,
        'challenge': challenge,
      },
    );
  };

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'alarmmaster',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
          onGenerateRoute: (settings) {
            if (AppRoutes.routes.containsKey(settings.name)) {
              return MaterialPageRoute(
                builder: AppRoutes.routes[settings.name]!,
                settings: settings,
              );
            }
            return null;
          },
        );
      },
    );
  }
}
