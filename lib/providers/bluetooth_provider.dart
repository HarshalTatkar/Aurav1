import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart'; // ✅ This imports ESP32BluetoothService
import '../providers/providers.dart';
import '../models/sensor_reading.dart';

// ✅ Use ESP32BluetoothService
final bluetoothServiceProvider = Provider<ESP32BluetoothService>((ref) {
  final service = ESP32BluetoothService();
  ref.onDispose(() => service.dispose());
  return service;
});

final bluetoothConnectionProvider = StateProvider<bool>((ref) => false);
final bluetoothDataProvider = StateProvider<Map<String, dynamic>>((ref) => {});
final bluetoothDeviceNameProvider = StateProvider<String>((ref) => '');
final bluetoothScanningProvider = StateProvider<bool>((ref) => false);
final bluetoothDevicesProvider = StateProvider<List<BluetoothDevice>>((ref) => []);

final bluetoothListenerProvider = Provider<void>((ref) {
  final service = ref.watch(bluetoothServiceProvider);
  
  service.connectionStatusStream.listen((connected) {
    ref.read(bluetoothConnectionProvider.notifier).state = connected;
  });
  
  service.sensorDataStream.listen((data) {
    ref.read(bluetoothDataProvider.notifier).state = data;
    _updateSensorData(ref, data);
  });
  
  return null;
});

// ✅ Fixed: Use ProviderRef instead of WidgetRef
void _updateSensorData(ProviderRef ref, Map<String, dynamic> btData) {
  try {
    final currentReading = ref.read(sensorDataProvider);
    final updatedReading = currentReading.copyWith(
      heartRate: btData['BPM']?.toDouble() ?? currentReading.heartRate,
      bodyTemperature: btData['TEMP']?.toDouble() ?? currentReading.bodyTemperature,
      ambientTemperature: btData['TEMP']?.toDouble() ?? currentReading.ambientTemperature,
      humidity: btData['HUMIDITY']?.toDouble() ?? currentReading.humidity,
      activityLevel: _calculateActivity(btData),
      fallDetected: _detectFall(btData),
      timestamp: DateTime.now(),
    );
    
    // ✅ Use the correct method to update sensor data
    ref.read(sensorDataProvider.notifier).state = updatedReading;
    
    // ✅ Update environment data
    final envData = ref.read(environmentDataProvider);
    ref.read(environmentDataProvider.notifier).state = envData.copyWith(
      temperature: btData['TEMP']?.toDouble() ?? envData.temperature,
      humidity: btData['HUMIDITY']?.toDouble() ?? envData.humidity,
      isReal: true,
    );
  } catch (e) {
    print("Error updating sensor data: $e");
  }
}

double _calculateActivity(Map<String, dynamic> data) {
  double ax = data['AX']?.toDouble() ?? 0;
  double ay = data['AY']?.toDouble() ?? 0;
  double az = data['AZ']?.toDouble() ?? 0;
  
  double magnitude = sqrt(ax * ax + ay * ay + az * az);
  double activity = ((magnitude - 9.8).abs() / 9.8).clamp(0, 1);
  return activity;
}

bool _detectFall(Map<String, dynamic> data) {
  double az = data['AZ']?.toDouble() ?? 0;
  return az < 2.0 && az > -2.0;
}