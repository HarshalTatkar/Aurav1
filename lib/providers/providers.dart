import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../data/models.dart';
import '../services/ble_manager.dart';
import '../services/risk_engine.dart';
import '../services/alert_service.dart';
import '../services/demo_engine.dart';
import '../services/sync_service.dart';
import '../services/environment_service.dart';
import 'package:geolocator/geolocator.dart';
import '../core/api_client.dart';

// ─── Auth Provider ───────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await ApiClient().getToken();
    if (token != null) {
      state = true;
    } else {
      // Auto login for development
      await login('test@example.com', 'password123');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await ApiClient().dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = response.data['access_token'];
      await ApiClient().saveToken(token);
      state = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      await ApiClient().dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });
      return await login(email, password);
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await ApiClient().clearToken();
    state = false;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) => AuthNotifier());


// ─── Settings Provider ───────────────────────────────────────────────────────
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  void update(AppSettings Function(AppSettings) fn) => state = fn(state);
  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);
  void setDemoMode(bool v) => state = state.copyWith(demoMode: v);
  void setDemoScenario(DemoScenario s) => state = state.copyWith(demoScenario: s);
  void setDisasterMode(DisasterMode m) => state = state.copyWith(disasterMode: m);
  void toggleHealthAlerts() => state = state.copyWith(healthAlerts: !state.healthAlerts);
  void toggleHeatAlerts() => state = state.copyWith(heatAlerts: !state.heatAlerts);
  void toggleAirQualityAlerts() =>
      state = state.copyWith(airQualityAlerts: !state.airQualityAlerts);
  void toggleWearableAlerts() =>
      state = state.copyWith(wearableAlerts: !state.wearableAlerts);
  void toggleDataSharing() => state = state.copyWith(dataSharing: !state.dataSharing);
  void toggleLocation() => state = state.copyWith(locationEnabled: !state.locationEnabled);
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) => SettingsNotifier());

// ─── Theme Provider ──────────────────────────────────────────────────────────
final themeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

// ─── Profile Provider ────────────────────────────────────────────────────────
class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier() : super(UserProfile.demo());

  void update(UserProfile Function(UserProfile) fn) => state = fn(state);
  void setBaseline(PersonalBaseline b) => state = state.copyWith(baseline: b);
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfile>((ref) => ProfileNotifier());

// ─── BLE Manager Provider ────────────────────────────────────────────────────
final bleManagerProvider = Provider<BleManager>((ref) {
  final settings = ref.watch(settingsProvider);
  final manager = BleManager(isDemoMode: settings.demoMode);
  ref.onDispose(() => manager.dispose());
  return manager;
});

// ─── Demo Engine Provider ────────────────────────────────────────────────────
final demoEngineProvider = Provider<DemoEngine>((ref) {
  final engine = DemoEngine();
  ref.onDispose(() => engine.dispose());
  return engine;
});

// ─── Sensor Data Provider ────────────────────────────────────────────────────
class SensorDataNotifier extends StateNotifier<SensorReading> {
  final DemoEngine _demoEngine;
  final BleManager _bleManager;
  final SyncService _syncService;
  final bool _isDemoMode;
  StreamSubscription? _subscription;
  final List<SensorReading> _history = [];

  SensorDataNotifier(this._demoEngine, this._bleManager, this._syncService, this._isDemoMode)
      : super(SensorReading.empty());

  List<SensorReading> get history => List.unmodifiable(_history);

  /// Start receiving sensor data
  void startListening() {
    _subscription?.cancel();

    if (_isDemoMode) {
      _subscription = _demoEngine.start(intervalMs: 2000).listen((reading) {
        state = reading;
        _addToHistory(reading);
        _syncService.syncReading(reading, 'wearable-1');
        _bleManager.updateSensorInfo(
          battery: reading.battery,
          lastSeen: reading.timestamp,
        );
      });
    } else {
      // Listen to API via WebSocket
      if (!_syncService.isConnected) {
        _syncService.connect();
      }
      _subscription = _syncService.onSensorReading.listen((reading) {
        state = reading;
        _addToHistory(reading);
        _bleManager.updateSensorInfo(
          battery: reading.battery,
          lastSeen: reading.timestamp,
        );
      });
    }
  }

  void stopListening() {
    _subscription?.cancel();
    if (_isDemoMode) _demoEngine.stop();
  }

  void _addToHistory(SensorReading reading) {
    _history.add(reading);
    // Keep last 2000 readings (~66 minutes at 2s intervals)
    if (_history.length > 2000) _history.removeAt(0);
  }

