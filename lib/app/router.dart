import 'package:go_router/go_router.dart';
import 'package:qr_attendx_mobile/app/home_screen.dart';
import 'package:qr_attendx_mobile/core/utils/navigation_utils.dart';
import 'package:qr_attendx_mobile/features/attendance/attendance_screen.dart';
import 'package:qr_attendx_mobile/features/dashboard/dashboard_screen.dart';
import 'package:qr_attendx_mobile/features/onboarding/onboarding_controller.dart';
import 'package:qr_attendx_mobile/features/onboarding/onboarding_screen.dart';
import 'package:qr_attendx_mobile/features/qr/qr_screen.dart';
import 'package:qr_attendx_mobile/features/settings/settings_screen.dart';
import 'package:qr_attendx_mobile/features/statistics/statistics_screen.dart';

class AppRouter {
  static const String onboardingPath = '/get-started';

  static GoRouter createRouter(
    OnboardingController onboardingController,
  ) {
    return GoRouter(
      initialLocation: AppNavigationUtils.dashboardPath,
      refreshListenable: onboardingController,
      redirect: (context, state) {
        final onOnboarding = state.matchedLocation == onboardingPath;
        if (!onboardingController.isCompleted && !onOnboarding) {
          return onboardingPath;
        }
        if (onboardingController.isCompleted && onOnboarding) {
          return AppNavigationUtils.dashboardPath;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: onboardingPath,
          builder: (context, state) => const OnboardingScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return HomeScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppNavigationUtils.dashboardPath,
                  name: AppNavigationUtils.dashboardRouteName,
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppNavigationUtils.attendancePath,
                  name: AppNavigationUtils.attendanceRouteName,
                  builder: (context, state) => const AttendanceScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppNavigationUtils.qrPath,
                  name: AppNavigationUtils.qrRouteName,
                  builder: (context, state) => const QrScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppNavigationUtils.statisticsPath,
                  name: AppNavigationUtils.statisticsRouteName,
                  builder: (context, state) => const StatisticsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppNavigationUtils.settingsPath,
                  name: AppNavigationUtils.settingsRouteName,
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
