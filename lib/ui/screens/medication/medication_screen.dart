import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/medication_alert_repository.dart';
import '../../../data/models/medication_model.dart';
import '../../../core/theme/app_theme.dart';

class MedicationScreen extends ConsumerWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final medications = ref.watch(medicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            onPressed: () => _showAddMedicationDialog(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.record_voice_over_rounded, color: theme.primaryColor, size: 28),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Reminders Active',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ESP32 hub and phone will synthesize voice alerts at dosage time.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Today Schedule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 14),

              ...medications.map(
                (med) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref.read(medicationProvider.notifier).toggleMedication(med.id);
                        },
                        child: Icon(
                          med.isTaken ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: med.isTaken ? AppTheme.accentEmerald : theme.disabledColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: med.isTaken ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${med.dosage} • ${med.repeatPattern}',
                              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          med.time,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMedicationDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '09:00 AM');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Medicine Name')),
            TextField(controller: dosageCtrl, decoration: const InputDecoration(labelText: 'Dosage (e.g. 500mg)')),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Reminder Time')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ref.read(medicationProvider.notifier).addMedication(
                      MedicationModel(
                        id: 'med-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text,
                        dosage: dosageCtrl.text.isEmpty ? '1 Pill' : dosageCtrl.text,
                        time: timeCtrl.text,
                        repeatPattern: 'Daily',
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
