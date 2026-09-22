import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../data/models/ai_prediction_model.dart';

class AiRiskMeter extends StatelessWidget {
  final double score;
  final RiskLevel level;
  final bool isConnected;

  const AiRiskMeter({
    super.key,
    required this.score,
    required this.level,
    this.isConnected = true,
  });

  Color _getRiskColor() {
    if (!isConnected) {
      return const Color(0xFF64748B);
    }
    switch (level) {
      case RiskLevel.critical:
        return const Color(0xFFF43F5E);
      case RiskLevel.high:
        return const Color(0xFFEA580C);
      case RiskLevel.moderate:
        return const Color(0xFFF59E0B);
      case RiskLevel.low:
        return const Color(0xFF0D9488);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getRiskColor();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 10.0,
            percent: isConnected ? (score / 100.0).clamp(0.0, 1.0) : 0.0,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isConnected ? '${score.toStringAsFixed(0)}%' : '--',
                  style: TextStyle(
                    fontSize: isConnected ? 20 : 22,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Outfit',
                    shadows: isConnected ? [
                      Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
                    ] : null,
                  ),
                ),
                Text(
                  isConnected ? 'RISK' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            progressColor: color,
            backgroundColor: color.withValues(alpha: 0.15),
            circularStrokeCap: CircularStrokeCap.round,
            animation: isConnected,
            animateFromLastPercent: true,
            animationDuration: 1200,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        isConnected ? '${level.name.toUpperCase()} RISK' : 'NOT CONNECTED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isConnected ? 'AI Health Engine Active' : 'Hardware Devices Offline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Outfit',
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isConnected
                      ? 'Continuous multi-modal telemetry analyzing smartwatch & ESP32 room sensors.'
                      : 'Connect hardware sensor devices via Smart Hub to compute real-time AI risk.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
