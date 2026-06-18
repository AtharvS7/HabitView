import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/auth_providers.dart';
import '../../application/providers/settings_providers.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/habits/habit_create_screen.dart';
import '../screens/habits/habit_detail_screen.dart';
import '../screens/habits/habit_edit_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/settings/account_screen.dart';
import '../screens/settings/backup_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/settings/premium_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/today/today_screen.dart';
import 'app_routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// The app's [GoRouter]. Redirects are driven by auth state + onboarding flag;
/// the router refreshes whenever either changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.listen(settingsProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loc = state.matchedLocation;

      // Still resolving the first auth event → stay on splash.
      if (authState.isLoading || !authState.hasValue) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final user = authState.valueOrNull;
      final onAuthRoute = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgotPassword;

      if (user == null) {
        return onAuthRoute ? null : AppRoutes.login;
      }

      // Signed in.
      final settings = ref.read(currentSettingsProvider);
      if (!settings.onboardingCompleted) {
        return loc == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      // Onboarded + signed in: bounce away from splash/auth/onboarding.
      if (loc == AppRoutes.splash ||
          onAuthRoute ||
          loc == AppRoutes.onboarding) {
        return AppRoutes.today;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      // Full-screen routes outside the bottom-nav shell.
      GoRoute(
        path: AppRoutes.habitCreate,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const HabitCreateScreen(),
      ),
      GoRoute(
        path: '/habits/:id/edit',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            HabitEditScreen(habitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/habits/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            HabitDetailScreen(habitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.account,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.backup,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const BackupScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.premium,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const PremiumScreen(),
      ),
      // Bottom-navigation shell.
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: AppRoutes.today,
                builder: (_, __) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.insights,
              builder: (_, __) => const InsightsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (_, __) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
