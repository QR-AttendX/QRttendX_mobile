import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendx_mobile/app/router.dart';
import 'package:qr_attendx_mobile/core/theme/app_theme.dart';
import 'package:qr_attendx_mobile/core/utils/navigation_state.dart';
import 'package:qr_attendx_mobile/features/attendance/attendance_controller.dart';
import 'package:qr_attendx_mobile/features/onboarding/onboarding_controller.dart';
import 'package:qr_attendx_mobile/features/settings/theme_controller.dart';

class App extends StatelessWidget {
  App({
    required this.themeController,
    required this.onboardingController,
    this.flavorLabel,
    super.key,
  }) : _router = AppRouter.createRouter(onboardingController);

  final ThemeController themeController;
  final OnboardingController onboardingController;
  final String? flavorLabel;
  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<OnboardingController>.value(
          value: onboardingController,
        ),
        ChangeNotifierProvider<AttendanceController>(
          create: (context) => AttendanceController(),
        ),
        ChangeNotifierProvider<NavigationStateController>(
          create: (context) => NavigationStateController(),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, controller, child) {
          return MaterialApp.router(
            title: 'QRttendX Mobile',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: controller.themeMode,
            routerConfig: _router,
            builder: (context, child) {
              final content = child ?? const SizedBox.shrink();
              if (flavorLabel == null || flavorLabel!.isEmpty) {
                return content;
              }
              return Banner(
                message: flavorLabel!,
                location: BannerLocation.topStart,
                child: content,
              );
            },
          );
        },
      ),
    );
  }
}
