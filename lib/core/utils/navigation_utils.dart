import 'package:flutter/material.dart';

class AppDestination {
  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    required this.routeName,
    required this.appBarTitle,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final String routeName;
  final String appBarTitle;
}

class AppNavigationUtils {
  static const int dashboardTabIndex = 0;
  static const int attendanceTabIndex = 1;
  static const int qrTabIndex = 2;
  static const int statisticsTabIndex = 3;
  static const int settingsTabIndex = 4;

  static const String dashboardPath = '/dashboard';
  static const String attendancePath = '/attendance';
  static const String qrPath = '/qr';
  static const String statisticsPath = '/statistics';
  static const String settingsPath = '/settings';

  static const String dashboardRouteName = 'dashboard';
  static const String attendanceRouteName = 'attendance';
  static const String qrRouteName = 'qr';
  static const String statisticsRouteName = 'statistics';
  static const String settingsRouteName = 'settings';

  static const List<AppDestination> destinations = [
    AppDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      path: dashboardPath,
      routeName: dashboardRouteName,
      appBarTitle: 'Dashboard',
    ),
    AppDestination(
      label: 'Attendance',
      icon: Icons.assignment_turned_in_outlined,
      selectedIcon: Icons.assignment_turned_in,
      path: attendancePath,
      routeName: attendanceRouteName,
      appBarTitle: 'Attendance',
    ),
    AppDestination(
      label: 'Scan QR',
      icon: Icons.qr_code_scanner_outlined,
      selectedIcon: Icons.qr_code_scanner,
      path: qrPath,
      routeName: qrRouteName,
      appBarTitle: 'QR Scanner',
    ),
    AppDestination(
      label: 'Statistics',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      path: statisticsPath,
      routeName: statisticsRouteName,
      appBarTitle: 'Statistics',
    ),
    AppDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      path: settingsPath,
      routeName: settingsRouteName,
      appBarTitle: 'Settings',
    ),
  ];

  static String appBarTitleForIndex(int index) {
    if (index < 0 || index >= destinations.length) {
      return destinations.first.appBarTitle;
    }
    return destinations[index].appBarTitle;
  }
}