  /// Get history points for a specific metric
  List<SensorHistoryPoint> getHistoryFor(
    String metric, {
    Duration window = const Duration(hours: 1),
  }) {
    final cutoff = DateTime.now().subtract(window);
    return _history
        .where((r) => r.timestamp.isAfter(cutoff))
        .map((r) {
          double value;
          switch (metric) {
            case 'hr':
              value = r.heartRate;
            case 'spo2':
              value = r.spo2;
            case 'bodyTemp':
              value = r.bodyTemperature;
            case 'ambientTemp':
              value = r.ambientTemperature;
            case 'humidity':
              value = r.humidity;
            case 'pm25':
              value = r.pm25;
            case 'pm10':
              value = r.pm10;
            case 'activity':
              value = r.activityLevel;
            default:
              value = 0;
          }
          return SensorHistoryPoint(r.timestamp, value);
        })
        .toList();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

final sensorDataProvider =
    StateNotifierProvider<SensorDataNotifier, SensorReading>((ref) {
  final settings = ref.watch(settingsProvider);
  final demoEngine = ref.watch(demoEngineProvider);
  final bleManager = ref.watch(bleManagerProvider);
  final syncService = ref.watch(syncServiceProvider);
  final notifier = SensorDataNotifier(demoEngine, bleManager, syncService, settings.demoMode);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

// ─── Risk Assessment Provider ────────────────────────────────────────────────
final riskProvider = Provider<RiskAssessment>((ref) {
  final reading = ref.watch(sensorDataProvider);
  final profile = ref.watch(profileProvider);
  final settings = ref.watch(settingsProvider);

  if (reading.heartRate <= 0) return RiskAssessment.initial();

  final engine = RiskEngine(profile.baseline);
  return engine.assess(reading, disaster: settings.disasterMode);
});

final cloudRiskRecommendationProvider = FutureProvider<String?>((ref) async {
  final syncService = ref.read(syncServiceProvider);
  return await syncService.fetchAiRecommendation();
});

// ─── Alert Service Provider ──────────────────────────────────────────────────
final alertServiceProvider = Provider<AlertService>((ref) {
  final service = AlertService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ─── Alerts List Provider ────────────────────────────────────────────────────
class AlertsNotifier extends StateNotifier<List<HealthAlert>> {
  final AlertService _service;
  StreamSubscription? _sub;

  AlertsNotifier(this._service) : super(_service.alerts) {
    _sub = _service.onAlert.listen((_) {
      state = List.from(_service.alerts);
    });
  }

  void acknowledge(String id) {
    _service.acknowledge(id);
    state = List.from(_service.alerts);
  }

  void resolve(String id) {
    _service.resolve(id);
    state = List.from(_service.alerts);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, List<HealthAlert>>((ref) {
  final service = ref.watch(alertServiceProvider);
  return AlertsNotifier(service);
});

// ─── Device State Provider ───────────────────────────────────────────────────
class DeviceStateNotifier extends StateNotifier<({DeviceInfo sensor, DeviceInfo wearable})> {
  final BleManager _bleManager;

  DeviceStateNotifier(this._bleManager)
      : super((sensor: _bleManager.sensorDevice, wearable: _bleManager.wearableDevice));

  Future<void> connectSensor() async {
    await _bleManager.connectSensor();
    _refresh();
  }

  Future<void> connectWearable() async {
    await _bleManager.connectWearable();
    _refresh();
  }

  Future<void> disconnectSensor() async {
    await _bleManager.disconnectSensor();
    _refresh();
  }

  Future<void> disconnectWearable() async {
    await _bleManager.disconnectWearable();
    _refresh();
  }

  Future<bool> sendCommand(WearableCommand cmd) async {
    final result = await _bleManager.sendWearableCommand(cmd);
    _refresh();
    return result;
  }

  void _refresh() {
    state = (sensor: _bleManager.sensorDevice, wearable: _bleManager.wearableDevice);
  }
}

final deviceStateProvider = StateNotifierProvider<DeviceStateNotifier,
    ({DeviceInfo sensor, DeviceInfo wearable})>((ref) {
  final bleManager = ref.watch(bleManagerProvider);
  return DeviceStateNotifier(bleManager);
});

// ─── Health Processing Provider (orchestrates risk → alerts → wearable) ─────
final healthProcessorProvider = Provider<void>((ref) {
  final reading = ref.watch(sensorDataProvider);
  final risk = ref.watch(riskProvider);
  final profile = ref.watch(profileProvider);
  final alertService = ref.read(alertServiceProvider);
  final settings = ref.watch(settingsProvider);

  if (reading.heartRate <= 0) return;
  if (!settings.healthAlerts) return;

  // Evaluate alerts
  alertService.evaluate(reading, risk, profile.baseline);

  // Determine wearable command
  if (settings.wearableAlerts) {
    final cmd = alertService.getWearableCommand(risk, reading);
    if (cmd != null && cmd != WearableCommand.normal) {
      final bleManager = ref.read(bleManagerProvider);
      bleManager.sendWearableCommand(cmd);
    }
  }
});

// ─── Environment Provider ───────────────────────────────────────────────────
final environmentServiceProvider = Provider<EnvironmentService>((ref) {
  return EnvironmentService();
});

class EnvironmentDataNotifier extends StateNotifier<EnvironmentData> {
  final EnvironmentService _service;
  Timer? _timer;
  StreamSubscription<Position>? _positionSub;

  EnvironmentDataNotifier(this._service) : super(EnvironmentData(
        temperature: 28.0,
        humidity: 50.0,
        pm25: 18.0,
        pm10: 35.0,
        fetchedAt: DateTime.now(),
        locationName: 'Fetching Location...',
        isReal: false,
      )) {
    _fetchData();
    _listenToLocationChanges();
    // Also refresh every 2 minutes for weather updates even without movement
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      _fetchData();
    });
  }

  void _listenToLocationChanges() {
    try {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // MUST be high for Emulator GPS
          distanceFilter: 500, // Only trigger on 500m+ movement
        ),
      ).listen((_) {
        // Location changed — refetch everything
        _fetchData();
      });
    } catch (_) {
      // Position stream not available (e.g. web), rely on timer
    }
  }

  Future<void> _fetchData() async {
    final data = await _service.fetchEnvironmentData();
    if (mounted) {
      state = data;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }
}

final environmentDataProvider = StateNotifierProvider<EnvironmentDataNotifier, EnvironmentData>((ref) {
  final service = ref.watch(environmentServiceProvider);
  return EnvironmentDataNotifier(service);
});

