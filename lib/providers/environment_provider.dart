import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnvironmentData {
  final double temperature;
  final double humidity;
  final double pm25;
  final double pm10;
  final bool isReal;
  final String? locationName;

  EnvironmentData({
    this.temperature = 0,
    this.humidity = 0,
    this.pm25 = 0,
    this.pm10 = 0,
    this.isReal = false,
    this.locationName,
  });

  EnvironmentData copyWith({
    double? temperature,
    double? humidity,
    double? pm25,
    double? pm10,
    bool? isReal,
    String? locationName,
  }) {
    return EnvironmentData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      isReal: isReal ?? this.isReal,
      locationName: locationName ?? this.locationName,
    );
  }
}

class EnvironmentDataNotifier extends StateNotifier<EnvironmentData> {
  EnvironmentDataNotifier() : super(EnvironmentData());

  void updateFromBluetooth({required double temperature, required double humidity}) {
    state = state.copyWith(
      temperature: temperature,
      humidity: humidity,
      isReal: true,
    );
  }

  void updateLocation(String location) {
    state = state.copyWith(locationName: location);
  }
}

final environmentDataProvider = StateNotifierProvider<EnvironmentDataNotifier, EnvironmentData>((ref) {
  return EnvironmentDataNotifier();
});