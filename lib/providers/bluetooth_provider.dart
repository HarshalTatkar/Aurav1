import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart';
import '../providers/providers.dart';
import '../data/models.dart'; // Use the SAME SensorReading as providers.dart

// ─── ESP32 Bluetooth Service Provider ────────────────────────────────────────
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

// ─── BLE Data Listener ──────────────────────────────────────────────────────
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

// ─── Map BLE JSON → SensorReading + EnvironmentData ─────────────────────────
void _updateSensorData(ProviderRef ref, Map<String, dynamic> btData) {
  try {
    print("📊 BLE data received: $btData");
    
    final currentReading = ref.read(sensorDataProvider);
    
    // Parse values from ESP32 JSON
    final bpm = btData['BPM']?.toDouble() ?? 0.0;
    final temp = btData['TEMP']?.toDouble() ?? 0.0;
    final humidity = btData['HUMIDITY']?.toDouble() ?? 0.0;
    final finger = btData['FINGER'] ?? 0;
    
    // Only use BPM if finger is detected on the sensor, otherwise clear it to 0
    final heartRate = (finger == 1 && bpm > 0) ? bpm : 0.0;
    
    final updatedReading = SensorReading(
      deviceId: currentReading.deviceId.isEmpty ? 'esp32-ble' : currentReading.deviceId,
      timestamp: DateTime.now(),
      heartRate: heartRate,
      spo2: currentReading.spo2, // ESP32 doesn't send SpO2 directly
      bodyTemperature: temp > 0 ? temp : 0.0,
      ambientTemperature: temp > 0 ? temp : 0.0,
      humidity: humidity > 0 ? humidity : 0.0,
      pm25: currentReading.pm25,
      pm10: currentReading.pm10,
      activityLevel: _calculateActivity(btData),
      fallDetected: _detectFall(btData),
      battery: currentReading.battery,
    );
    
    // Update the sensor data provider — use the notifier's update method
    ref.read(sensorDataProvider.notifier).updateFromBle(updatedReading);
    
    // Update environment data with BLE temp/humidity
    final envNotifier = ref.read(environmentDataProvider.notifier);
    if (temp > 0 || humidity > 0) {
      envNotifier.updateFromBluetooth(
        temperature: temp > 0 ? temp : null,
        humidity: humidity > 0 ? humidity : null,
      );
    } else {
      envNotifier.clearBleData();
    }
    
    print("✅ Sensor updated — HR: ${updatedReading.heartRate}, Temp: ${updatedReading.bodyTemperature}, Humidity: ${updatedReading.humidity}");
  } catch (e) {
    print("❌ Error updating sensor data from BLE: $e");
  }
}

double _calculateActivity(Map<String, dynamic> data) {
  double ax = data['AX']?.toDouble() ?? 0;
  double ay = data['AY']?.toDouble() ?? 0;
  double az = data['AZ']?.toDouble() ?? 0;
  
  double magnitude = sqrt(ax * ax + ay * ay + az * az);
  
  // If the ESP32 doesn't subtract gravity, magnitude will be ~9.8 when still.
  // If it already subtracts gravity, magnitude will be ~0 when still.
  // We determine the baseline dynamically based on the current reading.
  double baseline = (magnitude > 5.0 && magnitude < 15.0) ? 9.8 : 0.0;
  
  // Calculate how far off the magnitude is from the baseline
  double diff = (magnitude - baseline).abs();
  
  // If diff is very small (e.g., sensor noise while resting), clamp it to 0
  if (diff < 0.5) return 0.0;
  
  // Map the difference to a 0.0 - 1.0 scale (where 9.8m/s² extra force = 100% activity)
  double activity = (diff / 9.8).clamp(0.0, 1.0);
  return activity;
}

bool _detectFall(Map<String, dynamic> data) {
  double ax = data['AX']?.toDouble() ?? 0;
  double ay = data['AY']?.toDouble() ?? 0;
  double az = data['AZ']?.toDouble() ?? 0;
  
  // Fall = sudden freefall (total acceleration near 0) followed by impact
  double magnitude = sqrt(ax * ax + ay * ay + az * az);
  return magnitude < 3.0; // Near-freefall condition
}