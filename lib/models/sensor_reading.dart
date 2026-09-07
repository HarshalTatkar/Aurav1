class SensorReading {
  final double heartRate;
  final double spo2;
  final double bodyTemperature;
  final double ambientTemperature;
  final double humidity;
  final double pm25;
  final double pm10;
  final double activityLevel;
  final bool fallDetected;
  final DateTime timestamp;

  SensorReading({
    this.heartRate = 0,
    this.spo2 = 0,
    this.bodyTemperature = 0,
    this.ambientTemperature = 0,
    this.humidity = 0,
    this.pm25 = 0,
    this.pm10 = 0,
    this.activityLevel = 0,
    this.fallDetected = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  SensorReading copyWith({
    double? heartRate,
    double? spo2,
    double? bodyTemperature,
    double? ambientTemperature,
    double? humidity,
    double? pm25,
    double? pm10,
    double? activityLevel,
    bool? fallDetected,
    DateTime? timestamp,
  }) {
    return SensorReading(
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      bodyTemperature: bodyTemperature ?? this.bodyTemperature,
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      humidity: humidity ?? this.humidity,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      activityLevel: activityLevel ?? this.activityLevel,
      fallDetected: fallDetected ?? this.fallDetected,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory SensorReading.initial() {
    return SensorReading();
  }
}