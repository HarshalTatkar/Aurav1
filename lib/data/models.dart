import 'package:flutter/material.dart';
import '../core/constants.dart';

// ─── Sensor Reading ──────────────────────────────────────────────────────────
class SensorReading {
  final String deviceId;
  final DateTime timestamp;
  final double heartRate;
  final double spo2;
  final double bodyTemperature;
  final double ambientTemperature;
  final double humidity;
  final double pm25;
  final double pm10;
  final double activityLevel; // 0.0 - 1.0
  final bool fallDetected;
  final int battery;

  const SensorReading({
    required this.deviceId,
    required this.timestamp,
    required this.heartRate,
    required this.spo2,
    required this.bodyTemperature,
    required this.ambientTemperature,
    required this.humidity,
    required this.pm25,
    required this.pm10,
    required this.activityLevel,
    required this.fallDetected,
    required this.battery,
  });

  factory SensorReading.empty() => SensorReading(
        deviceId: '',
        timestamp: DateTime.now(),
        heartRate: 0,
        spo2: 0,
        bodyTemperature: 0,
        ambientTemperature: 0,
        humidity: 0,
        pm25: 0,
        pm10: 0,
        activityLevel: 0,
        fallDetected: false,
        battery: 0,
      );

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'timestamp': timestamp.toIso8601String(),
        'heartRate': heartRate,
        'spo2': spo2,
        'bodyTemperature': bodyTemperature,
        'ambientTemperature': ambientTemperature,
        'humidity': humidity,
        'pm25': pm25,
        'pm10': pm10,
        'activityLevel': activityLevel,
        'fallDetected': fallDetected,
        'battery': battery,
      };

  factory SensorReading.fromJson(Map<String, dynamic> json) => SensorReading(
        deviceId: json['deviceId'] ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        heartRate: (json['heartRate'] ?? 0).toDouble(),
        spo2: (json['spo2'] ?? 0).toDouble(),
        bodyTemperature: (json['bodyTemperature'] ?? 0).toDouble(),
        ambientTemperature: (json['ambientTemperature'] ?? 0).toDouble(),
        humidity: (json['humidity'] ?? 0).toDouble(),
        pm25: (json['pm25'] ?? 0).toDouble(),
        pm10: (json['pm10'] ?? 0).toDouble(),
        activityLevel: (json['activityLevel'] ?? 0).toDouble(),
        fallDetected: json['fallDetected'] ?? false,
        battery: json['battery'] ?? 0,
      );

  SensorReading copyWith({
    String? deviceId,
    DateTime? timestamp,
    double? heartRate,
    double? spo2,
    double? bodyTemperature,
    double? ambientTemperature,
    double? humidity,
    double? pm25,
    double? pm10,
    double? activityLevel,
    bool? fallDetected,
    int? battery,
  }) =>
      SensorReading(
        deviceId: deviceId ?? this.deviceId,
        timestamp: timestamp ?? this.timestamp,
        heartRate: heartRate ?? this.heartRate,
        spo2: spo2 ?? this.spo2,
        bodyTemperature: bodyTemperature ?? this.bodyTemperature,
        ambientTemperature: ambientTemperature ?? this.ambientTemperature,
        humidity: humidity ?? this.humidity,
        pm25: pm25 ?? this.pm25,
        pm10: pm10 ?? this.pm10,
        activityLevel: activityLevel ?? this.activityLevel,
        fallDetected: fallDetected ?? this.fallDetected,
        battery: battery ?? this.battery,
      );
}

// ─── Personal Baseline ───────────────────────────────────────────────────────
class PersonalBaseline {
  final double hrLow;
  final double hrHigh;
  final double hrAvg;
  final double spo2Low;
  final double spo2Avg;
  final double bodyTempLow;
  final double bodyTempHigh;
  final double bodyTempAvg;
  final double avgActivity;
  final DateTime? calibratedAt;
  final int readingsCount;

