import 'package:intl/intl.dart';

class SmartwatchDataModel {
  final String id;
  final String patientId;
  final int heartRate; // BPM
  final int spO2; // %
  final double sleepHours; // Hours
  final int steps; // Steps
  final String activityState; // Resting, Walking, Active
  final int caloriesBurned; // kcal
  final int stressLevel; // 0-100 score
  final DateTime timestamp;
  final bool isConnected;

  SmartwatchDataModel({
    String? id,
    String? patientId,
    required this.heartRate,
    required this.spO2,
    required this.sleepHours,
    required this.steps,
    required this.activityState,
    required this.caloriesBurned,
    required this.stressLevel,
    required this.timestamp,
    this.isConnected = false,
  })  : id = id ?? 'telemetry_${timestamp.millisecondsSinceEpoch}',
        patientId = patientId ?? 'patient_eleanor_vance';

  // Date and Time Helpers for Daily Rollover & SQL Partitioning
  String get dateString => DateFormat('yyyy-MM-dd').format(timestamp);
  String get timeString => DateFormat('HH:mm:ss').format(timestamp);
  String get formattedTime => DateFormat('hh:mm:ss a').format(timestamp);
  String get formattedDate => DateFormat('d MMM yyyy').format(timestamp);
  String get formattedDateTime => DateFormat('hh:mm:ss a • d MMM yyyy').format(timestamp);

  // Connection-aware display helpers
  String get hrDisplay => isConnected ? '$heartRate' : 'Not Connected';
  String get spO2Display => isConnected ? '$spO2' : 'Not Connected';
  String get sleepDisplay => isConnected ? sleepHours.toStringAsFixed(1) : 'Not Connected';
  String get stepsDisplay => isConnected ? '$steps' : 'Not Connected';
  String get caloriesDisplay => isConnected ? '$caloriesBurned' : 'Not Connected';
  String get stressDisplay => isConnected ? '$stressLevel' : 'Not Connected';

  factory SmartwatchDataModel.mock() {
    return SmartwatchDataModel(
      heartRate: 0,
      spO2: 0,
      sleepHours: 0,
      steps: 0,
      activityState: 'No Data',
      caloriesBurned: 0,
      stressLevel: 0,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isConnected: false,
    );
  }

  factory SmartwatchDataModel.fromJson(Map<String, dynamic> json) {
    return SmartwatchDataModel(
      id: json['id'],
      patientId: json['patient_id'] ?? 'patient_eleanor_vance',
      heartRate: json['heart_rate'] ?? 72,
      spO2: json['spo2'] ?? 98,
      sleepHours: (json['sleep_hours'] as num?)?.toDouble() ?? 7.0,
      steps: json['steps'] ?? 4000,
      activityState: json['activity'] ?? 'Resting',
      caloriesBurned: json['calories'] ?? 1400,
      stressLevel: json['stress'] ?? 25,
      isConnected: json['is_connected'] ?? true,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : (json['recorded_at'] != null ? DateTime.parse(json['recorded_at']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'heart_rate': heartRate,
      'spo2': spO2,
      'sleep_hours': sleepHours,
      'steps': steps,
      'activity': activityState,
      'calories': caloriesBurned,
      'stress': stressLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// SQL / Supabase REST Payload matching `smartwatch_telemetry_10min` table columns
  Map<String, dynamic> toSupabaseMap() {
    return {
      'patient_id': patientId,
      'reading_date': dateString,
      'reading_time': timeString,
      'recorded_at': timestamp.toIso8601String(),
      'heart_rate': heartRate,
      'spo2': spO2,
      'sleep_duration': sleepHours,
      'daily_steps': steps,
      'stress_index': stressLevel,
      'active_calories': caloriesBurned,
      'activity_state': activityState,
      'synced_from': 'CareSphere App',
    };
  }
}
