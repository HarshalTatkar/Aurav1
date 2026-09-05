import 'dart:math';
import '../core/constants.dart';
import '../data/models.dart';

/// The core AI Risk Engine that performs multi-sensor analysis
/// to compute personalized health risk scores.
///
/// This is NOT a clinical diagnostic system. All scores are
/// prototype-level indicators for demonstration purposes.
class RiskEngine {
  final PersonalBaseline baseline;

  RiskEngine(this.baseline);

  /// Compute a comprehensive risk assessment from sensor data
  RiskAssessment assess(SensorReading reading, {DisasterMode disaster = DisasterMode.none}) {
    final factors = <ContributingFactor>[];
    double totalScore = 0;

    // ── 1. Heart Rate Deviation ──────────────────────────────────────────
    final hrDeviation = _hrScore(reading.heartRate);
    if (hrDeviation > 0) {
      factors.add(ContributingFactor(
        name: 'Heart Rate',
        description: _hrDescription(reading.heartRate),
        weight: hrDeviation / 100,
        rawValue: reading.heartRate,
        unit: 'BPM',
      ));
      totalScore += hrDeviation;
    }

    // ── 2. SpO2 Deviation ────────────────────────────────────────────────
    final spo2Score = _spo2Score(reading.spo2);
    if (spo2Score > 0) {
      factors.add(ContributingFactor(
        name: 'Blood Oxygen',
        description: _spo2Description(reading.spo2),
        weight: spo2Score / 100,
        rawValue: reading.spo2,
        unit: '%',
      ));
      totalScore += spo2Score;
    }

    // ── 3. Body Temperature ──────────────────────────────────────────────
    final bodyTempScore = _bodyTempScore(reading.bodyTemperature);
    if (bodyTempScore > 0) {
      factors.add(ContributingFactor(
        name: 'Body Temperature',
        description: _bodyTempDescription(reading.bodyTemperature),
        weight: bodyTempScore / 100,
        rawValue: reading.bodyTemperature,
        unit: '°C',
      ));
      totalScore += bodyTempScore;
    }

    // ── 4. Ambient Temperature ───────────────────────────────────────────
    final ambientScore = _ambientTempScore(reading.ambientTemperature);
    if (ambientScore > 0) {
      factors.add(ContributingFactor(
        name: 'Ambient Temperature',
        description: _ambientTempDescription(reading.ambientTemperature),
        weight: ambientScore / 100,
        rawValue: reading.ambientTemperature,
        unit: '°C',
      ));
      totalScore += ambientScore;
    }

    // ── 5. Humidity ──────────────────────────────────────────────────────
    final humidityScore = _humidityScore(reading.humidity);
    if (humidityScore > 0) {
      factors.add(ContributingFactor(
        name: 'Humidity',
        description: 'Humidity at ${reading.humidity.round()}% increases heat stress risk.',
        weight: humidityScore / 100,
        rawValue: reading.humidity,
        unit: '%',
      ));
      totalScore += humidityScore;
    }

    // ── 6. Air Quality (PM2.5) ───────────────────────────────────────────
    final pm25Score = _pm25Score(reading.pm25);
    if (pm25Score > 0) {
      factors.add(ContributingFactor(
        name: 'Air Quality (PM2.5)',
        description: 'PM2.5 at ${reading.pm25.round()} µg/m³ may affect respiratory health.',
        weight: pm25Score / 100,
        rawValue: reading.pm25,
        unit: 'µg/m³',
      ));
      totalScore += pm25Score;
    }

    // ── 7. Activity Level ────────────────────────────────────────────────
    final activityScore = _activityScore(
      reading.activityLevel,
      reading.ambientTemperature,
      reading.humidity,
    );
    if (activityScore > 0) {
      factors.add(ContributingFactor(
        name: 'Physical Activity',
        description: _activityDescription(reading.activityLevel),
        weight: activityScore / 100,
        rawValue: reading.activityLevel,
        unit: '',
      ));
      totalScore += activityScore;
    }

    // ── 8. Fall Detection ────────────────────────────────────────────────
    if (reading.fallDetected) {
      factors.add(const ContributingFactor(
        name: 'Fall Detected',
        description: 'A potential fall has been detected. Please confirm you are safe.',
        weight: 1.0,
        rawValue: 1,
      ));
      totalScore += 30; // Significant bump
    }

    // ── Disaster multiplier ──────────────────────────────────────────────
    if (disaster == DisasterMode.heatwave) {
      totalScore *= 1.2;
    } else if (disaster == DisasterMode.airPollution) {
      totalScore *= 1.15;
    }

    // Clamp to 0-100
    final finalScore = min(100, max(0, totalScore.round()));
    final level = RiskLevel.fromScore(finalScore);

    // Sort factors by weight descending
    factors.sort((a, b) => b.weight.compareTo(a.weight));

    return RiskAssessment(
      score: finalScore,
      level: level,
      factors: factors,
      pattern: _generatePattern(factors, level, disaster),
      recommendations: _generateRecommendations(factors, level, reading, disaster),
      confidence: _calculateConfidence(reading, factors),
      timestamp: DateTime.now(),
      disasterContext: disaster != DisasterMode.none ? disaster.label : null,
    );
  }

