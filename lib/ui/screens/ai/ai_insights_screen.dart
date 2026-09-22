import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/ai_risk_meter.dart';

class AiInsightsScreen extends ConsumerWidget {
  const AiInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aiAsync = ref.watch(aiPredictionProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          'AI Predictive Health Engine',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
      ),
      body: SafeArea(
        child: aiAsync.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          data: (aiData) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Risk Meter Header
                AiRiskMeter(
                  score: aiData.riskPercentage,
                  level: aiData.riskLevel,
                  isConnected: aiData.isConnected,
                ),

                const SizedBox(height: 20),

                // Confidence & Emergency Probability Metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricBadge(
                        title: 'ML Confidence',
                        value: aiData.isConnected ? '${aiData.confidenceScore}%' : 'Not Connected',
                        icon: Icons.verified_rounded,
                        color: aiData.isConnected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricBadge(
                        title: 'Emergency Prob.',
                        value: aiData.isConnected ? '${aiData.emergencyProbability}%' : 'Not Connected',
                        icon: Icons.warning_amber_rounded,
                        color: aiData.isConnected ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                        theme: theme,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Key Prediction Factors / Reasons
                const Text(
                  'Multi-Modal Diagnostic Telemetry',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 12),

                ...aiData.riskReasons.map(
                  (reason) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x060F172A),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.analytics_rounded, size: 18, color: Color(0xFF0D9488)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            reason,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Recommendations & Reminders Section
                const Text(
                  'Personalized Care Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 12),

                _buildRecommendationTile(
                  title: 'Hydration Assistant',
                  desc: aiData.waterReminderAdvice,
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 10),
                _buildRecommendationTile(
                  title: 'Medication Schedule',
                  desc: aiData.medicineReminderAdvice,
                  icon: Icons.medication_rounded,
                  color: const Color(0xFF0D9488),
                ),
                const SizedBox(height: 10),
                _buildRecommendationTile(
                  title: 'Sleep Optimization',
                  desc: aiData.sleepRecommendation,
                  icon: Icons.bedtime_rounded,
                  color: const Color(0xFF4F46E5),
                ),
                const SizedBox(height: 10),
                _buildRecommendationTile(
                  title: 'Daily Activity Guidance',
                  desc: aiData.exerciseSuggestion,
                  icon: Icons.fitness_center_rounded,
                  color: const Color(0xFFEA580C),
                ),
                const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('AI Engine Error: $err')),
        ),
      ),
    );
  }

  Widget _buildMetricBadge({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTile({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
