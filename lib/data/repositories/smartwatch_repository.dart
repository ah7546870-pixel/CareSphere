import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/smartwatch_data_model.dart';
import 'telemetry_database_repository.dart';

class SmartwatchRepository {
  final TelemetryDatabaseRepository? _dbRepo;
  final _controller = StreamController<SmartwatchDataModel>.broadcast();
  Timer? _timer;
  SmartwatchDataModel _latest = SmartwatchDataModel.mock();
  bool _isFastDemoMode = false;
  Duration _samplingInterval = const Duration(minutes: 10);
  DateTime _lastRecordedTime = DateTime.now();

  SmartwatchRepository([this._dbRepo]) {
    _startSamplingTimer();
  }

  void _startSamplingTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_samplingInterval, (timer) {
      if (_isFastDemoMode) {
        _generateAndRecordSample();
      } else {
        // Just emit the latest data to keep stream alive, without changing values randomly
        _controller.add(_latest);
      }
    });
  }

  /// Generates a new smartwatch reading with the exact current timestamp and saves to database
  SmartwatchDataModel _generateAndRecordSample() {
    final rand = Random();
    final deltaHr = rand.nextInt(5) - 2; // -2 to +2
    final baseHr = _latest.heartRate == 0 ? 74 : _latest.heartRate;
    final baseSpo2 = _latest.spO2 == 0 ? 98 : _latest.spO2;
    final baseSteps = _latest.steps == 0 ? 4120 : _latest.steps;
    final baseCal = _latest.caloriesBurned == 0 ? 1420 : _latest.caloriesBurned;

    final newHr = (baseHr + deltaHr).clamp(60, 115);
    final deltaSpO2 = rand.nextInt(3) - 1; // -1 to +1
    final newSpO2 = (baseSpo2 + deltaSpO2).clamp(93, 100);
    final deltaSteps = rand.nextInt(15) + 5;

    _lastRecordedTime = DateTime.now();
    _latest = SmartwatchDataModel(
      heartRate: newHr,
      spO2: newSpO2,
      sleepHours: 7.2,
      steps: baseSteps + deltaSteps,
      activityState: newHr > 90 ? 'Light Walking' : 'Resting in Armchair',
      caloriesBurned: baseCal + (deltaSteps > 0 ? 2 : 0),
      stressLevel: (24 + rand.nextInt(8)).clamp(10, 85),
      timestamp: _lastRecordedTime,
      isConnected: true,
    );

    // Save to database with exact timestamp
    _dbRepo?.logTelemetry(_latest);
    _controller.add(_latest);
    return _latest;
  }

  /// Manually sample smartwatch right now and commit to database with exact timestamp
  SmartwatchDataModel sampleAndRecordNow() {
    return _generateAndRecordSample();
  }

  /// Toggle between Standard 10-Minute interval and 10-Second Live Demo interval
  void toggleIntervalMode({required bool fastDemo}) {
    _isFastDemoMode = fastDemo;
    _samplingInterval = fastDemo ? const Duration(seconds: 10) : const Duration(minutes: 10);
    _startSamplingTimer();
  }

  Stream<SmartwatchDataModel> watchStream() => _controller.stream;
  SmartwatchDataModel get latest => _latest;
  DateTime get lastRecordedTime => _lastRecordedTime;
  bool get isFastDemoMode => _isFastDemoMode;
  Duration get samplingInterval => _samplingInterval;

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

final smartwatchRepoProvider = Provider<SmartwatchRepository>((ref) {
  final dbRepo = ref.watch(telemetryDbRepoProvider);
  final repo = SmartwatchRepository(dbRepo);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final smartwatchStreamProvider = StreamProvider<SmartwatchDataModel>((ref) {
  return ref.watch(smartwatchRepoProvider).watchStream();
});
