/// ESP32 Controller #1: Wearable Vitals & Motion Hub
/// Measures Heart Rate (MAX30102), SpO2 (%), Accelerometer & Gyroscope (MPU6050)
class Esp32VitalsDataModel {
  final int heartRate;          // BPM (e.g. 72)
  final int spO2;               // % (e.g. 98)
  final double accelX;          // m/s²
  final double accelY;          // m/s²
  final double accelZ;          // m/s²
  final double gyroX;           // deg/s
  final double gyroY;           // deg/s
  final double gyroZ;           // deg/s
  final bool fallDetected;      // MPU6050 Fall Detection
  final String deviceStatus;    // 'Connected', 'Disconnected', 'Syncing'
  final int wifiStrength;       // RSSI dBm
  final DateTime lastSync;

  Esp32VitalsDataModel({
    required this.heartRate,
    required this.spO2,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.fallDetected,
    required this.deviceStatus,
    required this.wifiStrength,
    required this.lastSync,
  });

  bool get isConnected => deviceStatus == 'Connected';
  String get hrDisplay => isConnected ? '$heartRate' : 'Not Connected';
  String get spO2Display => isConnected ? '$spO2' : 'Not Connected';
  String get accelZDisplay => isConnected ? accelZ.toStringAsFixed(2) : 'Not Connected';

