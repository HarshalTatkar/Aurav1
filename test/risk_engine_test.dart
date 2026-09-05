import 'package:flutter_test/flutter_test.dart';
import 'package:aura/services/risk_engine.dart';
import 'package:aura/data/models.dart';
import 'package:aura/core/constants.dart';

void main() {
  late RiskEngine engine;

  setUp(() {
    engine = RiskEngine(const PersonalBaseline());
  });

  group('RiskEngine', () {
    test('normal readings produce low risk', () {
      final reading = SensorReading(
        deviceId: 'TEST',
        timestamp: DateTime.now(),
        heartRate: 72,
        spo2: 98,
        bodyTemperature: 36.6,
        ambientTemperature: 28,
        humidity: 50,
        pm25: 18,
        pm10: 35,
        activityLevel: 0.25,
        fallDetected: false,
        battery: 90,
      );

      final result = engine.assess(reading);
      expect(result.score, lessThanOrEqualTo(30));
      expect(result.level, RiskLevel.low);
      expect(result.recommendations, isNotEmpty);
    });

    test('heatwave scenario produces high risk', () {
      final reading = SensorReading(
        deviceId: 'TEST',
        timestamp: DateTime.now(),
        heartRate: 108,
        spo2: 96,
        bodyTemperature: 37.8,
        ambientTemperature: 39,
        humidity: 75,
        pm25: 82,
        pm10: 130,
        activityLevel: 0.72,
        fallDetected: false,
        battery: 87,
      );

      final result = engine.assess(reading, disaster: DisasterMode.heatwave);
      expect(result.score, greaterThan(60));
      expect(result.level, isIn([RiskLevel.high, RiskLevel.critical]));
      expect(result.factors, isNotEmpty);
      expect(result.factors.any((f) => f.name == 'Heart Rate'), isTrue);
      expect(result.recommendations.any((r) => r.contains('cool')), isTrue);
    });

    test('critical scenario produces critical risk', () {
      final reading = SensorReading(
        deviceId: 'TEST',
        timestamp: DateTime.now(),
        heartRate: 128,
        spo2: 89,
        bodyTemperature: 39.1,
        ambientTemperature: 41,
        humidity: 82,
        pm25: 95,
        pm10: 160,
        activityLevel: 0.15,
        fallDetected: true,
        battery: 45,
      );

      final result = engine.assess(reading);
      expect(result.score, greaterThan(80));
      expect(result.level, RiskLevel.critical);
      expect(result.factors.any((f) => f.name == 'Fall Detected'), isTrue);
    });

    test('low SpO2 generates contributing factor', () {
      final reading = SensorReading(
        deviceId: 'TEST',
        timestamp: DateTime.now(),
        heartRate: 75,
        spo2: 90,
        bodyTemperature: 36.7,
        ambientTemperature: 25,
        humidity: 45,
        pm25: 10,
        pm10: 20,
        activityLevel: 0.1,
        fallDetected: false,
        battery: 80,
      );

      final result = engine.assess(reading);
      expect(result.factors.any((f) => f.name == 'Blood Oxygen'), isTrue);
      expect(result.score, greaterThan(10));
    });

    test('risk score is clamped 0-100', () {
      // Extreme values
      final reading = SensorReading(
        deviceId: 'TEST',
        timestamp: DateTime.now(),
        heartRate: 180,
        spo2: 80,
        bodyTemperature: 41,
        ambientTemperature: 50,
        humidity: 95,
        pm25: 400,
        pm10: 500,
        activityLevel: 0.95,
        fallDetected: true,
        battery: 10,
      );

      final result = engine.assess(reading, disaster: DisasterMode.heatwave);
      expect(result.score, lessThanOrEqualTo(100));
      expect(result.score, greaterThanOrEqualTo(0));
    });

    test('confidence increases with calibrated baseline', () {
      final calibratedBaseline = PersonalBaseline(
        hrLow: 65,
        hrHigh: 78,
        hrAvg: 71,
        spo2Low: 97,
        spo2Avg: 99,
        bodyTempLow: 36.3,
        bodyTempHigh: 36.8,
        bodyTempAvg: 36.5,
        calibratedAt: DateTime.now(),
        readingsCount: 50,
      );

      final calibratedEngine = RiskEngine(calibratedBaseline);

      final reading = SensorReading(
        deviceId: 'TEST',
        timestamp: DateTime.now(),
        heartRate: 75,
        spo2: 98,
        bodyTemperature: 36.6,
        ambientTemperature: 28,
        humidity: 50,
        pm25: 15,
        pm10: 30,
        activityLevel: 0.2,
        fallDetected: false,
        battery: 90,
      );

      final defaultResult = engine.assess(reading);
      final calibratedResult = calibratedEngine.assess(reading);

      expect(calibratedResult.confidence, greaterThan(defaultResult.confidence));
    });

    test('pattern text describes contributing factors', () {
      final reading = SensorReading(
        deviceId: 'TEST',
        timestamp: DateTime.now(),
        heartRate: 110,
        spo2: 97,
        bodyTemperature: 37.5,
        ambientTemperature: 40,
        humidity: 78,
        pm25: 20,
        pm10: 30,
        activityLevel: 0.6,
        fallDetected: false,
        battery: 85,
      );

      final result = engine.assess(reading);
      expect(result.pattern, isNotEmpty);
      expect(result.pattern, isNot('Waiting for sensor data...'));
    });
  });
}
