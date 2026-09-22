import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/smartwatch_data_model.dart';
import '../services/supabase_service.dart';

class TelemetryDatabaseRepository {
  static const String _storageKey = 'caresphere_realtime_telemetry_history_v3';
  final SupabaseService? _supabaseService;
  final _controller = StreamController<List<SmartwatchDataModel>>.broadcast();
  List<SmartwatchDataModel> _cachedLogs = [];
  bool _isInitialized = false;

  TelemetryDatabaseRepository([this._supabaseService]) {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Remove any legacy mock records
      await prefs.remove('caresphere_smartwatch_telemetry_history_v2');

      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _cachedLogs = decoded
            .map((item) => SmartwatchDataModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // Start empty until hardware connects and logs real-time telemetry
        _cachedLogs = [];
      }
    } catch (_) {
      _cachedLogs = [];
    }
    _isInitialized = true;
    _controller.add(List.unmodifiable(_cachedLogs));
  }

  /// Generates a realistic full-day history (144 intervals of 10 minutes)
  List<SmartwatchDataModel> _generateFullDay10MinuteRecords() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final List<SmartwatchDataModel> records = [];

    // 1. Seed Yesterday (One Full Day: 144 intervals from 00:00 to 23:50)
    for (int i = 0; i < 144; i++) {
      final minuteOffset = i * 10;
      final sampleTime = yesterday.add(Duration(minutes: minuteOffset));
      final hour = sampleTime.hour;
      
      // Circadian variation for heart rate and steps
      final isNight = hour >= 22 || hour < 6;
      final hr = isNight ? (58 + (i % 8)) : (72 + (i % 18));
      final spo2 = 96 + (i % 4);
      final steps = (i * 32).clamp(0, 5200);
      final calories = (1200 + (i * 4)).clamp(1200, 1650);
      final stress = isNight ? 15 : (25 + (i % 15));
      final activity = isNight ? 'Sleeping' : (i % 12 == 0 ? 'Light Walking' : 'Resting in Armchair');

      records.add(
        SmartwatchDataModel(
          heartRate: hr,
          spO2: spo2,
          sleepHours: 7.4,
          steps: steps,
          activityState: activity,
          caloriesBurned: calories,
          stressLevel: stress,
          timestamp: sampleTime,
        ),
      );
    }

    // 2. Seed Today up to current hour/minute (10-minute intervals from 00:00 to now)
    final minutesElapsedToday = now.hour * 60 + now.minute;
    final totalIntervalsToday = (minutesElapsedToday / 10).floor().clamp(1, 144);

    for (int i = 0; i < totalIntervalsToday; i++) {
      final minuteOffset = i * 10;
      final sampleTime = today.add(Duration(minutes: minuteOffset));
      final hour = sampleTime.hour;
      final isNight = hour >= 22 || hour < 6;
      final hr = isNight ? (60 + (i % 6)) : (74 + (i % 14));
      final spo2 = 97 + (i % 3);
      final steps = (i * 45).clamp(0, 4483);
      final calories = (1250 + (i * 5)).clamp(1250, 1480);
      final stress = isNight ? 18 : (24 + (i % 12));
      final activity = isNight ? 'Sleeping' : (i % 8 == 0 ? 'Light Walking' : 'Resting in Armchair');

      records.add(
        SmartwatchDataModel(
          heartRate: hr,
          spO2: spo2,
          sleepHours: 7.2,
          steps: steps,
          activityState: activity,
          caloriesBurned: calories,
          stressLevel: stress,
          timestamp: sampleTime,
        ),
      );
    }

    // Sort descending by timestamp (newest first)
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  Future<void> _persistLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_cachedLogs.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (_) {}
  }

  /// Records a new 10-minute telemetry reading with exact timestamp into database
  /// Also synchronizes with Supabase SQL database table `smartwatch_telemetry_10min`
  Future<void> logTelemetry(SmartwatchDataModel data) async {
    if (!_isInitialized) {
      await _init();
    }
    // Prepend newest record
    _cachedLogs.insert(0, data);

    // Keep up to 7 full days of 10-minute snapshots (7 * 144 = 1008 records)
    if (_cachedLogs.length > 1050) {
      _cachedLogs = _cachedLogs.sublist(0, 1050);
    }
    await _persistLogs();
    _controller.add(List.unmodifiable(_cachedLogs));

    // Asynchronously synchronize with Supabase SQL database
    _supabaseService?.insert10MinTelemetry(data);
  }

  /// Returns ONLY the records for ONE specific full day (e.g. Today or Yesterday)
  /// Enforces daily rollover: after that day ends, only the next day's data is displayed
  List<SmartwatchDataModel> getDayRecords(DateTime date) {
    final targetDateString = DateFormat('yyyy-MM-dd').format(date);
    return _cachedLogs.where((record) => record.dateString == targetDateString).toList();
  }

  /// Get distinct available dates stored in the database, newest first
  List<String> getAvailableDates() {
    final Set<String> dateSet = {};
    for (final record in _cachedLogs) {
      dateSet.add(record.dateString);
    }
    final list = dateSet.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  /// All records in database
  List<SmartwatchDataModel> get currentLogs => List.unmodifiable(_cachedLogs);

  /// Stream of database logs
  Stream<List<SmartwatchDataModel>> watchLogs() => _controller.stream;

  /// Clear database
  Future<void> clearDatabase() async {
    _cachedLogs = [];
    await _persistLogs();
    _controller.add(List.unmodifiable(_cachedLogs));
  }

  /// Reset to standard full-day 10-minute seed
  Future<void> resetToSeed() async {
    _cachedLogs = _generateFullDay10MinuteRecords();
    await _persistLogs();
    _controller.add(List.unmodifiable(_cachedLogs));
  }

  void dispose() {
    _controller.close();
  }
}

final telemetryDbRepoProvider = Provider<TelemetryDatabaseRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  final repo = TelemetryDatabaseRepository(supabase);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final telemetryLogsStreamProvider = StreamProvider<List<SmartwatchDataModel>>((ref) {
  final repo = ref.watch(telemetryDbRepoProvider);
  return repo.watchLogs();
});