  factory Esp32VitalsDataModel.mock() {
    return Esp32VitalsDataModel(
      heartRate: 0,
      spO2: 0,
      accelX: 0.0,
      accelY: 0.0,
      accelZ: 0.0,
      gyroX: 0.0,
      gyroY: 0.0,
      gyroZ: 0.0,
      fallDetected: false,
      deviceStatus: 'Disconnected',
      wifiStrength: 0,
      lastSync: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  factory Esp32VitalsDataModel.fromJson(Map<String, dynamic> json) {
    return Esp32VitalsDataModel(
      heartRate: json['heart_rate'] ?? 75,
      spO2: json['spo2'] ?? 98,
      accelX: (json['accel_x'] as num?)?.toDouble() ?? 0.0,
      accelY: (json['accel_y'] as num?)?.toDouble() ?? 0.0,
      accelZ: (json['accel_z'] as num?)?.toDouble() ?? 9.81,
      gyroX: (json['gyro_x'] as num?)?.toDouble() ?? 0.0,
      gyroY: (json['gyro_y'] as num?)?.toDouble() ?? 0.0,
      gyroZ: (json['gyro_z'] as num?)?.toDouble() ?? 0.0,
      fallDetected: json['fall_detected'] ?? false,
      deviceStatus: json['device_status'] ?? 'Connected',
      wifiStrength: json['wifi_rssi'] ?? -60,
      lastSync: json['last_sync'] != null ? DateTime.parse(json['last_sync']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heart_rate': heartRate,
      'spo2': spO2,
      'accel_x': accelX,
      'accel_y': accelY,
      'accel_z': accelZ,
      'gyro_x': gyroX,
      'gyro_y': gyroY,
      'gyro_z': gyroZ,
      'fall_detected': fallDetected,
      'device_status': deviceStatus,
      'wifi_rssi': wifiStrength,
      'last_sync': lastSync.toIso8601String(),
    };
  }

  Esp32VitalsDataModel copyWith({
    int? heartRate,
    int? spO2,
    double? accelX,
    double? accelY,
    double? accelZ,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    bool? fallDetected,
    String? deviceStatus,
    int? wifiStrength,
    DateTime? lastSync,
  }) {
    return Esp32VitalsDataModel(
      heartRate: heartRate ?? this.heartRate,
      spO2: spO2 ?? this.spO2,
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      gyroX: gyroX ?? this.gyroX,
      gyroY: gyroY ?? this.gyroY,
      gyroZ: gyroZ ?? this.gyroZ,
      fallDetected: fallDetected ?? this.fallDetected,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      wifiStrength: wifiStrength ?? this.wifiStrength,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

/// ESP32 Controller #2: Room Environment & Presence Hub
/// Measures Light Presence (BH1750 Lux), Human Presence (Radar HLK-LD2410/PIR), Temperature & Humidity (DHT22/SHT31)
class Esp32RoomDataModel {
  final double temperature;        // °C (e.g. 23.4)
  final double humidity;           // % (e.g. 52.0)
  final double ambientLight;       // Lux (e.g. 340.0)
  final bool presenceDetected;     // Radar / PIR presence
  final bool emergencyButtonPressed;// Physical SOS Button
  final String deviceStatus;       // 'Connected', 'Disconnected', 'Syncing'
  final int wifiStrength;          // RSSI dBm
  final String firmwareVersion;
  final DateTime lastSync;

  Esp32RoomDataModel({
    required this.temperature,
    required this.humidity,
    required this.ambientLight,
    required this.presenceDetected,
    required this.emergencyButtonPressed,
    required this.deviceStatus,
    required this.wifiStrength,
    required this.firmwareVersion,
    required this.lastSync,
  });

  bool get isConnected => deviceStatus == 'Connected';
  String get tempDisplay => isConnected ? '${temperature.toStringAsFixed(1)}' : 'Not Connected';
  String get humDisplay => isConnected ? '${humidity.toStringAsFixed(1)}' : 'Not Connected';
  String get lightDisplay => isConnected ? '${ambientLight.toStringAsFixed(1)}' : 'Not Connected';
  String get presenceDisplay => isConnected ? (presenceDetected ? 'DETECTED' : 'NOT PRESENT') : 'Not Connected';

  factory Esp32RoomDataModel.mock() {
    return Esp32RoomDataModel(
      temperature: 0.0,
      humidity: 0.0,
      ambientLight: 0.0,
      presenceDetected: false,
      emergencyButtonPressed: false,
      deviceStatus: 'Disconnected',
      wifiStrength: 0,
      firmwareVersion: 'v2.1.0-ESP32-SIH',
      lastSync: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  factory Esp32RoomDataModel.fromJson(Map<String, dynamic> json) {
    return Esp32RoomDataModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 23.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 50.0,
      ambientLight: (json['light'] as num?)?.toDouble() ?? (json['ambient_light'] as num?)?.toDouble() ?? 300.0,
      presenceDetected: json['presence'] ?? json['presence_detected'] ?? true,
      emergencyButtonPressed: json['button'] ?? json['emergency_button'] ?? false,
      deviceStatus: json['device_status'] ?? 'Connected',
      wifiStrength: json['wifi_rssi'] ?? -65,
      firmwareVersion: json['firmware'] ?? 'v2.1.0-ESP32-SIH',
      lastSync: json['last_sync'] != null ? DateTime.parse(json['last_sync']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'light': ambientLight,
      'presence': presenceDetected,
      'button': emergencyButtonPressed,
      'device_status': deviceStatus,
      'wifi_rssi': wifiStrength,
      'firmware': firmwareVersion,
      'last_sync': lastSync.toIso8601String(),
    };
  }

  Esp32RoomDataModel copyWith({
    double? temperature,
    double? humidity,
    double? ambientLight,
    bool? presenceDetected,
    bool? emergencyButtonPressed,
    String? deviceStatus,
    int? wifiStrength,
    String? firmwareVersion,
    DateTime? lastSync,
  }) {
    return Esp32RoomDataModel(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      ambientLight: ambientLight ?? this.ambientLight,
      presenceDetected: presenceDetected ?? this.presenceDetected,
      emergencyButtonPressed: emergencyButtonPressed ?? this.emergencyButtonPressed,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      wifiStrength: wifiStrength ?? this.wifiStrength,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

/// Backward Compatible Composite Esp32DataModel
class Esp32DataModel {
  final Esp32VitalsDataModel vitals;
  final Esp32RoomDataModel room;

  Esp32DataModel({
    required this.vitals,
    required this.room,
  });

  // Proxy getters for legacy code compatibility
  double get temperature => room.temperature;
  double get humidity => room.humidity;
  double get ambientLight => room.ambientLight;
  bool get presenceDetected => room.presenceDetected;
  bool get emergencyButtonPressed => room.emergencyButtonPressed;
  String get deviceStatus => (vitals.deviceStatus == 'Connected' && room.deviceStatus == 'Connected')
      ? 'Connected'
      : (vitals.deviceStatus == 'Disconnected' || room.deviceStatus == 'Disconnected')
          ? 'Disconnected'
          : 'Syncing';
  int get wifiStrength => room.wifiStrength;
  String get firmwareVersion => room.firmwareVersion;
  DateTime get lastSync => vitals.lastSync.isAfter(room.lastSync) ? vitals.lastSync : room.lastSync;
  bool get isConnected => vitals.isConnected || room.isConnected;

  factory Esp32DataModel.mock() {
    return Esp32DataModel(
      vitals: Esp32VitalsDataModel.mock(),
      room: Esp32RoomDataModel.mock(),
    );
  }

  factory Esp32DataModel.fromJson(Map<String, dynamic> json) {
    return Esp32DataModel(
      vitals: json['vitals'] != null ? Esp32VitalsDataModel.fromJson(json['vitals']) : Esp32VitalsDataModel.fromJson(json),
      room: json['room'] != null ? Esp32RoomDataModel.fromJson(json['room']) : Esp32RoomDataModel.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vitals': vitals.toJson(),
      'room': room.toJson(),
    };
  }
}

