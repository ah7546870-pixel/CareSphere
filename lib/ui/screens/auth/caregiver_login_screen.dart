import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import 'login_screen.dart' show GlowOrb, DarkTextField, GradientButton, ErrorBanner;

class CaregiverLoginScreen extends ConsumerStatefulWidget {
  const CaregiverLoginScreen({super.key});

  @override
  ConsumerState<CaregiverLoginScreen> createState() => _CaregiverLoginScreenState();
}

class _CaregiverLoginScreenState extends ConsumerState<CaregiverLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _obscurePass = true;
  String? _errorMessage;
  String? _codeError;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
      _codeError = null;
    });

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final code = _codeCtrl.text.trim();

    final user = await ref.read(authStateProvider.notifier).loginCaregiver(
          email: email,
          password: pass,
          patientCode: code,
        );

    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.hasError) {
      final err = state.error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = err;
        if (err.toLowerCase().contains('code') || err.toLowerCase().contains('patient')) {
          _codeError = err;
        }
      });
    } else if (user != null) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.authDarkGradient),
        child: Stack(
          children: [
            const Positioned(
              top: -60,
              left: -40,
              child: GlowOrb(
                color: AppTheme.accentIndigo,
                size: 320,
                opacity: 0.16,
              ),
            ),
            const Positioned(
              bottom: -60,
              right: -40,
              child: GlowOrb(
                color: AppTheme.accentPurple,
                size: 300,
                opacity: 0.14,
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
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
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Bar with Back Button & Brand
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                          onPressed: () => context.go('/role-selection'),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentIndigo.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppTheme.accentIndigo.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.volunteer_activism_rounded,
                                                color: AppTheme.accentPurple,
                                                size: 14,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Caregiver Portal',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Header Lockup
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppTheme.accentIndigo,
                                                AppTheme.accentPurple,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.accentIndigo
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 16,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.health_and_safety_rounded,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        const Text(
                                          'CareSphere',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'Outfit',
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),

                                    const Text(
                                      'Caregiver Sign In',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Outfit',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Enter your email, password, and the 6-digit patient code to view live telemetry.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: Colors.white.withValues(alpha: 0.55),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    if (_errorMessage != null) ...[
                                      ErrorBanner(message: _errorMessage!),
                                      const SizedBox(height: 18),
                                    ],

                                    // Email Field
                                    DarkTextField(
                                      controller: _emailCtrl,
                                      label: 'Caregiver Email Address',
                                      hint: 'caregiver@example.com',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || !v.contains('@')) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Password Field
                                    DarkTextField(
                                      controller: _passCtrl,
                                      label: 'Password',
                                      hint: '••••••••',
                                      prefixIcon: Icons.lock_outlined,
                                      obscureText: _obscurePass,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePass
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.white38,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            setState(() => _obscurePass = !_obscurePass),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Patient Code Field
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        DarkTextField(
                                          controller: _codeCtrl,
                                          label: 'Patient Code Number (6-digit)',
                                          hint: 'e.g. 654321',
                                          prefixIcon: Icons.tag_rounded,
                                          keyboardType: TextInputType.number,
                                          errorText: _codeError,
                                          onChanged: (_) {
                                            if (_codeError != null) {
                                              setState(() => _codeError = null);
                                            }
                                          },
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return 'Please enter the patient code';
                                            }
                                            if (v.trim().length < 5) {
                                              return 'Enter a valid 6-digit patient code';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Ask the patient for the 6-digit code displayed in their profile.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white.withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 28),

                                    // Submit Button
                                    GradientButton(
                                      text: 'Sign In to Dashboard',
                                      icon: Icons.arrow_forward_rounded,
                                      isLoading: authState.isLoading,
                                      colors: const [
                                        AppTheme.accentIndigo,
                                        AppTheme.accentPurple,
                                      ],
                                      onTap: _handleLogin,
                                    ),
                                    const SizedBox(height: 24),

                                    // Cross-links
                                    Center(
                                      child: Column(
                                        children: [
                                          Wrap(
                                            alignment: WrapAlignment.center,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                "Are you a Patient? ",
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.45),
                                                  fontSize: 13,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => context.go('/login'),
                                                child: const Text(
                                                  'Sign In here',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primaryTealLight,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            alignment: WrapAlignment.center,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                "Don't have a caregiver account? ",
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.45),
                                                  fontSize: 13,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => context.go('/signup?role=caregiver'),
                                                child: const Text(
                                                  'Create Account',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.accentPurple,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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
            ),
          ],
        ),
      ),
    );
  }
}
