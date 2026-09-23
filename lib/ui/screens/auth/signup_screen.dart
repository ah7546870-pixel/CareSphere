import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import 'login_screen.dart'
    show DarkTextField, GradientButton, ErrorBanner, GlowOrb;

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  // Step tracker
  int _step = 0; // 0 = role selection, 1 = profile form
  UserRole _selectedRole = UserRole.patient;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _elderCodeCtrl = TextEditingController();
  final _bloodGroupCtrl = TextEditingController(text: 'B+');
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _medicalConditionsCtrl = TextEditingController();
  final _emergencyContactNameCtrl = TextEditingController();
  final _emergencyContactPhoneCtrl = TextEditingController();
  bool _obscurePass = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  void _nextStep() {
    _animController.reset();
    setState(() => _step = 1);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _elderCodeCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _medicalConditionsCtrl.dispose();
    _emergencyContactNameCtrl.dispose();
    _emergencyContactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    final age = int.tryParse(_ageCtrl.text.trim()) ?? 50;
    final height = double.tryParse(_heightCtrl.text.trim()) ?? 170.0;
    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 65.0;

    await ref.read(authStateProvider.notifier).signup(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          role: _selectedRole,
          age: age,
          phone: _phoneCtrl.text.trim(),
          linkedElderCode: _selectedRole == UserRole.caregiver
              ? _elderCodeCtrl.text.trim()
              : null,
          bloodGroup: _bloodGroupCtrl.text.trim(),
          height: height,
          weight: weight,
          medicalConditions: _medicalConditionsCtrl.text.trim(),
          emergencyContactName: _emergencyContactNameCtrl.text.trim(),
          emergencyContactPhone: _emergencyContactPhoneCtrl.text.trim(),
        );

    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.hasError) {
      setState(() => _errorMessage =
          state.error.toString().replaceFirst('Exception: ', ''));
    } else if (state.value != null) {
      final user = state.value!;
      if (user.role == UserRole.patient && user.elderCode != null) {
        _showElderCodeDialog(user.elderCode!);
      } else {
        context.go('/dashboard');
      }
    }
  }

  void _showElderCodeDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.navyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
              color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentEmerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accentEmerald, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Account Created!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Share this code with your children so they can monitor your health.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryTeal, AppTheme.primaryTealLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.white,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Unique Elder Code',
                style: TextStyle(
                  color: AppTheme.primaryTealLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (mounted) {
                      context.go('/dashboard');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Enter Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              top: -100,
              left: -50,
              child: GlowOrb(
                  color: AppTheme.primaryTeal, size: 300, opacity: 0.1),
            ),
            const Positioned(
              bottom: -60,
              right: -40,
              child: GlowOrb(
                  color: AppTheme.accentIndigo, size: 240, opacity: 0.08),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        if (_step > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white70),
                            onPressed: () {
                              _animController.reset();
                              setState(() => _step = 0);
                              _animController.forward();
                            },
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                              foregroundColor:
                                  Colors.white.withValues(alpha: 0.5)),
                          child: const Text('Sign In Instead'),
                        ),
                      ],
                    ),
                  ),

                  // Step indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        _StepDot(active: _step == 0, done: _step > 0, label: '1'),
                        _StepLine(done: _step > 0),
                        _StepDot(active: _step == 1, done: false, label: '2'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Content
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: _step == 0
                            ? _buildRoleStep()
                            : _buildFormStep(authState),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Role Selection ───────────────────────────────────────────────

  Widget _buildRoleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        children: [
          const Text(
            'Who are you?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Outfit',
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Select your role to get a personalized experience',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 40),
          _RoleCard(
            icon: Icons.elderly_rounded,
            title: 'Elder / Patient',
            subtitle:
                'I want to monitor my own health and share data with my family.',
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
            ),
            glowColor: AppTheme.primaryTeal,
            isSelected: _selectedRole == UserRole.patient,
            onTap: () => setState(() => _selectedRole = UserRole.patient),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            icon: Icons.volunteer_activism_rounded,
            title: 'Child / Caregiver',
            subtitle:
                'I want to remotely monitor my parent\'s health & receive alerts.',
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
            glowColor: AppTheme.accentIndigo,
            isSelected: _selectedRole == UserRole.caregiver,
            onTap: () => setState(() => _selectedRole = UserRole.caregiver),
          ),
          const SizedBox(height: 40),
          GradientButton(
            text: 'Continue',
            isLoading: false,
            onTap: _nextStep,
            icon: Icons.arrow_forward_rounded,
            colors: _selectedRole == UserRole.patient
                ? [AppTheme.primaryTeal, AppTheme.primaryTealLight]
                : [AppTheme.accentIndigo, AppTheme.accentPurple],
          ),
        ],
      ),
    );
  }

  // ── Step 2: Profile Form ─────────────────────────────────────────────────

  Widget _buildFormStep(AsyncValue<dynamic> authState) {
    final isPatient = _selectedRole == UserRole.patient;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1), width: 1.5),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: isPatient
                                ? const LinearGradient(colors: [
                                    AppTheme.primaryTeal,
                                    AppTheme.primaryTealLight
                                  ])
                                : const LinearGradient(colors: [
                                    AppTheme.accentIndigo,
                                    AppTheme.accentPurple
                                  ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPatient
                                ? Icons.elderly_rounded
                                : Icons.volunteer_activism_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPatient ? 'Elder Profile' : 'Caregiver Profile',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            Text(
                              'Fill in your details',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    if (_errorMessage != null) ...[
                      ErrorBanner(message: _errorMessage!),
                      const SizedBox(height: 20),
                    ],

                    DarkTextField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      hint: 'e.g. Eleanor Vance',
                      prefixIcon: Icons.person_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v != null && v.isNotEmpty ? null : 'Required',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DarkTextField(
                            controller: _ageCtrl,
                            label: 'Age',
                            hint: 'e.g. 72',
                            prefixIcon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v != null && v.isNotEmpty ? null : 'Required',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DarkTextField(
                            controller: _phoneCtrl,
                            label: 'Phone',
                            hint: '+91 9876543210',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v != null && v.isNotEmpty ? null : 'Required',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (isPatient) ...[
                      Row(
                        children: [
                          Expanded(
                            child: DarkTextField(
                              controller: _bloodGroupCtrl,
                              label: 'Blood Group',
                              hint: 'e.g. O+',
                              prefixIcon: Icons.bloodtype_outlined,
                              validator: (v) =>
                                  v != null && v.isNotEmpty ? null : 'Required',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DarkTextField(
                              controller: _heightCtrl,
                              label: 'Height (cm)',
                              hint: '162',
                              prefixIcon: Icons.height_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DarkTextField(
                              controller: _weightCtrl,
                              label: 'Weight (kg)',
                              hint: '65',
                              prefixIcon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DarkTextField(
                        controller: _medicalConditionsCtrl,
                        label: 'Medical Conditions (optional)',
                        hint: 'e.g. Mild Hypertension, Type-2 Diabetes',
                        prefixIcon: Icons.healing_outlined,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DarkTextField(
                              controller: _emergencyContactNameCtrl,
                              label: 'Emergency Contact Name',
                              hint: 'e.g. Dr. Sarah Jenkins',
                              prefixIcon: Icons.person_pin_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DarkTextField(
                              controller: _emergencyContactPhoneCtrl,
                              label: 'Emergency Phone',
                              hint: '+91 9876543210',
                              prefixIcon: Icons.phone_in_talk_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    DarkTextField(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      hint: 'you@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : 'Enter valid email',
                    ),
                    const SizedBox(height: 14),
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
                      validator: (v) => v != null && v.length >= 6
                          ? null
                          : 'Minimum 6 characters',
                    ),
                    const SizedBox(height: 14),

                    if (!isPatient) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.accentIndigo.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.accentIndigo
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            DarkTextField(
                              controller: _elderCodeCtrl,
                              label: 'Parent\'s Elder Code',
                              hint: 'e.g. 234567',
                              prefixIcon: Icons.vpn_key_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v != null && v.isNotEmpty ? null : 'Required',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ask your parent for their 6-digit code shown in their profile.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const SizedBox(height: 10),
                    GradientButton(
                      text: isPatient
                          ? 'Create Patient Account'
                          : 'Create Caregiver Account',
                      isLoading: authState.isLoading,
                      onTap: _handleSignup,
                      colors: isPatient
                          ? [AppTheme.primaryTeal, AppTheme.primaryTealLight]
                          : [AppTheme.accentIndigo, AppTheme.accentPurple],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Role Card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final Color glowColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.glowColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? glowColor.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? glowColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: isSelected
                    ? null
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.white : Colors.white38, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: isSelected ? 0.6 : 0.35),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: glowColor, size: 24),
          ],
        ),
      ),
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  final String label;

  const _StepDot({required this.active, required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active || done
            ? AppTheme.primaryTeal
            : Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: active || done
              ? AppTheme.primaryTeal
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 2,
        color: done
            ? AppTheme.primaryTeal
            : Colors.white.withValues(alpha: 0.15),
      ),
    );
  }
}
