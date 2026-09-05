import 'package:flutter_test/flutter_test.dart';
import 'package:aura/data/models.dart';
import 'package:aura/core/constants.dart';
import 'package:aura/core/utils.dart';

void main() {
  group('SensorReading', () {
    test('fromJson parses correctly', () {
      final json = {
        'deviceId': 'SENSOR_001',
        'timestamp': '2026-09-02T12:30:00Z',
        'heartRate': 108,
        'spo2': 96,
        'bodyTemperature': 37.8,
        'ambientTemperature': 39.0,
        'humidity': 75,
        'pm25': 82,
        'pm10': 130,
        'activityLevel': 0.82,
        'fallDetected': false,
        'battery': 87,
      };

      final reading = SensorReading.fromJson(json);
      expect(reading.deviceId, 'SENSOR_001');
      expect(reading.heartRate, 108);
      expect(reading.spo2, 96);
      expect(reading.bodyTemperature, 37.8);
      expect(reading.ambientTemperature, 39.0);
      expect(reading.humidity, 75);
      expect(reading.pm25, 82);
      expect(reading.pm10, 130);
      expect(reading.activityLevel, 0.82);
      expect(reading.fallDetected, false);
      expect(reading.battery, 87);
    });

    test('toJson round trips', () {
      final original = SensorReading(
        deviceId: 'TEST',
        timestamp: DateTime(2026, 1, 1),
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

      final json = original.toJson();
      final restored = SensorReading.fromJson(json);

      expect(restored.heartRate, original.heartRate);
      expect(restored.spo2, original.spo2);
      expect(restored.bodyTemperature, original.bodyTemperature);
      expect(restored.fallDetected, original.fallDetected);
    });

    test('empty reading has zero values', () {
      final empty = SensorReading.empty();
      expect(empty.heartRate, 0);
      expect(empty.spo2, 0);
      expect(empty.battery, 0);
    });

    test('copyWith preserves unchanged fields', () {
      final original = SensorReading(
        deviceId: 'TEST', timestamp: DateTime.now(),
        heartRate: 72, spo2: 98, bodyTemperature: 36.6,
        ambientTemperature: 28, humidity: 50,
        pm25: 18, pm10: 35, activityLevel: 0.25,
        fallDetected: false, battery: 90,
      );

      final modified = original.copyWith(heartRate: 100);
      expect(modified.heartRate, 100);
      expect(modified.spo2, 98);
      expect(modified.deviceId, 'TEST');
    });
  });

  group('PersonalBaseline', () {
    test('default baseline has expected ranges', () {
      const baseline = PersonalBaseline();
      expect(baseline.hrLow, 62);
      expect(baseline.hrHigh, 82);
      expect(baseline.spo2Low, 96);
      expect(baseline.isCalibrated, false);
    });

    test('calibrated when readings >= 30', () {
      const baseline = PersonalBaseline(readingsCount: 30);
      expect(baseline.isCalibrated, true);
    });
  });

  group('RiskLevel', () {
    test('fromScore maps correctly', () {
      expect(RiskLevel.fromScore(0), RiskLevel.low);
      expect(RiskLevel.fromScore(30), RiskLevel.low);
      expect(RiskLevel.fromScore(31), RiskLevel.moderate);
      expect(RiskLevel.fromScore(60), RiskLevel.moderate);
      expect(RiskLevel.fromScore(61), RiskLevel.high);
      expect(RiskLevel.fromScore(80), RiskLevel.high);
      expect(RiskLevel.fromScore(81), RiskLevel.critical);
      expect(RiskLevel.fromScore(100), RiskLevel.critical);
    });
  });

  group('Utils', () {
    test('heat index calculation', () {
      final hi = calculateHeatIndex(35, 70);
      expect(hi, greaterThan(35));
    });

    test('AQI labels are correct', () {
      expect(aqiLabel(10), 'Good');
      expect(aqiLabel(30), 'Moderate');
      expect(aqiLabel(100), 'Unhealthy');
      expect(aqiLabel(300), 'Hazardous');
    });

    test('sensor validation', () {
      expect(isValidHr(72), true);
      expect(isValidHr(0), false);
      expect(isValidHr(250), false);
      expect(isValidSpo2(98), true);
      expect(isValidSpo2(60), false);
    });

    test('greeting returns time-appropriate text', () {
      final greeting = getGreeting();
      expect(greeting, isIn(['Good morning', 'Good afternoon', 'Good evening']));
    });
  });
}