  const PersonalBaseline({
    this.hrLow = 62,
    this.hrHigh = 82,
    this.hrAvg = 72,
    this.spo2Low = 96,
    this.spo2Avg = 98,
    this.bodyTempLow = 36.2,
    this.bodyTempHigh = 36.9,
    this.bodyTempAvg = 36.6,
    this.avgActivity = 0.3,
    this.calibratedAt,
    this.readingsCount = 0,
  });

  bool get isCalibrated => readingsCount >= 30;

  Map<String, dynamic> toJson() => {
        'hrLow': hrLow,
        'hrHigh': hrHigh,
        'hrAvg': hrAvg,
        'spo2Low': spo2Low,
        'spo2Avg': spo2Avg,
        'bodyTempLow': bodyTempLow,
        'bodyTempHigh': bodyTempHigh,
        'bodyTempAvg': bodyTempAvg,
        'avgActivity': avgActivity,
        'calibratedAt': calibratedAt?.toIso8601String(),
        'readingsCount': readingsCount,
      };

  factory PersonalBaseline.fromJson(Map<String, dynamic> json) =>
      PersonalBaseline(
        hrLow: (json['hrLow'] ?? 62).toDouble(),
        hrHigh: (json['hrHigh'] ?? 82).toDouble(),
        hrAvg: (json['hrAvg'] ?? 72).toDouble(),
        spo2Low: (json['spo2Low'] ?? 96).toDouble(),
        spo2Avg: (json['spo2Avg'] ?? 98).toDouble(),
        bodyTempLow: (json['bodyTempLow'] ?? 36.2).toDouble(),
        bodyTempHigh: (json['bodyTempHigh'] ?? 36.9).toDouble(),
        bodyTempAvg: (json['bodyTempAvg'] ?? 36.6).toDouble(),
        avgActivity: (json['avgActivity'] ?? 0.3).toDouble(),
        calibratedAt: json['calibratedAt'] != null
            ? DateTime.tryParse(json['calibratedAt'])
            : null,
        readingsCount: json['readingsCount'] ?? 0,
      );
}

// ─── Contributing Factor ─────────────────────────────────────────────────────
class ContributingFactor {
  final String name;
  final String description;
  final double weight; // 0.0 - 1.0 contribution
  final double rawValue;
  final String unit;

  const ContributingFactor({
    required this.name,
    required this.description,
    required this.weight,
    required this.rawValue,
    this.unit = '',
  });
}

// ─── Risk Assessment ─────────────────────────────────────────────────────────
class RiskAssessment {
  final int score;
  final RiskLevel level;
  final List<ContributingFactor> factors;
  final String pattern;
  final List<String> recommendations;
  final double confidence;
  final DateTime timestamp;
  final String? disasterContext;

  const RiskAssessment({
    required this.score,
    required this.level,
    required this.factors,
    required this.pattern,
    required this.recommendations,
    required this.confidence,
    required this.timestamp,
    this.disasterContext,
  });

  factory RiskAssessment.initial() => RiskAssessment(
        score: 0,
        level: RiskLevel.low,
        factors: [],
        pattern: 'Waiting for sensor data...',
        recommendations: [],
        confidence: 0,
        timestamp: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        'level': level.code,
        'pattern': pattern,
        'recommendations': recommendations,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'factors': factors
            .map((f) => {
                  'name': f.name,
                  'description': f.description,
                  'weight': f.weight,
                  'rawValue': f.rawValue,
                  'unit': f.unit,
                })
            .toList(),
      };
}

