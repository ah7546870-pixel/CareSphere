import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/medication_alert_repository.dart';
import '../../../data/models/alert_model.dart';
import '../../widgets/status_badge.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final alerts = ref.watch(alertProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts Log', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            final color = alert.severity == AlertSeverity.emergency
                ? Colors.red
                : alert.severity == AlertSeverity.warning
                    ? Colors.amber.shade800
                    : Colors.blue;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_active_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge(label: alert.category.toUpperCase(), color: color),
                            Text(
                              DateFormat('hh:mm a').format(alert.timestamp),
                              style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alert.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.description,
                          style: TextStyle(fontSize: 12, height: 1.4, color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
