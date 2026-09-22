import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/esp32_data_model.dart';
import 'auth_repository.dart';
import '../services/supabase_service.dart';

class Esp32Repository {
  final _vitalsController = StreamController<Esp32VitalsDataModel>.broadcast();
  final _roomController = StreamController<Esp32RoomDataModel>.broadcast();
  final _compositeController = StreamController<Esp32DataModel>.broadcast();

  Timer? _simulationTimer;
  Timer? _watchdogTimer;

  bool _isVitalsSimulationActive = false;
  bool _isRoomSimulationActive = false;

  Esp32VitalsDataModel _latestVitals = Esp32VitalsDataModel.mock().copyWith(deviceStatus: 'Disconnected');
  Esp32RoomDataModel _latestRoom = Esp32RoomDataModel.mock().copyWith(deviceStatus: 'Disconnected');

  String _vitalsIp = '';
  String _roomIp = '';
  final Ref _ref;

  Esp32Repository(this._ref) {
    _loadSavedIps();
    _startWatchdog();
  }

  String get vitalsIp => _vitalsIp;
  String get roomIp => _roomIp;

  Future<void> _loadSavedIps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _vitalsIp = prefs.getString('caresphere_esp32_vitals_ip') ?? '';
      _roomIp = prefs.getString('caresphere_esp32_room_ip') ?? '';
    } catch (_) {}
  }

  Future<void> _saveIps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('caresphere_esp32_vitals_ip', _vitalsIp);
      await prefs.setString('caresphere_esp32_room_ip', _roomIp);
    } catch (_) {}
  }

  String _cleanIp(String ip) {
    return ip
        .replaceAll('http://', '')
        .replaceAll('https://', '')
        .replaceAll('/', '')
        .trim();
  }

  void setVitalsIp(String ip) {
    _vitalsIp = _cleanIp(ip);
    _saveIps();
  }

  void setRoomIp(String ip) {
    _roomIp = _cleanIp(ip);
    _saveIps();
  }

  /// 1. Heartbeat Watchdog & Local IP Poller: Polls the ESP32 web servers directly every 3 seconds.
  void _startWatchdog() {
    _watchdogTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      bool changed = false;

      // Poll ESP32 #1 Vitals locally
      if (_vitalsIp.isNotEmpty) {
        try {
          final url = Uri.parse('http://$_vitalsIp/api/vitals');
          final response = await http.get(url).timeout(const Duration(seconds: 2));

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = jsonDecode(response.body);
            data['recorded_at'] = DateTime.now().toUtc().toIso8601String(); 
            
            _latestVitals = Esp32VitalsDataModel.fromJson(data).copyWith(
              deviceStatus: 'Connected',
              lastSync: DateTime.now(),
            );
            _vitalsController.add(_latestVitals);
            changed = true;
            
            // Upload to Supabase
            _uploadVitalsToSupabase(data);
          } else {
            _latestVitals = _latestVitals.copyWith(deviceStatus: 'Disconnected');
          }
        } catch (_) {
          _latestVitals = _latestVitals.copyWith(deviceStatus: 'Disconnected');
        }
      }

      // Poll ESP32 #2 Room Node locally
      if (_roomIp.isNotEmpty) {
        try {
          final url = Uri.parse('http://$_roomIp/api/room');
          final response = await http.get(url).timeout(const Duration(seconds: 2));

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = jsonDecode(response.body);
            data['recorded_at'] = DateTime.now().toUtc().toIso8601String(); 
            
            _latestRoom = Esp32RoomDataModel.fromJson(data).copyWith(
              deviceStatus: data['emergency_button'] == true ? 'EMERGENCY_TRIGGERED' : 'Connected',
              lastSync: DateTime.now(),
            );
            _roomController.add(_latestRoom);
            changed = true;
            
            // Upload to Supabase
            _uploadRoomToSupabase(data);
          } else {
            _latestRoom = _latestRoom.copyWith(deviceStatus: 'Disconnected');
          }
        } catch (_) {
          _latestRoom = _latestRoom.copyWith(deviceStatus: 'Disconnected');
        }
      }

      if (changed) {
        _compositeController.add(latest);
      }
    });
  }

  Future<void> _uploadVitalsToSupabase(Map<String, dynamic> data) async {
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        data['patient_id'] = user.id; // Override with actual patient ID
      }
      final supabaseService = _ref.read(supabaseServiceProvider);
      await supabaseService.insertEsp32VitalsTelemetry(data);
    } catch (_) {}
  }
  
  Future<void> _uploadRoomToSupabase(Map<String, dynamic> data) async {
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        data['patient_id'] = user.id; // Override with actual patient ID
      }
      final supabaseService = _ref.read(supabaseServiceProvider);
      await supabaseService.insertEsp32RoomTelemetry(data);
    } catch (_) {}
  }


  /// 2. Background Stream Simulator (can be paused to simulate real hardware HTTP posts or offline connection loss)
  void _startSimulation() {
    final rand = Random();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final now = DateTime.now();

      // ESP32 #1: Vitals & Motion (Heart Rate, SpO2, Accel X/Y/Z, Gyro X/Y/Z)
      if (_isVitalsSimulationActive && _latestVitals.deviceStatus != 'Disconnected') {
        final hrDelta = rand.nextInt(5) - 2;
        final newHr = (_latestVitals.heartRate + hrDelta).clamp(60, 120);
        final newSpo2 = (rand.nextInt(3) == 0) ? (97 + rand.nextInt(3)) : _latestVitals.spO2;

        _latestVitals = Esp32VitalsDataModel(
          heartRate: newHr,
          spO2: newSpo2,
          accelX: double.parse(((rand.nextDouble() - 0.5) * 0.4).toStringAsFixed(2)),
          accelY: double.parse(((rand.nextDouble() - 0.5) * 0.4).toStringAsFixed(2)),
          accelZ: double.parse((9.81 + (rand.nextDouble() - 0.5) * 0.2).toStringAsFixed(2)),
          gyroX: double.parse(((rand.nextDouble() - 0.5) * 0.08).toStringAsFixed(2)),
          gyroY: double.parse(((rand.nextDouble() - 0.5) * 0.08).toStringAsFixed(2)),
          gyroZ: double.parse(((rand.nextDouble() - 0.5) * 0.08).toStringAsFixed(2)),
          fallDetected: false,
          deviceStatus: 'Connected',
          wifiStrength: -55 - rand.nextInt(10),
          lastSync: now,
        );
        _vitalsController.add(_latestVitals);
      }

      // ESP32 #2: Room Environment (Temp, Humidity, Light Lux, Presence)
      if (_isRoomSimulationActive && _latestRoom.deviceStatus != 'Disconnected') {
        final deltaTemp = (rand.nextDouble() - 0.5) * 0.2;
        final deltaHum = (rand.nextDouble() - 0.5) * 0.4;
        final newTemp = double.parse((_latestRoom.temperature + deltaTemp).toStringAsFixed(1));
        final newHum = double.parse((_latestRoom.humidity + deltaHum).toStringAsFixed(1));

        _latestRoom = Esp32RoomDataModel(
          temperature: newTemp.clamp(18.0, 38.0),
          humidity: newHum.clamp(30.0, 85.0),
          ambientLight: double.parse((320.0 + rand.nextInt(40)).toStringAsFixed(1)),
          presenceDetected: _latestRoom.presenceDetected,
          emergencyButtonPressed: _latestRoom.emergencyButtonPressed,
          deviceStatus: 'Connected',
          wifiStrength: -60 - rand.nextInt(10),
          firmwareVersion: 'v2.1.0-ESP32-SIH',
          lastSync: now,
        );
        _roomController.add(_latestRoom);
      }

      _compositeController.add(latest);
    });
  }

  /// 3. Ingestion API Endpoint handler for physical ESP32 #1 (Vitals & Motion)
  void updateVitalsFromEsp32(Esp32VitalsDataModel data) {
    _latestVitals = data.copyWith(
      deviceStatus: 'Connected',
      lastSync: DateTime.now(),
    );
    _vitalsController.add(_latestVitals);
    _compositeController.add(latest);
  }

  /// 4. Ingestion API Endpoint handler for physical ESP32 #2 (Room & Environment)
  void updateRoomFromEsp32(Esp32RoomDataModel data) {
    _latestRoom = data.copyWith(
      deviceStatus: 'Connected',
      lastSync: DateTime.now(),
    );
    _roomController.add(_latestRoom);
    _compositeController.add(latest);
  }

  /// Interactive Simulation & Connection Toggles
  void toggleVitalsConnection(bool isConnected) {
    _latestVitals = _latestVitals.copyWith(
      deviceStatus: isConnected ? 'Connected' : 'Disconnected',
      lastSync: isConnected ? DateTime.now() : DateTime.now().subtract(const Duration(seconds: 30)),
    );
    _vitalsController.add(_latestVitals);
    _compositeController.add(latest);
  }

  void toggleRoomConnection(bool isConnected) {
    _latestRoom = _latestRoom.copyWith(
      deviceStatus: isConnected ? 'Connected' : 'Disconnected',
      lastSync: isConnected ? DateTime.now() : DateTime.now().subtract(const Duration(seconds: 30)),
    );
    _roomController.add(_latestRoom);
    _compositeController.add(latest);
  }

  void togglePresence(bool detected) {
    _latestRoom = _latestRoom.copyWith(
      presenceDetected: detected,
      lastSync: DateTime.now(),
    );
    _roomController.add(_latestRoom);
    _compositeController.add(latest);
  }

  void triggerEmergencyButton() {
    _latestRoom = _latestRoom.copyWith(
      emergencyButtonPressed: true,
      deviceStatus: 'EMERGENCY_TRIGGERED',
      lastSync: DateTime.now(),
    );
    _roomController.add(_latestRoom);
    _compositeController.add(latest);
  }

  void resetEmergencyButton() {
    _latestRoom = _latestRoom.copyWith(
      emergencyButtonPressed: false,
      deviceStatus: 'Connected',
      lastSync: DateTime.now(),
    );
    _roomController.add(_latestRoom);
    _compositeController.add(latest);
  }

  void triggerFallEvent() {
    _latestVitals = _latestVitals.copyWith(
      fallDetected: true,
      accelZ: 28.5,
      gyroX: 180.0,
      lastSync: DateTime.now(),
    );
    _vitalsController.add(_latestVitals);
    _compositeController.add(latest);
  }

  // Stream & State Getters
  Stream<Esp32VitalsDataModel> vitalsStream() => _vitalsController.stream;
  Stream<Esp32RoomDataModel> roomStream() => _roomController.stream;
  Stream<Esp32DataModel> esp32Stream() => _compositeController.stream;

  Esp32VitalsDataModel get latestVitals => _latestVitals;
  Esp32RoomDataModel get latestRoom => _latestRoom;
  Esp32DataModel get latest => Esp32DataModel(vitals: _latestVitals, room: _latestRoom);

  void dispose() {
    _simulationTimer?.cancel();
    _watchdogTimer?.cancel();
    _vitalsController.close();
    _roomController.close();
    _compositeController.close();
  }
}

final esp32RepoProvider = Provider<Esp32Repository>((ref) {
  final repo = Esp32Repository(ref);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final esp32StreamProvider = StreamProvider<Esp32DataModel>((ref) {
  return ref.watch(esp32RepoProvider).esp32Stream();
});

final esp32VitalsStreamProvider = StreamProvider<Esp32VitalsDataModel>((ref) {
  return ref.watch(esp32RepoProvider).vitalsStream();
});

final esp32RoomStreamProvider = StreamProvider<Esp32RoomDataModel>((ref) {
  return ref.watch(esp32RepoProvider).roomStream();
});

