import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/theme/app_theme.dart';

class MainNavigationWrapper extends ConsumerWidget {
  final Widget child;

  const MainNavigationWrapper({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/monitoring')) return 1;
    if (location.startsWith('/ai-insights')) return 2;
    if (location.startsWith('/smart-hub')) return 3;
    if (location.startsWith('/caregiver') || location.startsWith('/medication')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, WidgetRef ref) {
    final user = ref.read(authStateProvider).value;
    final isCaregiver = user?.role == UserRole.caregiver;
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/monitoring');
        break;
      case 2:
        context.go('/ai-insights');
        break;
      case 3:
        context.go('/smart-hub');
        break;
      case 4:
        if (isCaregiver) {
          context.go('/caregiver');
        } else {
          context.go('/medication');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final user = ref.watch(authStateProvider).value;
    final isCaregiver = user?.role == UserRole.caregiver;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.borderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryTeal.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: selectedIndex > 4 ? 0 : selectedIndex,
            onDestinationSelected: (idx) => _onItemTapped(idx, context, ref),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppTheme.primaryTeal.withValues(alpha: 0.12),
            height: 70,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              _navDest(
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view_rounded,
                label: 'Dashboard',
                isSelected: selectedIndex == 0,
              ),
              _navDest(
                icon: Icons.favorite_outline_rounded,
                selectedIcon: Icons.favorite_rounded,
                label: 'Vitals',
                isSelected: selectedIndex == 1,
              ),
              _navDest(
                icon: Icons.psychology_outlined,
                selectedIcon: Icons.psychology_rounded,
                label: 'AI',
                isSelected: selectedIndex == 2,
              ),
              _navDest(
                icon: Icons.router_outlined,
                selectedIcon: Icons.router_rounded,
                label: 'IoT Hub',
                isSelected: selectedIndex == 3,
              ),
              if (isCaregiver)
                _navDest(
                  icon: Icons.volunteer_activism_outlined,
                  selectedIcon: Icons.volunteer_activism_rounded,
                  label: 'Care',
                  isSelected: selectedIndex == 4,
                )
              else
                _navDest(
                  icon: Icons.medication_outlined,
                  selectedIcon: Icons.medication_rounded,
                  label: 'Meds',
                  isSelected: selectedIndex == 4,
                ),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _navDest({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
  }) {
    return NavigationDestination(
      icon: Icon(icon,
          color: isSelected
              ? AppTheme.primaryTeal
              : const Color(0xFF94A3B8)),
      selectedIcon: Icon(selectedIcon, color: AppTheme.primaryTeal),
      label: label,
    );
  }
}
