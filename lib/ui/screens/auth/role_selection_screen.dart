import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import 'login_screen.dart' show GlowOrb, GradientButton;

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  UserRole _selectedRole = UserRole.patient;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    // Navigate to signup with chosen role
    context.go('/signup?role=${_selectedRole.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.authDarkGradient),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              left: -40,
              child: GlowOrb(
                color: AppTheme.primaryTeal,
                size: 320,
                opacity: 0.12,
              ),
            ),
            const Positioned(
              bottom: -60,
              right: -40,
              child: GlowOrb(
                color: AppTheme.accentIndigo,
                size: 280,
                opacity: 0.10,
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Brand Lockup Header
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppTheme.primaryTeal,
                                                AppTheme.primaryTealLight,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryTeal
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 18,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.health_and_safety_rounded,
                                            size: 26,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        const Text(
                                          'CareSphere',
                                          style: TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'Outfit',
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  const Text(
                                    'Choose Your Role',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Are you signing up as a patient or a caregiver? Select your role to get started.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: Colors.white.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Patient Card
                                  _RoleSelectCard(
                                    title: 'Patient / Elder',
                                    subtitle:
                                        'Track daily vitals, manage medicine schedules, and connect with bedside smart hub.',
                                    icon: Icons.elderly_rounded,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                                    ),
                                    accentColor: AppTheme.primaryTeal,
                                    isSelected: _selectedRole == UserRole.patient,
                                    onTap: () {
                                      setState(() => _selectedRole = UserRole.patient);
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Caregiver Card
                                  _RoleSelectCard(
                                    title: 'Caregiver / Family Member',
                                    subtitle:
                                        'Remotely monitor patient vitals, receive live emergency alerts, and view telemetry.',
                                    icon: Icons.volunteer_activism_rounded,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                    ),
                                    accentColor: AppTheme.accentIndigo,
                                    isSelected: _selectedRole == UserRole.caregiver,
                                    onTap: () {
                                      setState(() => _selectedRole = UserRole.caregiver);
                                    },
                                  ),
                                  const SizedBox(height: 32),

                                  // Continue to Sign Up Button
                                  GradientButton(
                                    text: 'Continue to Sign Up',
                                    isLoading: false,
                                    icon: Icons.arrow_forward_rounded,
                                    colors: _selectedRole == UserRole.patient
                                        ? [AppTheme.primaryTeal, AppTheme.primaryTealLight]
                                        : [AppTheme.accentIndigo, AppTheme.accentPurple],
                                    onTap: _handleContinue,
                                  ),
                                  const SizedBox(height: 14),

                                  // Direct Sign In Button for Selected Role
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        if (_selectedRole == UserRole.caregiver) {
                                          context.go('/caregiver-login');
                                        } else {
                                          context.go('/login');
                                        }
                                      },
                                      icon: Icon(
                                        _selectedRole == UserRole.caregiver
                                            ? Icons.volunteer_activism_rounded
                                            : Icons.elderly_rounded,
                                        size: 18,
                                        color: Colors.white70,
                                      ),
                                      label: Text(
                                        _selectedRole == UserRole.caregiver
                                            ? 'Sign In as Caregiver'
                                            : 'Sign In as Patient',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Outfit',
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        side: BorderSide(
                                          color: (_selectedRole == UserRole.caregiver
                                                  ? AppTheme.accentPurple
                                                  : AppTheme.primaryTealLight)
                                              .withValues(alpha: 0.5),
                                          width: 1.4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Already have an account? Sign In
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (_selectedRole == UserRole.caregiver) {
                                            context.go('/caregiver-login');
                                          } else {
                                            context.go('/login');
                                          }
                                        },
                                        child: Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: _selectedRole == UserRole.caregiver
                                                ? AppTheme.accentPurple
                                                : AppTheme.primaryTealLight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSelectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
