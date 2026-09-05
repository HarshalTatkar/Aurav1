import 'dart:async';
import '../core/constants.dart';
import '../core/utils.dart';
import '../data/models.dart';

/// Centralized alert management system.
/// Creates, deduplicates, and manages health alerts based on risk assessments and sensor data.
class AlertService {
  final List<HealthAlert> _alerts = [];
  final StreamController<HealthAlert> _alertStream =
      StreamController<HealthAlert>.broadcast();
  final Map<String, DateTime> _cooldowns = {};

  static const Duration _cooldownDuration = Duration(minutes: 2);

  List<HealthAlert> get alerts => List.unmodifiable(_alerts);
  List<HealthAlert> get activeAlerts =>
      _alerts.where((a) => a.status == AlertStatus.active).toList();
  Stream<HealthAlert> get onAlert => _alertStream.stream;

  /// Evaluate sensor reading and risk assessment, creating alerts if needed
  void evaluate(SensorReading reading, RiskAssessment risk, PersonalBaseline baseline) {
    // Heart Rate
    if (reading.heartRate > baseline.hrHigh + 20) {
      _createAlert(
        type: AlertType.elevatedHr,
        severity: reading.heartRate > baseline.hrHigh + 35
            ? AlertSeverity.critical
            : AlertSeverity.warning,
        reason: 'Heart rate at ${reading.heartRate.round()} BPM is above your usual range (${baseline.hrLow.round()}-${baseline.hrHigh.round()}).',
        recommendation: 'Take a rest and monitor your heart rate.',
        values: {'heartRate': reading.heartRate},
      );
    }

    // SpO2
    if (reading.spo2 > 0 && reading.spo2 < 92) {
      _createAlert(
        type: AlertType.lowSpo2,
        severity: reading.spo2 < 88 ? AlertSeverity.critical : AlertSeverity.high,
        reason: 'Blood oxygen at ${reading.spo2.round()}% is below safe levels.',
        recommendation: 'Sit upright and take slow, deep breaths.',
        values: {'spo2': reading.spo2},
      );
    }

    // Body Temperature
    if (reading.bodyTemperature > baseline.bodyTempHigh + 1.5) {
      _createAlert(
        type: AlertType.highBodyTemp,
        severity: reading.bodyTemperature > 39
            ? AlertSeverity.critical
            : AlertSeverity.warning,
        reason:
            'Body temperature at ${reading.bodyTemperature.toStringAsFixed(1)}°C is elevated.',
        recommendation: 'Apply cooling measures and rest.',
        values: {'bodyTemperature': reading.bodyTemperature},
      );
    }

    // Heat Stress (combined)
    if (reading.ambientTemperature > 35 &&
        reading.humidity > 65 &&
        reading.bodyTemperature > baseline.bodyTempHigh) {
      _createAlert(
        type: AlertType.heatStress,
        severity: reading.ambientTemperature > 40
            ? AlertSeverity.critical
            : AlertSeverity.high,
        reason:
            'High heat (${reading.ambientTemperature.round()}°C) and humidity (${reading.humidity.round()}%) combined with elevated body temperature.',
        recommendation: 'Move to a cooler environment and hydrate immediately.',
        values: {
          'ambientTemperature': reading.ambientTemperature,
          'humidity': reading.humidity,
          'bodyTemperature': reading.bodyTemperature,
        },
      );
    }

    // Air Quality
    if (reading.pm25 > SensorRanges.pm25Unhealthy) {
      _createAlert(
        type: AlertType.poorAirQuality,
        severity: reading.pm25 > 250 ? AlertSeverity.critical : AlertSeverity.warning,
        reason: 'PM2.5 at ${reading.pm25.round()} µg/m³ is at unhealthy levels.',
        recommendation: 'Reduce outdoor exposure and use a mask if available.',
        values: {'pm25': reading.pm25, 'pm10': reading.pm10},
      );
    }

    // Fall
    if (reading.fallDetected) {
      _createAlert(
        type: AlertType.fallDetected,
        severity: AlertSeverity.critical,
        reason: 'A potential fall has been detected.',
        recommendation: 'Please confirm you are okay. If injured, activate SOS.',
        values: {'fallDetected': 1},
      );
    }

    // Critical risk score
    if (risk.score >= 80) {
      _createAlert(
        type: AlertType.criticalRisk,
        severity: AlertSeverity.critical,
        reason: 'Overall health risk score has reached ${risk.score}/100.',
        recommendation: risk.recommendations.isNotEmpty
            ? risk.recommendations.first
            : 'Take immediate precautionary measures.',
        values: {'riskScore': risk.score.toDouble()},
      );
    }
  }

  void _createAlert({
    required AlertType type,
    required AlertSeverity severity,
    required String reason,
    required String recommendation,
    required Map<String, double> values,
  }) {
    // Cooldown check — don't spam same alert type
    final key = type.code;
    final lastTime = _cooldowns[key];
    if (lastTime != null &&
        DateTime.now().difference(lastTime) < _cooldownDuration) {
      return;
    }

    final alert = HealthAlert(
      id: generateId(),
      type: type,
      severity: severity,
      timestamp: DateTime.now(),
      reason: reason,
      recommendation: recommendation,
      sensorValues: values,
    );

    _alerts.insert(0, alert);
    _cooldowns[key] = DateTime.now();
    _alertStream.add(alert);

    // Keep history manageable
    if (_alerts.length > 100) {
      _alerts.removeRange(100, _alerts.length);
    }
  }

  /// Acknowledge an alert
  void acknowledge(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      _alerts[idx] = _alerts[idx].copyWith(status: AlertStatus.acknowledged);
    }
  }

  /// Resolve an alert
  void resolve(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      _alerts[idx] = _alerts[idx].copyWith(status: AlertStatus.resolved);
    }
  }

  /// Mark alert as sent to wearable
  void markWearableNotified(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      _alerts[idx] = _alerts[idx].copyWith(wearableNotified: true);
    }
  }

  /// Get the appropriate wearable command for the latest risk level
  WearableCommand? getWearableCommand(RiskAssessment risk, SensorReading reading) {
    if (reading.fallDetected) return WearableCommand.fallAlert;
    if (risk.score >= 81) return WearableCommand.critical;

    // Heat-specific alert
    if (risk.factors.any((f) => f.name == 'Ambient Temperature' && f.weight > 0.1) &&
        risk.score >= 61) {
      return WearableCommand.heatAlert;
    }

    // SpO2-specific
    if (reading.spo2 > 0 && reading.spo2 < 92) return WearableCommand.lowSpo2Alert;

    if (risk.score >= 61) return WearableCommand.highRisk;
    if (risk.score >= 31) return WearableCommand.warning;
    return WearableCommand.normal;
  }

  void dispose() {
    _alertStream.close();
  }
}
