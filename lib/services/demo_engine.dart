import 'dart:async';
import 'dart:math';
import '../core/constants.dart';
import '../data/models.dart';

/// Generates realistic simulated sensor data for demo/presentation mode.
/// Values transition smoothly between scenarios rather than jumping.
class DemoEngine {
  final Random _random = Random();
  Timer? _timer;
  StreamController<SensorReading>? _controller;

  DemoScenario _currentScenario = DemoScenario.normal;
  DemoScenario _targetScenario = DemoScenario.normal;

  // Real environment override
  EnvironmentData? _realEnvData;

  // Current simulated values (smooth transitions)
  double _hr = 72;
  double _spo2 = 98;
  double _bodyTemp = 36.6;
  double _ambientTemp = 28;
  double _humidity = 50;
  double _pm25 = 18;
  double _pm10 = 35;
  double _activity = 0.25;
  bool _fallDetected = false;
  int _battery = 92;
  int _ticksSinceFall = 0;
  DateTime _scenarioStartTime = DateTime.now();

  DemoScenario get currentScenario => _currentScenario;

  /// Start the simulation engine, emitting readings at the given interval
  Stream<SensorReading> start({int intervalMs = 2000}) {
    _controller?.close();
    _controller = StreamController<SensorReading>.broadcast();
    _timer?.cancel();

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _tick();
      _controller?.add(_currentReading());
    });

    // Emit initial reading immediately
    Future.microtask(() => _controller?.add(_currentReading()));
    return _controller!.stream;
  }

  /// Stop the simulation
  void stop() {
    _timer?.cancel();
    _controller?.close();
  }

  /// Switch to a new scenario — values will smoothly transition
  void setScenario(DemoScenario scenario) {
    _targetScenario = scenario;
    _scenarioStartTime = DateTime.now();

    // Fall is instant
    if (scenario == DemoScenario.fall) {
      _fallDetected = true;
      _ticksSinceFall = 0;
    } else {
      _fallDetected = false;
    }
  }

  /// Override the simulated environment data with real data
  void setRealEnvironmentData(EnvironmentData data) {
    if (data.isReal) {
      _realEnvData = data;
    }
  }

  // ─── Target values per scenario ────────────────────────────────────────

  _ScenarioTargets _targets(DemoScenario scenario) {
    switch (scenario) {
      case DemoScenario.normal:
        return _ScenarioTargets(
          hr: 72, spo2: 98, bodyTemp: 36.6,
          ambientTemp: 28, humidity: 50,
          pm25: 18, pm10: 35, activity: 0.25,
        );
      case DemoScenario.heatwave:
        return _ScenarioTargets(
          hr: 108, spo2: 96, bodyTemp: 37.8,
          ambientTemp: 39, humidity: 75,
          pm25: 82, pm10: 130, activity: 0.72,
        );
      case DemoScenario.critical:
        return _ScenarioTargets(
          hr: 128, spo2: 89, bodyTemp: 39.1,
          ambientTemp: 41, humidity: 82,
          pm25: 95, pm10: 160, activity: 0.15,
        );
      case DemoScenario.fall:
        return _ScenarioTargets(
          hr: 95, spo2: 95, bodyTemp: 37.0,
          ambientTemp: 30, humidity: 55,
          pm25: 25, pm10: 45, activity: 0.05,
        );
      case DemoScenario.airPollution:
        return _ScenarioTargets(
          hr: 82, spo2: 94, bodyTemp: 36.8,
          ambientTemp: 32, humidity: 60,
          pm25: 180, pm10: 280, activity: 0.3,
        );
    }
  }

  // ─── Simulation tick ───────────────────────────────────────────────────

  void _tick() {
    final target = _targets(_targetScenario);
    const smoothing = 0.08; // How fast values transition (0-1)

    // Smooth interpolation toward targets
    _hr = _lerp(_hr, target.hr, smoothing) + _noise(1.5);
    _spo2 = (_lerp(_spo2, target.spo2, smoothing) + _noise(0.3)).clamp(70, 100);
    _bodyTemp = _lerp(_bodyTemp, target.bodyTemp, smoothing) + _noise(0.05);
    _activity = (_lerp(_activity, target.activity, smoothing) + _noise(0.02)).clamp(0, 1);

    if (_realEnvData != null) {
      // Use real environment data directly (no scenario targets)
      _ambientTemp = _lerp(_ambientTemp, _realEnvData!.temperature, smoothing) + _noise(0.1);
      _humidity = (_lerp(_humidity, _realEnvData!.humidity, smoothing) + _noise(0.1)).clamp(0, 100);
      _pm25 = (_lerp(_pm25, _realEnvData!.pm25, smoothing) + _noise(0.5)).clamp(0, 500);
      _pm10 = (_lerp(_pm10, _realEnvData!.pm10, smoothing) + _noise(0.5)).clamp(0, 500);
    } else {
      // Simulated environment data
      _ambientTemp = _lerp(_ambientTemp, target.ambientTemp, smoothing) + _noise(0.3);
      _humidity = (_lerp(_humidity, target.humidity, smoothing) + _noise(0.5)).clamp(0, 100);
      _pm25 = (_lerp(_pm25, target.pm25, smoothing) + _noise(2.0)).clamp(0, 500);
      _pm10 = (_lerp(_pm10, target.pm10, smoothing) + _noise(3.0)).clamp(0, 500);
    }

    // Battery slowly drains
    if (_random.nextInt(20) == 0 && _battery > 5) _battery--;

    // Auto-resolve fall after ~10 seconds
    if (_fallDetected) {
      _ticksSinceFall++;
      if (_ticksSinceFall > 5) {
        _fallDetected = false;
      }
    }

    // Update current scenario label once values are close
    if (_targetScenario != _currentScenario) {
      final elapsed = DateTime.now().difference(_scenarioStartTime).inSeconds;
      if (elapsed > 8) _currentScenario = _targetScenario;
    }
  }

  double _lerp(double current, double target, double t) {
    return current + (target - current) * t;
  }

  double _noise(double amplitude) {
    return (_random.nextDouble() - 0.5) * 2 * amplitude;
  }

  SensorReading _currentReading() {
    return SensorReading(
      deviceId: 'AURA_DEMO_SENSOR',
      timestamp: DateTime.now(),
      heartRate: double.parse(_hr.toStringAsFixed(1)),
      spo2: double.parse(_spo2.toStringAsFixed(1)),
      bodyTemperature: double.parse(_bodyTemp.toStringAsFixed(2)),
      ambientTemperature: double.parse(_ambientTemp.toStringAsFixed(1)),
      humidity: double.parse(_humidity.toStringAsFixed(1)),
      pm25: double.parse(_pm25.toStringAsFixed(1)),
      pm10: double.parse(_pm10.toStringAsFixed(1)),
      activityLevel: double.parse(_activity.toStringAsFixed(3)),
      fallDetected: _fallDetected,
      battery: _battery,
    );
  }

  void dispose() {
    stop();
  }
}

class _ScenarioTargets {
  final double hr, spo2, bodyTemp, ambientTemp, humidity, pm25, pm10, activity;
  const _ScenarioTargets({
    required this.hr, required this.spo2, required this.bodyTemp,
    required this.ambientTemp, required this.humidity,
    required this.pm25, required this.pm10, required this.activity,
  });
}
