import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final ageCtrl = TextEditingController(text: user.age > 0 ? user.age.toString() : '');
    final bloodCtrl = TextEditingController(text: user.bloodGroup);
    final heightCtrl = TextEditingController(text: user.height > 0 ? user.height.toString() : '');
    final weightCtrl = TextEditingController(text: user.weight > 0 ? user.weight.toString() : '');
    final medCtrl = TextEditingController(text: user.medicalConditions);
    final emergNameCtrl = TextEditingController(text: user.emergencyContactName);
    final emergPhoneCtrl = TextEditingController(text: user.emergencyContactPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppTheme.primaryTealLight, size: 28),
            SizedBox(width: 10),
            Text(
              'Edit Health Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField('Full Name', nameCtrl, Icons.person_outline),
                const SizedBox(height: 12),
                _buildDialogField('Phone', phoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDialogField('Age', ageCtrl, Icons.cake_outlined, keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDialogField('Blood Group', bloodCtrl, Icons.bloodtype_outlined)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDialogField('Height (cm)', heightCtrl, Icons.height_rounded, keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDialogField('Weight (kg)', weightCtrl, Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDialogField('Medical Conditions', medCtrl, Icons.healing_outlined),
                const SizedBox(height: 12),
                _buildDialogField('Emergency Contact Name', emergNameCtrl, Icons.person_pin_outlined),
                const SizedBox(height: 12),
                _buildDialogField('Emergency Phone', emergPhoneCtrl, Icons.phone_in_talk_outlined, keyboardType: TextInputType.phone),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = user.copyWith(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                age: int.tryParse(ageCtrl.text.trim()) ?? user.age,
                bloodGroup: bloodCtrl.text.trim().isEmpty ? 'Not specified' : bloodCtrl.text.trim(),
                height: double.tryParse(heightCtrl.text.trim()) ?? user.height,
                weight: double.tryParse(weightCtrl.text.trim()) ?? user.weight,
                medicalConditions: medCtrl.text.trim().isEmpty ? 'None specified' : medCtrl.text.trim(),
                emergencyContactName: emergNameCtrl.text.trim().isEmpty ? 'Not provided' : emergNameCtrl.text.trim(),
                emergencyContactPhone: emergPhoneCtrl.text.trim().isEmpty ? 'Not provided' : emergPhoneCtrl.text.trim(),
              );

              await ref.read(authStateProvider.notifier).updateProfile(updated);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white38, size: 18),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Health Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () => _showEditProfileDialog(context, ref, user),
                icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primaryTeal),
                label: const Text('Edit Details',
                  style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar & Basic Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF2B608A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x141E3A5F),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryTeal, AppTheme.primaryTealLight],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.name ?? 'User Profile',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                    ),
                    if (user?.phone.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.phone,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Physical Vitals Metrics Grid
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Age', user?.age != null && user!.age > 0 ? '${user.age} yrs' : 'Not set', Icons.cake_outlined)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Blood', user?.bloodGroup ?? 'Not set', Icons.bloodtype_outlined)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Weight', user?.weight != null && user!.weight > 0 ? '${user.weight} kg' : 'Not set', Icons.monitor_weight_outlined)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Height', user?.height != null && user!.height > 0 ? '${user.height} cm' : 'Not set', Icons.height_rounded)),
                ],
              ),

              if (user?.role == UserRole.patient && user?.elderCode != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Unique Elder Code',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        user!.elderCode!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                          color: AppTheme.primaryTeal,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share this code with your caregiver to link accounts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Medical Conditions Card
              _buildInfoSectionCard(
                title: 'Medical Conditions',
                content: user?.medicalConditions.isNotEmpty ?? false ? user!.medicalConditions : 'None specified',
                icon: Icons.healing_rounded,
                iconColor: AppTheme.accentRose,
                onEditTap: user != null ? () => _showEditProfileDialog(context, ref, user) : null,
              ),

              const SizedBox(height: 14),

              // Emergency Contact Card
              _buildInfoSectionCard(
                title: 'Emergency Contact',
                content: (user?.emergencyContactName.isNotEmpty ?? false)
                    ? '${user!.emergencyContactName} ${user.emergencyContactPhone.isNotEmpty ? "(${user.emergencyContactPhone})" : ""}'
                    : 'Not provided',
                icon: Icons.phone_in_talk_rounded,
                iconColor: AppTheme.accentEmerald,
                onEditTap: user != null ? () => _showEditProfileDialog(context, ref, user) : null,
              ),

              const SizedBox(height: 36),

              CustomButton(
                text: 'Log Out',
                isSecondary: true,
                isDanger: true,
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryTeal),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSectionCard({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onEditTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (onEditTap != null)
                      InkWell(
                        onTap: onEditTap,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryTeal),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
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
