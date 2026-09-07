import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_reading.dart';

class SensorDataNotifier extends StateNotifier<SensorReading> {
  SensorDataNotifier() : super(SensorReading.initial());

  void updateReading(SensorReading newReading) {
    state = state.copyWith(
      heartRate: newReading.heartRate > 0 ? newReading.heartRate : state.heartRate,
      spo2: newReading.spo2 > 0 ? newReading.spo2 : state.spo2,
      bodyTemperature: newReading.bodyTemperature > 0 ? newReading.bodyTemperature : state.bodyTemperature,
      ambientTemperature: newReading.ambientTemperature > 0 ? newReading.ambientTemperature : state.ambientTemperature,
      humidity: newReading.humidity > 0 ? newReading.humidity : state.humidity,
      activityLevel: newReading.activityLevel > 0 ? newReading.activityLevel : state.activityLevel,
      fallDetected: newReading.fallDetected,
      timestamp: DateTime.now(),
    );
  }

  void startListening() {
    // This will be triggered by Bluetooth listener
  }
}

final sensorDataProvider = StateNotifierProvider<SensorDataNotifier, SensorReading>((ref) {
  return SensorDataNotifier();
});