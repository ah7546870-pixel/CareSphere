enum RiskLevel { low, moderate, high, critical }

class AiPredictionModel {
  final double riskPercentage;
  final RiskLevel riskLevel;
  final double confidenceScore;
  final List<String> riskReasons;
  final List<String> recommendations;
  final double emergencyProbability;
  final String waterReminderAdvice;
  final String medicineReminderAdvice;
  final String sleepRecommendation;
  final String exerciseSuggestion;
  final DateTime predictionTime;

  AiPredictionModel({
    required this.riskPercentage,
    required this.riskLevel,
    required this.confidenceScore,
    required this.riskReasons,
    required this.recommendations,
    required this.emergencyProbability,
    required this.waterReminderAdvice,
    required this.medicineReminderAdvice,
    required this.sleepRecommendation,
    required this.exerciseSuggestion,
    required this.predictionTime,
  });

  bool get isConnected => confidenceScore > 0.0;

  factory AiPredictionModel.disconnected() {
    return AiPredictionModel(
      riskPercentage: 0.0,
      riskLevel: RiskLevel.low,
      confidenceScore: 0.0,
      riskReasons: [
        'Hardware Devices Not Connected: Awaiting live sensor telemetry',
        'Connect ESP32 #1 (Vitals/Motion), ESP32 #2 (Room Node), or Smartwatch to begin AI risk assessment',
      ],
      recommendations: [
        'Connect hardware devices via Smart Hub to activate real-time AI vitals monitoring.',
        'Ensure ESP32 is powered on and connected to the local Wi-Fi network.',
      ],
      emergencyProbability: 0.0,
      waterReminderAdvice: 'Awaiting device telemetry to calibrate hydration status.',
      medicineReminderAdvice: 'Schedule: Consult your caregiver or doctor for prescribed regimen.',
      sleepRecommendation: 'Awaiting sensor connectivity for sleep analysis.',
      exerciseSuggestion: 'Awaiting sensor connectivity for mobility tracking.',
      predictionTime: DateTime.now(),
    );
  }

  factory AiPredictionModel.mock() {
    return AiPredictionModel(
      riskPercentage: 14.5,
      riskLevel: RiskLevel.low,
      confidenceScore: 94.2,
      riskReasons: [
        'Heart rate stable within baseline range (74 BPM)',
        'Bedside temperature optimal (23.4°C)',
        'Presence active in living area',
        'Normal SpO2 levels (98%)',
      ],
      recommendations: [
        'Drink 250ml water before 5:00 PM',
        'Schedule evening walk at 6:15 PM for 15 mins',
        'Maintain ambient humidity above 45%',
      ],
      emergencyProbability: 2.1,
      waterReminderAdvice: 'Drink 1 glass of warm water now to meet hydration goal (1.8L / 2.0L)',
      medicineReminderAdvice: 'Next Dose: Amlodipine 5mg at 8:00 PM after dinner',
      sleepRecommendation: 'Target sleep time: 10:00 PM. High sleep efficiency expected based on light dimming.',
      exerciseSuggestion: '15-min light indoor stretching or garden walk recommended.',
      predictionTime: DateTime.now(),
    );
  }

  factory AiPredictionModel.fromJson(Map<String, dynamic> json) {
    return AiPredictionModel(
      riskPercentage: (json['risk_score'] as num?)?.toDouble() ?? 12.0,
      riskLevel: _parseRiskLevel(json['risk_level'] ?? 'low'),
      confidenceScore: (json['confidence'] as num?)?.toDouble() ?? 92.0,
      riskReasons: List<String>.from(json['reasons'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      emergencyProbability: (json['emergency_prob'] as num?)?.toDouble() ?? 2.0,
      waterReminderAdvice: json['water_advice'] ?? 'Hydrate regularly.',
      medicineReminderAdvice: json['medicine_advice'] ?? 'Take medicines on schedule.',
      sleepRecommendation: json['sleep_rec'] ?? '7-8 hours of restful sleep recommended.',
      exerciseSuggestion: json['exercise_rec'] ?? 'Light daily walks.',
      predictionTime: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }

  static RiskLevel _parseRiskLevel(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return RiskLevel.high;
      case 'critical':
        return RiskLevel.critical;
      case 'moderate':
        return RiskLevel.moderate;
      default:
        return RiskLevel.low;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'risk_score': riskPercentage,
      'risk_level': riskLevel.name,
      'confidence': confidenceScore,
      'reasons': riskReasons,
      'recommendations': recommendations,
      'emergency_prob': emergencyProbability,
      'water_advice': waterReminderAdvice,
      'medicine_advice': medicineReminderAdvice,
      'sleep_rec': sleepRecommendation,
      'exercise_rec': exerciseSuggestion,
      'timestamp': predictionTime.toIso8601String(),
    };
  }
}
