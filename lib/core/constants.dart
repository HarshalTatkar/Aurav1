// ─── BLE Constants ───────────────────────────────────────────────────────────
class BleUuids {
  BleUuids._();
  static const String sensorServiceUuid = '12345678-1234-5678-1234-56789abcdef0';
  static const String sensorDataCharUuid = '12345678-1234-5678-1234-56789abcdef1';
  static const String sensorBatteryCharUuid = '12345678-1234-5678-1234-56789abcdef2';

  static const String wearableServiceUuid = 'abcdef01-1234-5678-1234-56789abcdef0';
  static const String wearableCommandCharUuid = 'abcdef01-1234-5678-1234-56789abcdef1';
  static const String wearableAckCharUuid = 'abcdef01-1234-5678-1234-56789abcdef2';

  static const String sensorDeviceName = 'AURA-SENSOR';
  static const String wearableDeviceName = 'AURA-WEARABLE';
}

// ─── API Constants ───────────────────────────────────────────────────────────
class ApiConstants {
  ApiConstants._();
  static const String baseUrl = 'http://localhost:8000';
  static const String wsUrl = 'ws://localhost:8000/ws';

  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String usersMe = '/users/me';
  static const String devices = '/devices';
  static const String sensorReadings = '/sensor/readings';
  static const String healthCurrent = '/health/current';
  static const String healthHistory = '/health/history';
  static const String environmentCurrent = '/environment/current';
  static const String riskCurrent = '/risk/current';
  static const String riskHistory = '/risk/history';
  static const String alerts = '/alerts';
  static const String emergencySos = '/emergency/sos';
  static const String emergencyHistory = '/emergency/history';
}

// ─── Risk Thresholds ─────────────────────────────────────────────────────────
class RiskThresholds {
  RiskThresholds._();
  static const int low = 30;
  static const int moderate = 60;
  static const int high = 80;
  static const int critical = 100;
}

// ─── Risk Level ──────────────────────────────────────────────────────────────
enum RiskLevel {
  low('Low Risk', 'LOW'),
  moderate('Moderate Risk', 'MODERATE'),
  high('High Risk', 'HIGH'),
  critical('Critical', 'CRITICAL');

  final String label;
  final String code;
  const RiskLevel(this.label, this.code);

  static RiskLevel fromScore(int score) {
    if (score <= RiskThresholds.low) return RiskLevel.low;
    if (score <= RiskThresholds.moderate) return RiskLevel.moderate;
    if (score <= RiskThresholds.high) return RiskLevel.high;
    return RiskLevel.critical;
  }
}

// ─── Sensor Ranges (normal adult at rest) ────────────────────────────────────
class SensorRanges {
  SensorRanges._();
  static const double hrMin = 40;
  static const double hrMax = 200;
  static const double hrNormalLow = 60;
  static const double hrNormalHigh = 100;

  static const double spo2Min = 70;
  static const double spo2Max = 100;
  static const double spo2NormalLow = 95;

  static const double bodyTempMin = 34;
  static const double bodyTempMax = 42;
  static const double bodyTempNormalLow = 36.1;
  static const double bodyTempNormalHigh = 37.2;

  static const double ambientTempMin = -20;
  static const double ambientTempMax = 55;
  static const double ambientTempSafe = 35;

  static const double humidityMin = 0;
  static const double humidityMax = 100;
  static const double humiditySafe = 60;

  static const double pm25Safe = 35;
  static const double pm25Moderate = 75;
  static const double pm25Unhealthy = 150;

  static const double pm10Safe = 50;
  static const double pm10Moderate = 100;
  static const double pm10Unhealthy = 250;
}

// ─── Alert Types ─────────────────────────────────────────────────────────────
enum AlertType {
  elevatedHr('Elevated Heart Rate', 'HR'),
  lowSpo2('Low SpO2', 'SPO2'),
  highBodyTemp('High Body Temperature', 'TEMP'),
  heatStress('Heat Stress Risk', 'HEAT'),
  poorAirQuality('Poor Air Quality', 'AIR'),
  fallDetected('Fall Detected', 'FALL'),
  prolongedInactivity('Prolonged Inactivity', 'INACTIVE'),
  deviceDisconnected('Device Disconnected', 'DEVICE'),
  criticalRisk('Critical Risk Level', 'CRITICAL'),
  sos('Emergency SOS', 'SOS');

  final String label;
  final String code;
  const AlertType(this.label, this.code);
}

// ─── Alert Severity ──────────────────────────────────────────────────────────
enum AlertSeverity { info, warning, high, critical }

// ─── Alert Status ────────────────────────────────────────────────────────────
enum AlertStatus { active, acknowledged, resolved }

// ─── Device Connection State ─────────────────────────────────────────────────
enum DeviceConnectionState { disconnected, connecting, connected, disconnecting }

// ─── Device Type ─────────────────────────────────────────────────────────────
enum AuraDeviceType { sensor, wearable }

// ─── Wearable Commands ───────────────────────────────────────────────────────
enum WearableCommand {
  normal('NORMAL'),
  warning('WARNING'),
  highRisk('HIGH_RISK'),
  critical('CRITICAL'),
  fallAlert('FALL_ALERT'),
  heatAlert('HEAT_ALERT'),
  lowSpo2Alert('LOW_SPO2_ALERT'),
  highTempAlert('HIGH_TEMPERATURE_ALERT'),
  sos('SOS'),
  cancelAlert('CANCEL_ALERT');

  final String code;
  const WearableCommand(this.code);
}

// ─── Disaster Mode ───────────────────────────────────────────────────────────
enum DisasterMode {
  none('Normal', 'No active disaster mode'),
  heatwave('Heatwave', 'Extreme heat conditions detected'),
  flood('Flood', 'Flood warning active'),
  airPollution('Severe Air Pollution', 'Air quality is hazardous'),
  extremeWeather('Extreme Weather', 'Severe weather conditions'),
  emergency('Emergency', 'General emergency mode');

  final String label;
  final String description;
  const DisasterMode(this.label, this.description);
}

// ─── Demo Scenarios ──────────────────────────────────────────────────────────
enum DemoScenario {
  normal('Normal', 'All readings within healthy range'),
  heatwave('Heatwave', 'Simulates high heat + humidity exposure'),
  critical('Critical', 'Simulates critical health emergency'),
  fall('Fall Detection', 'Simulates a fall event'),
  airPollution('Air Pollution', 'Simulates poor air quality');

  final String label;
  final String description;
  const DemoScenario(this.label, this.description);
}

// ─── Time Ranges for Charts ──────────────────────────────────────────────────
enum TimeRange {
  oneHour('1h', Duration(hours: 1)),
  sixHours('6h', Duration(hours: 6)),
  twentyFourHours('24h', Duration(hours: 24)),
  sevenDays('7d', Duration(days: 7));

  final String label;
  final Duration duration;
  const TimeRange(this.label, this.duration);
}
