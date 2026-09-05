import 'package:flutter_test/flutter_test.dart';
import 'package:aura/services/alert_service.dart';
import 'package:aura/data/models.dart';
import 'package:aura/core/constants.dart';

void main() {
  late AlertService service;

  setUp(() {
    service = AlertService();
  });

  tearDown(() {
    service.dispose();
  });

  group('AlertService', () {
    test('no alerts for normal readings', () {
      final reading = SensorReading(
        deviceId: 'TEST', timestamp: DateTime.now(),
        heartRate: 72, spo2: 98, bodyTemperature: 36.6,
        ambientTemperature: 28, humidity: 50,
        pm25: 18, pm10: 35, activityLevel: 0.25,
        fallDetected: false, battery: 90,
      );
      final risk = RiskAssessment(
        score: 15, level: RiskLevel.low,
        factors: [], pattern: '', recommendations: [],
        confidence: 0.7, timestamp: DateTime.now(),
      );
      const baseline = PersonalBaseline();

      service.evaluate(reading, risk, baseline);
      expect(service.alerts, isEmpty);
    });

    test('creates alert for elevated heart rate', () {
      final reading = SensorReading(
        deviceId: 'TEST', timestamp: DateTime.now(),
        heartRate: 115, spo2: 98, bodyTemperature: 36.6,
        ambientTemperature: 28, humidity: 50,
        pm25: 18, pm10: 35, activityLevel: 0.25,
        fallDetected: false, battery: 90,
      );
      final risk = RiskAssessment(
        score: 40, level: RiskLevel.moderate,
        factors: [], pattern: '', recommendations: [],
        confidence: 0.7, timestamp: DateTime.now(),
      );
      const baseline = PersonalBaseline();

      service.evaluate(reading, risk, baseline);
      expect(service.alerts.any((a) => a.type == AlertType.elevatedHr), isTrue);
    });

    test('creates alert for fall detection', () {
      final reading = SensorReading(
        deviceId: 'TEST', timestamp: DateTime.now(),
        heartRate: 72, spo2: 98, bodyTemperature: 36.6,
        ambientTemperature: 28, humidity: 50,
        pm25: 18, pm10: 35, activityLevel: 0.05,
        fallDetected: true, battery: 90,
      );
      final risk = RiskAssessment(
        score: 50, level: RiskLevel.moderate,
        factors: [], pattern: '', recommendations: [],
        confidence: 0.7, timestamp: DateTime.now(),
      );
      const baseline = PersonalBaseline();

      service.evaluate(reading, risk, baseline);
      expect(service.alerts.any((a) => a.type == AlertType.fallDetected), isTrue);
      expect(service.alerts.first.severity, AlertSeverity.critical);
    });

    test('alert cooldown prevents duplicates', () {
      final reading = SensorReading(
        deviceId: 'TEST', timestamp: DateTime.now(),
        heartRate: 115, spo2: 98, bodyTemperature: 36.6,
        ambientTemperature: 28, humidity: 50,
        pm25: 18, pm10: 35, activityLevel: 0.25,
        fallDetected: false, battery: 90,
      );
      final risk = RiskAssessment(
        score: 40, level: RiskLevel.moderate,
        factors: [], pattern: '', recommendations: [],
        confidence: 0.7, timestamp: DateTime.now(),
      );
      const baseline = PersonalBaseline();

      service.evaluate(reading, risk, baseline);
      service.evaluate(reading, risk, baseline);

      // Only one alert due to cooldown
      final hrAlerts = service.alerts.where((a) => a.type == AlertType.elevatedHr);
      expect(hrAlerts.length, 1);
    });

    test('acknowledge changes status', () {
      final reading = SensorReading(
        deviceId: 'TEST', timestamp: DateTime.now(),
        heartRate: 115, spo2: 98, bodyTemperature: 36.6,
        ambientTemperature: 28, humidity: 50,
        pm25: 18, pm10: 35, activityLevel: 0.25,
        fallDetected: false, battery: 90,
      );
      final risk = RiskAssessment(
        score: 40, level: RiskLevel.moderate,
        factors: [], pattern: '', recommendations: [],
        confidence: 0.7, timestamp: DateTime.now(),
      );
      const baseline = PersonalBaseline();

      service.evaluate(reading, risk, baseline);
      final alertId = service.alerts.first.id;
      service.acknowledge(alertId);

      expect(service.alerts.first.status, AlertStatus.acknowledged);
    });

    test('wearable command maps to correct level', () {
      final normalRisk = RiskAssessment(
        score: 20, level: RiskLevel.low,
        factors: [], pattern: '', recommendations: [],
        confidence: 0.7, timestamp: DateTime.now(),
      );
      final normalReading = SensorReading(
        deviceId: 'TEST', timestamp: DateTime.now(),
        heartRate: 72, spo2: 98, bodyTemperature: 36.6,
        ambientTemperature: 28, humidity: 50,
        pm25: 18, pm10: 35, activityLevel: 0.25,
        fallDetected: false, battery: 90,
      );

      expect(service.getWearableCommand(normalRisk, normalReading), WearableCommand.normal);

      final criticalRisk = RiskAssessment(
        score: 85, level: RiskLevel.critical,
        factors: [], pattern: '', recommendations: [],
        confidence: 0.7, timestamp: DateTime.now(),
      );
      expect(service.getWearableCommand(criticalRisk, normalReading), WearableCommand.critical);

      final fallReading = normalReading.copyWith(fallDetected: true);
      expect(service.getWearableCommand(normalRisk, fallReading), WearableCommand.fallAlert);
    });
  });
}
