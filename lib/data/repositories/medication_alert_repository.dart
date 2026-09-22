import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_model.dart';
import '../models/medication_model.dart';

class MedicationNotifier extends StateNotifier<List<MedicationModel>> {
  MedicationNotifier() : super(MedicationModel.mockList());

  void toggleMedication(String id) {
    state = [
      for (final med in state)
        if (med.id == id)
          MedicationModel(
            id: med.id,
            name: med.name,
            dosage: med.dosage,
            time: med.time,
            repeatPattern: med.repeatPattern,
            isTaken: !med.isTaken,
            voiceReminderEnabled: med.voiceReminderEnabled,
            instructions: med.instructions,
          )
        else
          med,
    ];
  }

  void addMedication(MedicationModel med) {
    state = [...state, med];
  }
}

final medicationProvider = StateNotifierProvider<MedicationNotifier, List<MedicationModel>>((ref) {
  return MedicationNotifier();
});

class AlertNotifier extends StateNotifier<List<AlertModel>> {
  AlertNotifier() : super(AlertModel.mockAlerts());

  void markAsRead(String id) {
    state = [
      for (final alt in state)
        if (alt.id == id)
          AlertModel(
            id: alt.id,
            title: alt.title,
            description: alt.description,
            severity: alt.severity,
            category: alt.category,
            timestamp: alt.timestamp,
            isRead: true,
          )
        else
          alt,
    ];
  }

  void addAlert(AlertModel alert) {
    state = [alert, ...state];
  }
}

final alertProvider = StateNotifierProvider<AlertNotifier, List<AlertModel>>((ref) {
  return AlertNotifier();
});
