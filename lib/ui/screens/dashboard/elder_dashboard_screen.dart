import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/esp32_repository.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/models/ai_prediction_model.dart';
import '../../widgets/vitals_card.dart';
import '../../widgets/ai_risk_meter.dart';

class ElderDashboardScreen extends ConsumerStatefulWidget {
  const ElderDashboardScreen({super.key});

  @override
  ConsumerState<ElderDashboardScreen> createState() =>
      _ElderDashboardScreenState();
}

class _ElderDashboardScreenState extends ConsumerState<ElderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade =
        CurvedAnimation(parent: _headerAnim, curve: Curves.easeIn);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut));
    _headerAnim.forward();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final espAsync = ref.watch(esp32StreamProvider);
    final aiAsync = ref.watch(aiPredictionProvider);
    final espData = espAsync.value ?? ref.read(esp32RepoProvider).latest;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final timeStr = DateFormat('EEEE, d MMMM').format(now);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Hero Header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.splashGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$greeting,',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                                Text(
                                  (user?.name != null && user!.name.isNotEmpty)
                                      ? user.name.split(' ').first
                                      : AppConstants.demoPatientName,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Outfit',
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Profile button
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.primaryTeal,
                                    AppTheme.primaryTealLight
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryTeal
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Quick stats row
                      Row(
                        children: [
                          _QuickStatChip(
                            icon: Icons.favorite_rounded,
                            value: espData.vitals.isConnected ? '${espData.vitals.heartRate}' : 'Not Connected',
                            unit: espData.vitals.isConnected ? 'BPM' : '',
                            color: espData.vitals.isConnected ? const Color(0xFFE11D48) : Colors.white60,
                          ),
                          const SizedBox(width: 10),
                          _QuickStatChip(
                            icon: Icons.water_drop_rounded,
                            value: espData.vitals.isConnected ? '${espData.vitals.spO2}' : 'Not Connected',
                            unit: espData.vitals.isConnected ? '%' : '',
                            color: espData.vitals.isConnected ? AppTheme.primaryTealLight : Colors.white60,
                          ),
                          const SizedBox(width: 10),
                          aiAsync.when(
                            skipLoadingOnReload: true,
                            skipLoadingOnRefresh: true,
                            data: (ai) => _QuickStatChip(
                              icon: Icons.psychology_rounded,
                              value: espData.isConnected ? '${ai.riskPercentage.toInt()}' : 'Not Connected',
                              unit: espData.isConnected ? 'Risk' : '',
                              color: espData.isConnected
                                  ? (ai.riskLevel == RiskLevel.critical
                                      ? const Color(0xFFE11D48)
                                      : ai.riskLevel == RiskLevel.high
                                          ? AppTheme.accentAmber
                                          : AppTheme.accentEmerald)
                                  : Colors.white60,
                            ),
                            loading: () => const _QuickStatChip(
                              icon: Icons.psychology_rounded,
                              value: '—',
                              unit: 'AI',
                              color: Colors.grey,
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section: Live Vitals
                _SectionHeader(
                  title: 'Live Vitals',
                  icon: Icons.monitor_heart_rounded,
                  onMore: () => context.go('/monitoring'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: VitalsCard(
                        title: 'Heart Rate',
                        value: espData.vitals.isConnected
                            ? '${espData.vitals.heartRate}'
                            : 'Not Connected',
                        unit: espData.vitals.isConnected ? 'BPM' : '',
                        icon: Icons.favorite_rounded,
                        color: espData.vitals.isConnected ? AppTheme.accentRose : const Color(0xFF94A3B8),
                        statusText: espData.vitals.isConnected
                            ? (espData.vitals.heartRate > 100 ? 'HIGH' : 'NORMAL')
                            : 'NOT CONNECTED',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: VitalsCard(
                        title: 'Blood Oxygen',
                        value: espData.vitals.isConnected
                            ? '${espData.vitals.spO2}'
                            : 'Not Connected',
                        unit: espData.vitals.isConnected ? '%' : '',
                        icon: Icons.water_drop_rounded,
                        color: espData.vitals.isConnected ? AppTheme.primaryTeal : const Color(0xFF94A3B8),
                        statusText: espData.vitals.isConnected
                            ? (espData.vitals.spO2 < 95 ? 'LOW' : 'NORMAL')
                            : 'NOT CONNECTED',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Section: AI Prediction
                _SectionHeader(
                  title: 'AI Health Prediction',
                  icon: Icons.psychology_rounded,
                  onMore: () => context.go('/ai-insights'),
                ),
                const SizedBox(height: 14),
                aiAsync.when(
                  skipLoadingOnReload: true,
                  skipLoadingOnRefresh: true,
                  data: (aiData) {
                    if (!espData.isConnected) {
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderLight, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.sensors_off_rounded, color: Color(0xFF64748B), size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hardware Not Connected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Connect ESP32 Vitals or Room node to stream live AI predictions.',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF94A3B8).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NOT CONNECTED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: [
                        // Risk level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: AppTheme.borderLight, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accentIndigo
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.medical_services_rounded,
                                  color: AppTheme.accentIndigo, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Primary Assessment',
                                    style: TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    aiData.riskLevel.name.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: _riskColor(aiData.riskLevel),
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _riskColor(aiData.riskLevel)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${aiData.riskPercentage.toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _riskColor(aiData.riskLevel),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AiRiskMeter(
                        score: aiData.riskPercentage,
                        level: aiData.riskLevel,
                      ),
                    ],
                  );
                },
                loading: () => Container(
                    height: 80,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                      strokeWidth: 2.5,
                    ),
                  ),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRose.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('AI service unavailable: $err',
                        style: const TextStyle(
                            color: AppTheme.accentRose, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 28),

                // Quick actions
                _SectionHeader(title: 'Quick Access', icon: Icons.apps_rounded),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.volunteer_activism_rounded,
                        label: 'Caregiver',
                        color: AppTheme.primaryTeal,
                        onTap: () => context.go('/caregiver'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.router_rounded,
                        label: 'IoT Hub',
                        color: AppTheme.accentIndigo,
                        onTap: () => context.go('/smart-hub'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.medication_rounded,
                        label: 'Meds',
                        color: AppTheme.accentEmerald,
                        onTap: () => context.go('/medication'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.show_chart_rounded,
                        label: 'History',
                        color: AppTheme.accentAmber,
                        onTap: () => context.go('/telemetry-history'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return AppTheme.accentRose;
      case RiskLevel.high:
        return AppTheme.accentAmber;
      case RiskLevel.moderate:
        return const Color(0xFFF59E0B);
      case RiskLevel.low:
        return AppTheme.accentEmerald;
    }
  }
}

// ── Shared Dashboard Widgets ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onMore;

  const _SectionHeader(
      {required this.title, required this.icon, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryTeal, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'Outfit',
            ),
          ),
        ),
        if (onMore != null)
          TextButton(
            onPressed: onMore,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryTeal,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'See all →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  const _QuickStatChip({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$value ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
