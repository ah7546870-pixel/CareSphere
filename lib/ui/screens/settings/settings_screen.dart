import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _voiceAssistant = true;
  bool _aiPredictiveAlerts = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Hardware & Connection Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSettingTile(
              title: 'ESP32 Bedside Hub',
              subtitle: 'IP: 192.168.1.150 • Connected',
              icon: Icons.router_rounded,
              trailing: const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
            ),
            _buildSettingTile(
              title: 'Smartwatch Connection',
              subtitle: 'Apple HealthKit / Health Connect Synced',
              icon: Icons.watch_rounded,
              trailing: const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
            ),
            _buildSettingTile(
              title: 'Firebase Backend Engine',
              subtitle: 'Cloud Firestore & Storage Synchronized',
              icon: Icons.cloud_done_rounded,
              trailing: const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
            ),

            const SizedBox(height: 24),

            const Text('Preferences & AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive emergency alerts instantly'),
              value: _pushNotifications,
              activeThumbColor: theme.primaryColor,
              activeTrackColor: theme.primaryColor.withValues(alpha: 0.3),
              onChanged: (val) => setState(() => _pushNotifications = val),
            ),
            SwitchListTile(
              title: const Text('AI Predictive Alerts'),
              subtitle: const Text('FastAPI continuous ML risk estimation'),
              value: _aiPredictiveAlerts,
              activeThumbColor: theme.primaryColor,
              activeTrackColor: theme.primaryColor.withValues(alpha: 0.3),
              onChanged: (val) => setState(() => _aiPredictiveAlerts = val),
            ),
            SwitchListTile(
              title: const Text('Voice Assistant Integration'),
              subtitle: const Text('Bedside voice medication prompts'),
              value: _voiceAssistant,
              activeThumbColor: theme.primaryColor,
              activeTrackColor: theme.primaryColor.withValues(alpha: 0.3),
              onChanged: (val) => setState(() => _voiceAssistant = val),
            ),

            const SizedBox(height: 24),

            const Text('About & Legal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSettingTile(
              title: 'Privacy Policy',
              subtitle: 'CareSphere HIPAA & GDPR Compliance',
              icon: Icons.privacy_tip_rounded,
              onTap: () {},
            ),
            _buildSettingTile(
              title: 'Terms of Service',
              subtitle: 'Commercial Hackathon License v1.0',
              icon: Icons.description_rounded,
              onTap: () {},
            ),
            _buildSettingTile(
              title: 'App Version',
              subtitle: 'v1.0.0 (Smart India Hackathon Build)',
              icon: Icons.info_rounded,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Icon(icon, color: theme.primaryColor),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}
