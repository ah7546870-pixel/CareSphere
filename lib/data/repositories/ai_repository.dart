import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_prediction_model.dart';
import '../models/smartwatch_data_model.dart';
import '../models/esp32_data_model.dart';
import 'smartwatch_repository.dart';
import 'esp32_repository.dart';

abstract class AiRepository {
  Future<AiPredictionModel> fetchPrediction({
    required SmartwatchDataModel watchData,
    required Esp32DataModel espData,
  });
}

class FastAPIClient implements AiRepository {
  @override
  Future<AiPredictionModel> fetchPrediction({
    required SmartwatchDataModel watchData,
    required Esp32DataModel espData,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    double baseRisk = 10.0;
    List<String> reasons = [];

    // Extract ESP32 #1 Vitals & Motion
    final vitals = espData.vitals;
    final room = espData.room;

    final isVitalsConnected = vitals.isConnected;
    final isRoomConnected = room.isConnected;
    final isWatchConnected = watchData.isConnected;

    if (!isVitalsConnected && !isRoomConnected && !isWatchConnected) {
      return AiPredictionModel.disconnected();
    }

    final effectiveHr = isVitalsConnected ? vitals.heartRate : watchData.heartRate;
    final effectiveSpo2 = isVitalsConnected ? vitals.spO2 : watchData.spO2;

    // 1. ESP32 #1 Vitals: Heart Rate Analysis
    if (effectiveHr > 105) {
      baseRisk += 30.0;
      reasons.add('CRITICAL: High Heart Rate Tachycardia Spike (${effectiveHr} BPM)');
    } else if (effectiveHr < 55) {
      baseRisk += 20.0;
      reasons.add('WARNING: Low Heart Rate Bradycardia (${effectiveHr} BPM)');
    } else {
      reasons.add('ESP32 #1 Vitals: Heart Rate normal baseline (${effectiveHr} BPM)');
    }

    // 2. ESP32 #1 Vitals: SpO2 Analysis
    if (effectiveSpo2 < 94) {
      baseRisk += 35.0;
      reasons.add('CRITICAL: Low Blood Oxygen Saturation Hypoxia (${effectiveSpo2}%)');
    } else if (effectiveSpo2 < 96) {
      baseRisk += 15.0;
      reasons.add('WARNING: Mild SpO2 Drop (${effectiveSpo2}%)');
    } else {
      reasons.add('ESP32 #1 Vitals: SpO2 saturation healthy (${effectiveSpo2}%)');
    }

    // 3. ESP32 #1 Motion: Accelerometer & Gyroscope Vector Analysis
    final accelMag = sqrt(vitals.accelX * vitals.accelX + vitals.accelY * vitals.accelY + vitals.accelZ * vitals.accelZ);
    if (vitals.fallDetected || accelMag > 22.0) {
      baseRisk = 96.0;
      reasons.insert(0, 'EMERGENCY: Impact Fall Detected via ESP32 #1 Accelerometer (${accelMag.toStringAsFixed(1)} m/s²)');
    } else if (accelMag > 14.0) {
      baseRisk += 20.0;
      reasons.add('Sudden Rapid Movement Vector Spike (${accelMag.toStringAsFixed(1)} m/s²)');
    }

    // 4. ESP32 #2 Environment: SOS Button & Room Presence
    if (room.emergencyButtonPressed) {
      baseRisk = 99.0;
      reasons.insert(0, 'CRITICAL: Bedside ESP32 Emergency SOS Button Pressed!');
    }

    if (!room.presenceDetected) {
      baseRisk += 15.0;
      reasons.add('ESP32 #2 Room: No radar human motion detected in room');
    } else {
      reasons.add('ESP32 #2 Room: Radar human presence confirmed');
    }

    // 5. Connection Watchdog Alerts
    if (vitals.deviceStatus == 'Disconnected') {
      baseRisk += 10.0;
      reasons.add('ALERT: Connection Lost with ESP32 #1 (Vitals/Motion Hub)');
    }
    if (room.deviceStatus == 'Disconnected') {
      baseRisk += 10.0;
      reasons.add('ALERT: Connection Lost with ESP32 #2 (Room Environment Hub)');
    }

    final level = baseRisk > 70
        ? RiskLevel.critical
        : baseRisk > 40
            ? RiskLevel.high
            : baseRisk > 25
                ? RiskLevel.moderate
                : RiskLevel.low;

    return AiPredictionModel(
      riskPercentage: double.parse(baseRisk.clamp(5.0, 99.9).toStringAsFixed(1)),
      riskLevel: level,
      confidenceScore: 96.8,
      riskReasons: reasons,
      recommendations: [
        if (effectiveSpo2 < 95) 'Administer supplemental oxygen / request caregiver check immediately',
        if (effectiveHr > 100) 'Guide patient into resting seating position and monitor respiration',
        'Maintain room temperature at 22-24°C',
        'Review evening medication schedule',
      ],
      emergencyProbability: baseRisk > 50 ? 88.5 : 2.1,
      waterReminderAdvice: 'Drink 1 glass of water now to maintain optimal blood hydration.',
      medicineReminderAdvice: 'Evening Dosage: Amlodipine 5mg at 8:00 PM',
      sleepRecommendation: 'Recommended bedtime: 10:00 PM. High sleep quality predicted.',
      exerciseSuggestion: '15-min mild indoor exercise recommended.',
      predictionTime: DateTime.now(),
    );
  }
}

final aiRepoProvider = Provider<AiRepository>((ref) {
  return FastAPIClient();
});

final aiPredictionProvider = StreamProvider<AiPredictionModel>((ref) async* {
  final aiRepo = ref.watch(aiRepoProvider);
  final watchRepo = ref.watch(smartwatchRepoProvider);
  final espRepo = ref.watch(esp32RepoProvider);

  yield await aiRepo.fetchPrediction(
    watchData: watchRepo.latest,
    espData: espRepo.latest,
  );

  while (true) {
    await Future.delayed(const Duration(seconds: 4));
    yield await aiRepo.fetchPrediction(
      watchData: watchRepo.latest,
      espData: espRepo.latest,
    );
  }
});

