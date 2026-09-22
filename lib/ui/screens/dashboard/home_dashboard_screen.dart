import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import 'elder_dashboard_screen.dart';
import 'caregiver_dashboard_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authStateProvider);
    final user = userState.value;

    if (user?.role == UserRole.caregiver) {
      return const CaregiverDashboardScreen();
    } else {
      return const ElderDashboardScreen();
    }
  }
}
