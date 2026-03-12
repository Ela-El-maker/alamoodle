import 'package:flutter/material.dart';
import '../presentation/alarm_creation_screen/alarm_creation_screen.dart';
import '../presentation/home_dashboard_screen/home_dashboard_screen.dart';
import '../presentation/alarm_ringing_screen/alarm_ringing_screen.dart';
import '../presentation/challenge_screen/challenge_screen.dart';
import '../presentation/alarm_detail_screen/alarm_detail_screen.dart';
import '../presentation/sound_picker_screen/sound_picker_screen.dart';
import '../presentation/reliability_settings_screen/reliability_settings_screen.dart';
import '../presentation/stats_dashboard_screen/stats_dashboard_screen.dart';
import '../presentation/streak_details_screen/streak_details_screen.dart';
import '../presentation/onboarding_flow_screen/onboarding_flow_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String alarmCreation = '/alarm-creation-screen';
  static const String homeDashboard = '/home-dashboard-screen';
  static const String alarmRinging = '/alarm-ringing-screen';
  static const String challengeScreen = '/challenge-screen';
  static const String alarmDetail = '/alarm-detail-screen';
  static const String soundPicker = '/sound-picker-screen';
  static const String reliabilitySettings = '/reliability-settings-screen';
  static const String statsDashboard = '/stats-dashboard-screen';
  static const String streakDetails = '/streak-details-screen';
  static const String onboardingFlow = '/onboarding-flow-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const HomeDashboardScreen(),
    alarmCreation: (context) => const AlarmCreationScreen(),
    homeDashboard: (context) => const HomeDashboardScreen(),
    alarmRinging: (context) => const AlarmRingingScreen(),
    challengeScreen: (context) => const ChallengeScreen(),
    alarmDetail: (context) => const AlarmDetailScreen(),
    soundPicker: (context) => const SoundPickerScreen(),
    reliabilitySettings: (context) => const ReliabilitySettingsScreen(),
    statsDashboard: (context) => const StatsDashboardScreen(),
    streakDetails: (context) => const StreakDetailsScreen(),
    onboardingFlow: (context) => const OnboardingFlowScreen(),
  };
}
