import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_attendx_mobile/core/utils/navigation_utils.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendx_mobile/core/utils/navigation_state.dart';
import 'package:qr_attendx_mobile/shared/widgets/custom_appbar.dart';
import 'package:qr_attendx_mobile/shared/widgets/custom_navbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(BuildContext context, int index) {
    context.read<NavigationStateController>().setCurrentIndex(index);
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    context
        .read<NavigationStateController>()
        .setCurrentIndex(navigationShell.currentIndex);
    final title = AppNavigationUtils.appBarTitleForIndex(
      navigationShell.currentIndex,
    );
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: navigationShell,
      bottomNavigationBar: CustomNavBar(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
      ),
    );
  }
}
