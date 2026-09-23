import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/ai_prediction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/esp32_repository.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../widgets/vitals_card.dart';
import '../../widgets/ai_risk_meter.dart';

class CaregiverDashboardScreen extends ConsumerWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userState = ref.watch(authStateProvider);
    final user = userState.value;

    final espAsync = ref.watch(esp32StreamProvider);
    final aiAsync = ref.watch(aiPredictionProvider);
    final patientAsync = ref.watch(monitoredPatientProvider);
    final patient = patientAsync.value;

    final espData = espAsync.value ?? ref.read(esp32RepoProvider).latest;

    // For caregiver, assume we get the fall detection from AI or SOS from ESP
    final isFallDetected = aiAsync.value?.riskLevel == RiskLevel.critical ||
        espData.room.emergencyButtonPressed;

    final currentTime =
        DateFormat('EEEE, d MMMM • hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.name ?? "Caregiver"} 👋',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface),
            ),
            Text(
              currentTime,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_rounded,
                color: theme.colorScheme.onSurface, size: 28),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.primaryColor,
          backgroundColor: theme.colorScheme.surface,
          onRefresh: () async {
            ref.invalidate(aiPredictionProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFallDetected) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2), // Soft coral background
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_rounded,
                            color: Color(0xFFDC2626), size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'EMERGENCY: Fall or SOS Detected!',
                            style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildPatientBanner(context, theme, patient, user?.linkedElderCode),
                const SizedBox(height: 20),
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
                        color: espData.vitals.isConnected ? theme.colorScheme.tertiary : const Color(0xFF94A3B8),
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
                        color: espData.vitals.isConnected ? theme.colorScheme.primary : const Color(0xFF94A3B8),
                        statusText: espData.vitals.isConnected
                            ? (espData.vitals.spO2 < 95 ? 'LOW' : 'NORMAL')
                            : 'NOT CONNECTED',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Medical Condition & ML Insights',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                aiAsync.when(
                  skipLoadingOnReload: true,
                  skipLoadingOnRefresh: true,
                  data: (aiData) {
                    if (!espData.isConnected) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                            width: 1.2,
                          ),
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
                            const Icon(Icons.sensors_off_rounded,
                                color: Color(0xFF64748B), size: 28),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hardware Devices Not Connected',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Waiting for real-time sensor streams from the elder\'s bedside/wearable hubs.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: theme.dividerColor.withValues(alpha: 0.1),
                                width: 1.2),
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
                              Icon(Icons.medical_services_rounded,
                                  color: theme.colorScheme.secondary,
                                  size: 28), // Indigo
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Primary Assessment',
                                        style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                            fontSize: 12)),
                                    Text(
                                      aiData.riskLevel.name.toUpperCase(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: theme.colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AiRiskMeter(
                          score: aiData.riskPercentage,
                          level: aiData.riskLevel,
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Error: $err'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientBanner(
    BuildContext context,
    ThemeData theme,
    UserModel? patient,
    String? code,
  ) {
    final patientName = patient?.name ?? 'Assigned Patient';
    final activeCode = code ?? patient?.elderCode ?? "N/A";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.elderly_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          patientName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Patient Code: #$activeCode',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live telemetry stream active for this patient',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (patient != null) ...[
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.08),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInfoChip(
                    theme,
                    Icons.cake_outlined,
                    'Age',
                    patient.age > 0 ? '${patient.age} yrs' : 'N/A',
                  ),
                  const SizedBox(width: 10),
                  _buildInfoChip(
                    theme,
                    Icons.bloodtype_outlined,
                    'Blood Group',
                    patient.bloodGroup.isNotEmpty ? patient.bloodGroup : 'N/A',
                  ),
                  const SizedBox(width: 10),
                  _buildInfoChip(
                    theme,
                    Icons.healing_outlined,
                    'Condition',
                    patient.medicalConditions.isNotEmpty && patient.medicalConditions != 'None specified'
                        ? patient.medicalConditions
                        : 'Normal Health',
                  ),
                  if (patient.emergencyContactPhone.isNotEmpty &&
                      patient.emergencyContactPhone != 'Not provided') ...[
                    const SizedBox(width: 10),
                    _buildInfoChip(
                      theme,
                      Icons.contact_phone_outlined,
                      'Emergency',
                      patient.emergencyContactPhone,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF4F46E5),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
