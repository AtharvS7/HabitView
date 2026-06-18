/// Centralised route paths and names for go_router.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';

  static const today = '/today';
  static const dashboard = '/dashboard';
  static const insights = '/insights';
  static const settings = '/settings';

  static const habitCreate = '/habits/new';
  static String habitDetail(String id) => '/habits/$id';
  static String habitEdit(String id) => '/habits/$id/edit';

  static const account = '/settings/account';
  static const backup = '/settings/backup';
  static const notifications = '/settings/notifications';
  static const premium = '/settings/premium';
}