// ─── Alert ───────────────────────────────────────────────────────────────────
class HealthAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final DateTime timestamp;
  final String reason;
  final String recommendation;
  final Map<String, double> sensorValues;
  final AlertStatus status;
  final bool wearableNotified;
  final bool wearableAcknowledged;

  const HealthAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.reason,
    required this.recommendation,
    required this.sensorValues,
    this.status = AlertStatus.active,
    this.wearableNotified = false,
    this.wearableAcknowledged = false,
  });

  HealthAlert copyWith({
    AlertStatus? status,
    bool? wearableNotified,
    bool? wearableAcknowledged,
  }) =>
      HealthAlert(
        id: id,
        type: type,
        severity: severity,
        timestamp: timestamp,
        reason: reason,
        recommendation: recommendation,
        sensorValues: sensorValues,
        status: status ?? this.status,
        wearableNotified: wearableNotified ?? this.wearableNotified,
        wearableAcknowledged: wearableAcknowledged ?? this.wearableAcknowledged,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.code,
        'severity': severity.name,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
        'recommendation': recommendation,
        'sensorValues': sensorValues,
        'status': status.name,
        'wearableNotified': wearableNotified,
        'wearableAcknowledged': wearableAcknowledged,
      };
}

// ─── Device Info ─────────────────────────────────────────────────────────────
class DeviceInfo {
  final String id;
  final String name;
  final AuraDeviceType type;
  final DeviceConnectionState connectionState;
  final int battery;
  final DateTime? lastSeen;
  final int signalStrength; // RSSI
  final String? firmwareVersion;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.type,
    this.connectionState = DeviceConnectionState.disconnected,
    this.battery = 0,
    this.lastSeen,
    this.signalStrength = 0,
    this.firmwareVersion,
  });

  DeviceInfo copyWith({
    DeviceConnectionState? connectionState,
    int? battery,
    DateTime? lastSeen,
    int? signalStrength,
  }) =>
      DeviceInfo(
        id: id,
        name: name,
        type: type,
        connectionState: connectionState ?? this.connectionState,
        battery: battery ?? this.battery,
        lastSeen: lastSeen ?? this.lastSeen,
        signalStrength: signalStrength ?? this.signalStrength,
        firmwareVersion: firmwareVersion,
      );

  bool get isConnected => connectionState == DeviceConnectionState.connected;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'connectionState': connectionState.name,
        'battery': battery,
        'lastSeen': lastSeen?.toIso8601String(),
        'signalStrength': signalStrength,
        'firmwareVersion': firmwareVersion,
      };
}

// ─── User Profile ────────────────────────────────────────────────────────────
class UserProfile {
  final String id;
  final String name;
  final String email;
  final int? age;
  final double? weight;
  final double? height;
  final List<String> emergencyContacts;
  final PersonalBaseline baseline;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.weight,
    this.height,
    this.emergencyContacts = const [],
    this.baseline = const PersonalBaseline(),
  });

  UserProfile copyWith({
    String? name,
    String? email,
    int? age,
    double? weight,
    double? height,
    List<String>? emergencyContacts,
    PersonalBaseline? baseline,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        age: age ?? this.age,
        weight: weight ?? this.weight,
        height: height ?? this.height,
        emergencyContacts: emergencyContacts ?? this.emergencyContacts,
        baseline: baseline ?? this.baseline,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'age': age,
        'weight': weight,
        'height': height,
        'emergencyContacts': emergencyContacts,
        'baseline': baseline.toJson(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        age: json['age'],
        weight: json['weight']?.toDouble(),
        height: json['height']?.toDouble(),
        emergencyContacts:
            List<String>.from(json['emergencyContacts'] ?? []),
        baseline: json['baseline'] != null
            ? PersonalBaseline.fromJson(json['baseline'])
            : const PersonalBaseline(),
      );

  factory UserProfile.demo() => const UserProfile(
        id: 'demo_user',
        name: 'Naise',
        email: 'naise@aura.health',
        age: 22,
        weight: 65,
        height: 170,
        emergencyContacts: ['+91 98765 43210', '+91 91234 56789'],
      );
}

// ─── Emergency Event ─────────────────────────────────────────────────────────
class EmergencyEvent {
  final String id;
  final DateTime timestamp;
  final String type; // SOS, FALL, CRITICAL
  final double? latitude;
  final double? longitude;
  final SensorReading? healthSnapshot;
  final String status; // ACTIVE, RESOLVED, CANCELLED
  final String? resolvedAt;

  const EmergencyEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    this.latitude,
    this.longitude,
    this.healthSnapshot,
    this.status = 'ACTIVE',
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        'healthSnapshot': healthSnapshot?.toJson(),
        'status': status,
        'resolvedAt': resolvedAt,
      };
}

