enum AlertSeverity { info, warning, emergency }

class AlertModel {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final String category; // High HR, Low SpO2, Emergency Button, No Presence, Temperature
  final DateTime timestamp;
  final bool isRead;

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.timestamp,
    this.isRead = false,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      category: json['category'] ?? 'General',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.name,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  static List<AlertModel> mockAlerts() {
    final now = DateTime.now();
    return [
      AlertModel(
        id: 'alt-1',
        title: 'Bedside Emergency SOS Pressed',
        description: 'Physical ESP32 Bedside Panic button triggered by patient.',
        severity: AlertSeverity.emergency,
        category: 'Emergency Button',
        timestamp: now.subtract(const Duration(minutes: 12)),
        isRead: false,
      ),
      AlertModel(
        id: 'alt-2',
        title: 'Elevated Heart Rate Spikes (112 BPM)',
        description: 'Smartwatch detected heart rate above safe threshold for 5 continuous mins.',
        severity: AlertSeverity.warning,
        category: 'High Heart Rate',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
        isRead: true,
      ),
      AlertModel(
        id: 'alt-3',
        title: 'No Room Presence Detected',
        description: 'HLK-LD2410 Radar detected zero micro-movement in room for over 3 hours.',
        severity: AlertSeverity.warning,
        category: 'No Presence',
        timestamp: now.subtract(const Duration(hours: 4)),
        isRead: true,
      ),
      AlertModel(
        id: 'alt-4',
        title: 'Medication Missed: Metformin 500mg',
        description: 'Afternoon pill schedule passed without patient confirmation.',
        severity: AlertSeverity.warning,
        category: 'Medication Missed',
        timestamp: now.subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      AlertModel(
        id: 'alt-5',
        title: 'Ambient Room Temperature High (31.2°C)',
        description: 'SHT31 sensor recorded room temperature exceeding recommended comfortable limit.',
        severity: AlertSeverity.info,
        category: 'High Temperature',
        timestamp: now.subtract(const Duration(hours: 9)),
        isRead: true,
      ),
    ];
  }
}