  // ─── Scoring Functions ─────────────────────────────────────────────────

  double _hrScore(double hr) {
    if (hr <= 0) return 0;
    final upperDev = hr - baseline.hrHigh;
    final lowerDev = baseline.hrLow - hr;

    if (upperDev > 40) return 25; // Very high
    if (upperDev > 25) return 20;
    if (upperDev > 15) return 15;
    if (upperDev > 5) return 8;
    if (lowerDev > 20) return 12; // Bradycardia concern
    if (lowerDev > 10) return 6;
    return 0;
  }

  double _spo2Score(double spo2) {
    if (spo2 <= 0) return 0;
    if (spo2 < 88) return 30; // Severely low
    if (spo2 < 92) return 22;
    if (spo2 < 94) return 15;
    if (spo2 < baseline.spo2Low) return 8;
    return 0;
  }

  double _bodyTempScore(double temp) {
    if (temp <= 0) return 0;
    final deviation = temp - baseline.bodyTempHigh;
    if (deviation > 2.5) return 25; // High fever
    if (deviation > 1.5) return 20;
    if (deviation > 0.8) return 15;
    if (deviation > 0.3) return 8;
    if (temp < baseline.bodyTempLow - 1.0) return 10; // Hypothermia
    return 0;
  }

  double _ambientTempScore(double temp) {
    if (temp > 42) return 20;
    if (temp > 38) return 15;
    if (temp > 35) return 10;
    if (temp > 32) return 5;
    if (temp < -5) return 10; // Cold stress
    return 0;
  }

  double _humidityScore(double humidity) {
    if (humidity > 85) return 12;
    if (humidity > 75) return 8;
    if (humidity > 65) return 4;
    return 0;
  }

  double _pm25Score(double pm25) {
    if (pm25 > 250) return 20;
    if (pm25 > 150) return 15;
    if (pm25 > 75) return 10;
    if (pm25 > 35) return 5;
    return 0;
  }

  double _activityScore(double activity, double ambientTemp, double humidity) {
    // Activity is more risky in hot/humid conditions
    if (activity < 0.3) return 0;
    double base = activity > 0.8 ? 8 : activity > 0.5 ? 5 : 2;
    if (ambientTemp > 35 && activity > 0.5) base += 5;
    if (humidity > 70 && activity > 0.5) base += 3;
    return base;
  }

  // ─── Description Generators ────────────────────────────────────────────

  String _hrDescription(double hr) {
    if (hr > baseline.hrHigh + 25) {
      return 'Heart rate is significantly above your baseline (${baseline.hrLow.round()}-${baseline.hrHigh.round()} BPM).';
    }
    if (hr > baseline.hrHigh) {
      return 'Heart rate is above your usual range (${baseline.hrLow.round()}-${baseline.hrHigh.round()} BPM).';
    }
    if (hr < baseline.hrLow - 10) {
      return 'Heart rate is below your usual range.';
    }
    return 'Heart rate within expected range.';
  }

  String _spo2Description(double spo2) {
    if (spo2 < 90) return 'Blood oxygen is significantly below normal levels.';
    if (spo2 < 94) return 'Blood oxygen is below the expected range.';
    return 'Blood oxygen is slightly below your baseline.';
  }

  String _bodyTempDescription(double temp) {
    if (temp > baseline.bodyTempHigh + 2) return 'Body temperature is significantly elevated.';
    if (temp > baseline.bodyTempHigh + 0.5) return 'Body temperature is above your normal range.';
    if (temp < baseline.bodyTempLow - 1) return 'Body temperature is below your normal range.';
    return 'Body temperature is slightly elevated.';
  }

