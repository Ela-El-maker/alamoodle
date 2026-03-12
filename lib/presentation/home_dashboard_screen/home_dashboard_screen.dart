import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_bottom_bar.dart';
import './home_dashboard_screen_initial_page.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  HomeDashboardScreenState createState() => HomeDashboardScreenState();
}

class HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int currentIndex = 0;

  final List<String> routes = [
    AppRoutes.homeDashboard,
    AppRoutes.alarmCreation,
    AppRoutes.statsDashboard,
    AppRoutes.reliabilitySettings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        initialRoute: AppRoutes.homeDashboard,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.homeDashboard || '/':
              return MaterialPageRoute(
                builder: (context) => const HomeDashboardScreenInitialPage(),
                settings: settings,
              );
            default:
              if (AppRoutes.routes.containsKey(settings.name)) {
                return MaterialPageRoute(
                  builder: AppRoutes.routes[settings.name]!,
                  settings: settings,
                );
              }
              return null;
          }
        },
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (!AppRoutes.routes.containsKey(routes[index])) {
            return;
          }
          if (currentIndex != index) {
            setState(() => currentIndex = index);
            navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
      ),
    );
  }
}
