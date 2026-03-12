import 'package:alarmmaster/presentation/alarm_creation_screen/alarm_creation_screen.dart';
import 'package:alarmmaster/presentation/alarm_detail_screen/alarm_detail_screen.dart';
import 'package:alarmmaster/presentation/alarm_ringing_screen/alarm_ringing_screen.dart';
import 'package:alarmmaster/presentation/challenge_screen/challenge_screen.dart';
import 'package:alarmmaster/presentation/home_dashboard_screen/home_dashboard_screen.dart';
import 'package:alarmmaster/presentation/home_dashboard_screen/home_dashboard_screen_initial_page.dart';
import 'package:alarmmaster/presentation/onboarding_flow_screen/onboarding_flow_screen.dart';
import 'package:alarmmaster/presentation/reliability_settings_screen/reliability_settings_screen.dart';
import 'package:alarmmaster/presentation/sound_picker_screen/sound_picker_screen.dart';
import 'package:alarmmaster/presentation/stats_dashboard_screen/stats_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <_Viewport>[
    _Viewport(name: 'small', size: Size(320, 568)),
    _Viewport(name: 'medium', size: Size(390, 844)),
    _Viewport(name: 'large', size: Size(800, 1280)),
  ];

  final screens = <_ScreenCase>[
    const _ScreenCase('home_dashboard', HomeDashboardScreen.new),
    const _ScreenCase(
      'home_dashboard_initial_page',
      HomeDashboardScreenInitialPage.new,
    ),
    const _ScreenCase('alarm_creation', AlarmCreationScreen.new),
    const _ScreenCase('alarm_detail', AlarmDetailScreen.new),
    const _ScreenCase('alarm_ringing', AlarmRingingScreen.new),
    const _ScreenCase('challenge', ChallengeScreen.new),
    const _ScreenCase('sound_picker', SoundPickerScreen.new),
    const _ScreenCase('reliability_settings', ReliabilitySettingsScreen.new),
    const _ScreenCase('stats_dashboard', StatsDashboardScreen.new),
    const _ScreenCase('onboarding_flow', OnboardingFlowScreen.new),
  ];

  for (final screen in screens) {
    testWidgets('responsive audit: ${screen.name}', (tester) async {
      for (final viewport in viewports) {
        final errors = await _renderAndCollectLayoutErrors(
          tester,
          viewport: viewport,
          child: screen.builder(),
        );
        expect(
          errors,
          isEmpty,
          reason:
              'Layout/render errors on ${screen.name} @ ${viewport.name}: ${errors.join('\n')}',
        );
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 30));
    });
  }
}

Future<List<String>> _renderAndCollectLayoutErrors(
  WidgetTester tester, {
  required _Viewport viewport,
  required Widget child,
}) async {
  final binding = tester.binding;
  final dispatcher = binding.platformDispatcher;
  final originalOnError = FlutterError.onError;
  final captured = <String>[];

  FlutterError.onError = (details) {
    final description = details.exceptionAsString();
    if (_isLayoutError(description)) {
      captured.add(description);
    }
    originalOnError?.call(details);
  };

  await binding.setSurfaceSize(viewport.size);
  dispatcher.views.first.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          home: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child,
          ),
        );
      },
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));

  dynamic pendingException;
  while ((pendingException = tester.takeException()) != null) {
    final description = pendingException.toString();
    if (_isLayoutError(description)) {
      captured.add(description);
    }
  }

  await binding.setSurfaceSize(null);
  FlutterError.onError = originalOnError;
  return captured;
}

bool _isLayoutError(String message) {
  return message.contains('A RenderFlex overflowed') ||
      message.contains('A RenderViewport overflowed') ||
      message.contains('was given an infinite size during layout') ||
      message.contains('BoxConstraints forces an infinite') ||
      message.contains('RenderBox was not laid out') ||
      message.contains('Vertical viewport was given unbounded height') ||
      message.contains('Horizontal viewport was given unbounded width');
}

class _Viewport {
  const _Viewport({required this.name, required this.size});

  final String name;
  final Size size;
}

class _ScreenCase {
  const _ScreenCase(this.name, this.builder);

  final String name;
  final Widget Function() builder;
}