  String _ambientTempDescription(double temp) {
    if (temp > 40) return 'Extreme heat detected in your environment.';
    if (temp > 35) return 'High ambient temperature in your surroundings.';
    return 'Ambient temperature is moderately elevated.';
  }

  String _activityDescription(double activity) {
    if (activity > 0.8) return 'High physical activity detected.';
    if (activity > 0.5) return 'Moderate physical activity detected.';
    return 'Light activity detected.';
  }

  // ─── Pattern Generator ─────────────────────────────────────────────────

  String _generatePattern(
    List<ContributingFactor> factors,
    RiskLevel level,
    DisasterMode disaster,
  ) {
    if (factors.isEmpty) {
      return 'All your readings are within your normal range. No unusual patterns detected.';
    }

    final topFactors = factors.take(3).map((f) => f.name.toLowerCase()).toList();

    if (disaster == DisasterMode.heatwave) {
      return 'During current heatwave conditions, your readings show a combination of ${topFactors.join(", ")} concerns that may increase heat-related health risks.';
    }

    switch (level) {
      case RiskLevel.low:
        return 'Minor variations detected in ${topFactors.first}. Your overall health pattern remains stable.';
      case RiskLevel.moderate:
        return 'Your readings show elevated ${topFactors.join(" and ")}. Consider monitoring these trends.';
      case RiskLevel.high:
        return 'Your current readings show a combination of ${topFactors.join(", ")} that suggests increased health risk.';
      case RiskLevel.critical:
        return 'Multiple critical indicators detected: ${topFactors.join(", ")}. Immediate attention recommended.';
    }
  }

  // ─── Recommendation Generator ──────────────────────────────────────────

  List<String> _generateRecommendations(
    List<ContributingFactor> factors,
    RiskLevel level,
    SensorReading reading,
    DisasterMode disaster,
  ) {
    final recs = <String>[];
    final factorNames = factors.map((f) => f.name).toSet();

    // Heat-related
    if (factorNames.contains('Ambient Temperature') ||
        factorNames.contains('Humidity') ||
        disaster == DisasterMode.heatwave) {
      recs.add('Move to a cooler, shaded environment if possible.');
      recs.add('Hydrate — drink water at regular intervals.');
      if (reading.activityLevel > 0.5) {
        recs.add('Reduce physical exertion until conditions improve.');
      }
    }

    // HR elevated
    if (factorNames.contains('Heart Rate')) {
      recs.add('Take a rest and allow your heart rate to return to baseline.');
      if (reading.heartRate > baseline.hrHigh + 30) {
        recs.add('If you feel chest discomfort, seek medical attention.');
      }
    }

    // SpO2 low
    if (factorNames.contains('Blood Oxygen')) {
      recs.add('Sit upright and take slow, deep breaths.');
      if (reading.spo2 < 90) {
        recs.add('Consider seeking medical evaluation if this persists.');
      }
    }

    // Body temp
    if (factorNames.contains('Body Temperature')) {
      recs.add('Apply cooling measures — cool water, rest in shade.');
      if (reading.bodyTemperature > 39) {
        recs.add('Consider medical attention for persistent high body temperature.');
      }
    }

    // Air quality
    if (factorNames.contains('Air Quality (PM2.5)')) {
      recs.add('Reduce prolonged outdoor exposure in current air quality.');
      recs.add('Use a mask if available when outdoors.');
    }

    // Fall
    if (factorNames.contains('Fall Detected')) {
      recs.add('Please confirm that you are okay.');
      recs.add('If injured, activate the SOS feature for assistance.');
    }

    // Generic
    if (level == RiskLevel.critical && recs.isEmpty) {
      recs.add('Multiple health indicators are outside normal range.');
      recs.add('Consider contacting a healthcare provider.');
    }

    if (recs.isEmpty) {
      recs.add('Continue your current routine. Your readings look stable.');
    }

    return recs;
  }

  // ─── Confidence Calculation ────────────────────────────────────────────

  double _calculateConfidence(SensorReading reading, List<ContributingFactor> factors) {
    double conf = 0.5; // Base confidence
    if (baseline.isCalibrated) conf += 0.2;
    if (reading.heartRate > 0) conf += 0.05;
    if (reading.spo2 > 0) conf += 0.05;
    if (reading.bodyTemperature > 0) conf += 0.05;
    if (reading.ambientTemperature > 0) conf += 0.05;
    if (factors.length >= 2) conf += 0.05;
    if (factors.length >= 4) conf += 0.05;
    return min(0.95, conf);
  }
}
