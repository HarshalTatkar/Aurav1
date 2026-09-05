import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../data/models.dart';

/// Abstraction layer for BLE communication.
/// In demo mode, simulates device connections.
/// In real mode, would use flutter_blue_plus.
class BleManager {
  final bool isDemoMode;
  DeviceConnectionState _wearableState = DeviceConnectionState.disconnected;

  final StreamController<DeviceConnectionState> _sensorStateController =
      StreamController<DeviceConnectionState>.broadcast();
  final StreamController<DeviceConnectionState> _wearableStateController =
      StreamController<DeviceConnectionState>.broadcast();

  DeviceInfo _sensorDevice = const DeviceInfo(
    id: 'AURA_SENSOR_001',
    name: 'AURA Sensor',
    type: AuraDeviceType.sensor,
  );

  DeviceInfo _wearableDevice = const DeviceInfo(
    id: 'AURA_WEARABLE_001',
    name: 'AURA Wearable',
    type: AuraDeviceType.wearable,
  );

  BleManager({this.isDemoMode = true});

  DeviceInfo get sensorDevice => _sensorDevice;
  DeviceInfo get wearableDevice => _wearableDevice;
  Stream<DeviceConnectionState> get sensorStateStream => _sensorStateController.stream;
  Stream<DeviceConnectionState> get wearableStateStream => _wearableStateController.stream;

  /// Connect to sensor device
  Future<bool> connectSensor() async {
    _setSensorState(DeviceConnectionState.connecting);

    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 1500));
      _sensorDevice = _sensorDevice.copyWith(
        connectionState: DeviceConnectionState.connected,
        battery: 92,
        lastSeen: DateTime.now(),
        signalStrength: -55,
      );
      _setSensorState(DeviceConnectionState.connected);
      return true;
    }

    // Real BLE connection would go here using flutter_blue_plus
    // For now, return false in non-demo mode
    _setSensorState(DeviceConnectionState.disconnected);
    return false;
  }

  /// Connect to wearable device
  Future<bool> connectWearable() async {
    _setSensorState2(DeviceConnectionState.connecting);

    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 1200));
      _wearableDevice = _wearableDevice.copyWith(
        connectionState: DeviceConnectionState.connected,
        battery: 78,
        lastSeen: DateTime.now(),
        signalStrength: -62,
      );
      _setSensorState2(DeviceConnectionState.connected);
      return true;
    }

    _setSensorState2(DeviceConnectionState.disconnected);
    return false;
  }

  /// Disconnect sensor
  Future<void> disconnectSensor() async {
    _sensorDevice = _sensorDevice.copyWith(
      connectionState: DeviceConnectionState.disconnected,
    );
    _setSensorState(DeviceConnectionState.disconnected);
  }

  /// Disconnect wearable
  Future<void> disconnectWearable() async {
    _wearableDevice = _wearableDevice.copyWith(
      connectionState: DeviceConnectionState.disconnected,
    );
    _setSensorState2(DeviceConnectionState.disconnected);
  }

  /// Send command to wearable
  Future<bool> sendWearableCommand(WearableCommand command) async {
    if (_wearableState != DeviceConnectionState.connected) return false;

    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      debugPrint('[BLE] Sent wearable command: ${command.code}');
      _wearableDevice = _wearableDevice.copyWith(lastSeen: DateTime.now());
      return true;
    }

    // Real BLE write would go here
    return false;
  }

  /// Update sensor device info (battery drain simulation etc.)
  void updateSensorInfo({int? battery, DateTime? lastSeen}) {
    _sensorDevice = _sensorDevice.copyWith(
      battery: battery,
      lastSeen: lastSeen ?? DateTime.now(),
    );
  }

  void _setSensorState(DeviceConnectionState state) {
    _sensorStateController.add(state);
  }

  void _setSensorState2(DeviceConnectionState state) {
    _wearableState = state;
    _wearableStateController.add(state);
  }

  void dispose() {
    _sensorStateController.close();
    _wearableStateController.close();
  }
}
