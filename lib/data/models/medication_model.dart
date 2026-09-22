class MedicationModel {
  final String id;
  final String name;
  final String dosage;
  final String time; // e.g. "08:00 AM"
  final String repeatPattern; // Daily, Twice Daily, Every 8 hours, Mon-Wed-Fri
  final bool isTaken;
  final bool voiceReminderEnabled;
  final String instructions;

  MedicationModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.repeatPattern,
    this.isTaken = false,
    this.voiceReminderEnabled = true,
    this.instructions = 'Take with warm water after meals',
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      time: json['time'] ?? '',
      repeatPattern: json['repeat'] ?? 'Daily',
      isTaken: json['isTaken'] ?? false,
      voiceReminderEnabled: json['voiceReminder'] ?? true,
      instructions: json['instructions'] ?? 'Take after meal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'time': time,
      'repeat': repeatPattern,
      'isTaken': isTaken,
      'voiceReminder': voiceReminderEnabled,
      'instructions': instructions,
    };
  }

  static List<MedicationModel> mockList() {
    return [
      MedicationModel(
        id: 'med-1',
        name: 'Amlodipine Besylate',
        dosage: '5 mg - 1 Pill',
        time: '08:00 AM',
        repeatPattern: 'Daily Morning',
        isTaken: true,
        voiceReminderEnabled: true,
        instructions: 'Take in morning with a full glass of water for blood pressure.',
      ),
      MedicationModel(
        id: 'med-2',
        name: 'Metformin Hydrochloride',
        dosage: '500 mg - 1 Tablet',
        time: '01:30 PM',
        repeatPattern: 'Daily Lunch',
        isTaken: false,
        voiceReminderEnabled: true,
        instructions: 'Take immediately after lunch for glucose control.',
      ),
      MedicationModel(
        id: 'med-3',
        name: 'Atorvastatin Calcium',
        dosage: '10 mg - 1 Pill',
        time: '08:30 PM',
        repeatPattern: 'Daily Bedtime',
        isTaken: false,
        voiceReminderEnabled: true,
        instructions: 'Take before sleeping.',
      ),
      MedicationModel(
        id: 'med-4',
        name: 'Multivitamin Complex',
        dosage: '1 Softgel',
        time: '09:00 AM',
        repeatPattern: 'Every 2 Days',
        isTaken: true,
        voiceReminderEnabled: false,
        instructions: 'General dietary supplement.',
      ),
    ];
  }
}
