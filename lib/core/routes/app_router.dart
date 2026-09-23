import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../ui/screens/splash/splash_screen.dart';
import '../../ui/screens/onboarding/onboarding_screen.dart';
import '../../ui/screens/auth/role_selection_screen.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/auth/caregiver_login_screen.dart';
import '../../ui/screens/auth/signup_screen.dart';
import '../../ui/screens/auth/forgot_password_screen.dart';
import '../../ui/screens/auth/otp_verification_screen.dart';
import '../../ui/screens/main_navigation_wrapper.dart';
import '../../ui/screens/dashboard/home_dashboard_screen.dart';
import '../../ui/screens/monitoring/health_monitoring_screen.dart';
import '../../ui/screens/monitoring/telemetry_history_screen.dart';
import '../../ui/screens/ai/ai_insights_screen.dart';
import '../../ui/screens/smart_hub/smart_hub_screen.dart';
import '../../ui/screens/caregiver/caregiver_screen.dart';
import '../../ui/screens/alerts/alerts_screen.dart';
import '../../ui/screens/medication/medication_screen.dart';
import '../../ui/screens/profile/profile_screen.dart';
import '../../ui/screens/settings/settings_screen.dart';

final _authRoutes = {
  '/role-selection',
  '/login',
  '/caregiver-login',
  '/signup',
  '/forgot-password',
  '/otp-verify',
};

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<UserModel?>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      // Do NOT redirect while auth is actively resolving
      if (authState.isLoading) return null;

      Session? session;
      try {
        session = Supabase.instance.client.auth.currentSession;
      } catch (_) {}

      final isLoggedIn = session != null || authState.valueOrNull != null;
      final isAuthRoute = _authRoutes.contains(state.matchedLocation);
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Always allow splash & onboarding
      if (isSplash || isOnboarding) return null;

      // Redirect logged-in users away from auth screens
      if (isLoggedIn && isAuthRoute) return '/dashboard';

      // Redirect logged-out users away from protected screens
      if (!isLoggedIn && !isAuthRoute) return '/role-selection';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/caregiver-login',
        builder: (context, state) => const CaregiverLoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final roleParam = state.uri.queryParameters['role'];
          final initialRole = roleParam == 'caregiver'
              ? UserRole.caregiver
              : roleParam == 'patient'
                  ? UserRole.patient
                  : null;
          return SignupScreen(initialRole: initialRole);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verify',
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const HomeDashboardScreen(),
          ),
          GoRoute(
            path: '/monitoring',
            builder: (context, state) => const HealthMonitoringScreen(),
          ),
          GoRoute(
            path: '/telemetry-history',
            builder: (context, state) => const TelemetryHistoryScreen(),
          ),
          GoRoute(
            path: '/ai-insights',
            builder: (context, state) => const AiInsightsScreen(),
          ),
          GoRoute(
            path: '/smart-hub',
            builder: (context, state) => const SmartHubScreen(),
          ),
          GoRoute(
            path: '/caregiver',
            builder: (context, state) => const CaregiverScreen(),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsScreen(),
          ),
          GoRoute(
            path: '/medication',
            builder: (context, state) => const MedicationScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
