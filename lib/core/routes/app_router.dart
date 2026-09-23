import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/providers/app_providers.dart';
import '../../ui/screens/splash/splash_screen.dart';
import '../../ui/screens/onboarding/onboarding_screen.dart';
import '../../ui/screens/auth/login_screen.dart';
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
  '/login',
  '/signup',
  '/forgot-password',
  '/otp-verify',
};

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null || ref.read(authStateProvider).value != null;
      final isAuthRoute = _authRoutes.contains(state.matchedLocation);
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Always allow splash & onboarding
      if (isSplash || isOnboarding) return null;

      // Redirect logged-in users away from auth screens
      if (isLoggedIn && isAuthRoute) return '/dashboard';

      // Redirect logged-out users away from protected screens
      if (!isLoggedIn && !isAuthRoute) return '/login';

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
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
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
