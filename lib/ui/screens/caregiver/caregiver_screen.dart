import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/medication_alert_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/alert_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_badge.dart';

class CaregiverScreen extends ConsumerWidget {
  const CaregiverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final alerts = ref.watch(alertProvider);

    final patientName = (user?.name.isNotEmpty ?? false)
        ? user!.name
        : AppConstants.demoPatientName;
    final patientAge = (user?.age != null && user!.age > 0)
        ? '${user.age} Yrs'
        : AppConstants.demoPatientAge;
    final patientBlood = (user?.bloodGroup != null &&
            user!.bloodGroup.isNotEmpty &&
            user.bloodGroup != 'Not specified')
        ? user.bloodGroup
        : AppConstants.demoPatientBloodGroup;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Caregiver Remote Portal', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Profile Overview
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C0F172A),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.primaryColor, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFFE2E8F0),
                        child: Icon(Icons.person_rounded, size: 36, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Outfit'),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$patientAge • Blood Group: $patientBlood',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          const StatusBadge(
                            label: 'STABLE CONDITION',
                            color: Color(0xFF0D9488),
                            icon: Icons.check_circle_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Live Geolocation Safety Zone
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Color(0xFFF43F5E), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Live Geolocation & Safety Zone',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Outfit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_rounded, color: Color(0xFF0D9488), size: 36),
                            SizedBox(height: 6),
                            Text(
                              'Sector 4, Green Valley Home, Bengaluru',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            Text('Geofence Safe • GPS Accuracy 4m', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Caregiver Communication Actions
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Voice Call',
                      icon: Icons.call_rounded,
                      onPressed: () {
                        final contactName = (user?.emergencyContactName.isNotEmpty == true && user!.emergencyContactName != 'Not provided')
                            ? user.emergencyContactName
                            : 'Emergency Contact';
                        final contactPhone = (user?.emergencyContactPhone.isNotEmpty == true && user!.emergencyContactPhone != 'Not provided')
                            ? user.emergencyContactPhone
                            : (user?.phone.isNotEmpty == true ? user!.phone : '+91 87548 14489');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dialing $contactName ($contactPhone)...')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Video Call',
                      icon: Icons.videocam_rounded,
                      isSecondary: true,
                      onPressed: () {
                        final contactName = (user?.emergencyContactName.isNotEmpty == true && user!.emergencyContactName != 'Not provided')
                            ? user.emergencyContactName
                            : patientName;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Initiating CareSphere WebRTC Video Channel with $contactName...')),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Emergency Alerts Feed
              const Text(
                'Caregiver Emergency Stream',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 12),

              ...alerts.take(3).map(
                (alt) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
                          color: (alt.severity == AlertSeverity.emergency ? Colors.red : Colors.amber).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: alt.severity == AlertSeverity.emergency ? Colors.red : Colors.amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alt.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alt.description,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
