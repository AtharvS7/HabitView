import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/user_progress_provider.dart';
import '../../router/app_routes.dart';

/// Bottom-navigation shell hosting the four primary branches. The Dashboard
/// and Insights destinations unlock progressively as the user logs more.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsUnlocked = ref.watch(statsUnlockedProvider);
    final insightsUnlocked = ref.watch(insightsUnlockedProvider);

    return Scaffold(
      body: navigationShell,
      floatingActionButton: navigationShell.currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.habitCreate),
              icon: const Icon(Icons.add),
              label: const Text('New habit'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(statsUnlocked
                ? Icons.bar_chart_outlined
                : Icons.lock_outline),
            selectedIcon: const Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(insightsUnlocked
                ? Icons.insights_outlined
                : Icons.lock_outline),
            selectedIcon: const Icon(Icons.insights),
            label: 'Insights',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    // `goBranch` preserves each branch's own navigation stack; tapping the
    // active destination pops it back to its root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