// ─── App Settings ────────────────────────────────────────────────────────────
class AppSettings {
  final bool continuousMonitoring;
  final bool backgroundMonitoring;
  final int sensorRefreshMs;
  final bool healthAlerts;
  final bool heatAlerts;
  final bool airQualityAlerts;
  final bool wearableAlerts;
  final bool dataSharing;
  final bool locationEnabled;
  final ThemeMode themeMode;
  final bool demoMode;
  final DemoScenario demoScenario;
  final DisasterMode disasterMode;

  const AppSettings({
    this.continuousMonitoring = true,
    this.backgroundMonitoring = false,
    this.sensorRefreshMs = 2000,
    this.healthAlerts = true,
    this.heatAlerts = true,
    this.airQualityAlerts = true,
    this.wearableAlerts = true,
    this.dataSharing = false,
    this.locationEnabled = false,
    this.themeMode = ThemeMode.light,
    this.demoMode = true,
    this.demoScenario = DemoScenario.normal,
    this.disasterMode = DisasterMode.none,
  });

  AppSettings copyWith({
    bool? continuousMonitoring,
    bool? backgroundMonitoring,
    int? sensorRefreshMs,
    bool? healthAlerts,
    bool? heatAlerts,
    bool? airQualityAlerts,
    bool? wearableAlerts,
    bool? dataSharing,
    bool? locationEnabled,
    ThemeMode? themeMode,
    bool? demoMode,
    DemoScenario? demoScenario,
    DisasterMode? disasterMode,
  }) =>
      AppSettings(
        continuousMonitoring:
            continuousMonitoring ?? this.continuousMonitoring,
        backgroundMonitoring:
            backgroundMonitoring ?? this.backgroundMonitoring,
        sensorRefreshMs: sensorRefreshMs ?? this.sensorRefreshMs,
        healthAlerts: healthAlerts ?? this.healthAlerts,
        heatAlerts: heatAlerts ?? this.heatAlerts,
        airQualityAlerts: airQualityAlerts ?? this.airQualityAlerts,
        wearableAlerts: wearableAlerts ?? this.wearableAlerts,
        dataSharing: dataSharing ?? this.dataSharing,
        locationEnabled: locationEnabled ?? this.locationEnabled,
        themeMode: themeMode ?? this.themeMode,
        demoMode: demoMode ?? this.demoMode,
        demoScenario: demoScenario ?? this.demoScenario,
        disasterMode: disasterMode ?? this.disasterMode,
      );
}

// ─── Sensor History Point (for charts) ───────────────────────────────────────
class SensorHistoryPoint {
  final DateTime timestamp;
  final double value;

  const SensorHistoryPoint(this.timestamp, this.value);
}

// ─── Environment Data ─────────────────────────────────────────────────────────
class EnvironmentData {
  final double temperature;
  final double humidity;
  final double pm25;
  final double pm10;
  final bool isReal;
  final String? locationName;
  final DateTime? fetchedAt; // ✅ ADD THIS FIELD

  EnvironmentData({
    this.temperature = 0,
    this.humidity = 0,
    this.pm25 = 0,
    this.pm10 = 0,
    this.isReal = false,
    this.locationName,
    this.fetchedAt, // ✅ ADD THIS
  });

  EnvironmentData copyWith({
    double? temperature,
    double? humidity,
    double? pm25,
    double? pm10,
    bool? isReal,
    String? locationName,
    DateTime? fetchedAt, // ✅ ADD THIS
  }) {
    return EnvironmentData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      isReal: isReal ?? this.isReal,
      locationName: locationName ?? this.locationName,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

}
