import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:qr_attendx_mobile/app/app.dart';
import 'package:qr_attendx_mobile/features/onboarding/onboarding_controller.dart';
import 'package:qr_attendx_mobile/features/settings/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );
  final themeController = await ThemeController.create();
  final onboardingController = await OnboardingController.create();
  runApp(
    App(
      themeController: themeController,
      onboardingController: onboardingController,
      flavorLabel: 'PROD',
    ),
  );
}
