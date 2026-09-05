import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'theme.dart';

// ─── Greeting Helper ─────────────────────────────────────────────────────────
String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

// ─── Number Formatting ───────────────────────────────────────────────────────
String formatBpm(double value) => '${value.round()}';
String formatSpo2(double value) => '${value.round()}%';
String formatTemp(double value) => '${value.toStringAsFixed(1)}°C';
String formatHumidity(double value) => '${value.round()}%';
String formatPm(double value) => '${value.round()} µg/m³';
String formatActivity(double value) => '${(value * 100).round()}%';
String formatBattery(int value) => '$value%';
String formatRiskScore(int score) => '$score / 100';

// ─── Date Formatting ─────────────────────────────────────────────────────────
String formatTimestamp(DateTime dt) => DateFormat('HH:mm:ss').format(dt);
String formatDate(DateTime dt) => DateFormat('MMM d, yyyy').format(dt);
String formatDateTime(DateTime dt) => DateFormat('MMM d, HH:mm').format(dt);

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 5) return 'Just now';
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

// ─── Risk Helpers ────────────────────────────────────────────────────────────
String riskLabel(int score) => RiskLevel.fromScore(score).label;

Color riskColor(int score) => AuraColors.riskColor(score);

IconData riskIcon(int score) {
  if (score <= 30) return Icons.check_circle_rounded;
  if (score <= 60) return Icons.info_rounded;
  if (score <= 80) return Icons.warning_rounded;
  return Icons.error_rounded;
}

// ─── Air Quality Index ───────────────────────────────────────────────────────
String aqiLabel(double pm25) {
  if (pm25 <= 12) return 'Good';
  if (pm25 <= 35) return 'Moderate';
  if (pm25 <= 55) return 'Unhealthy for Sensitive';
  if (pm25 <= 150) return 'Unhealthy';
  if (pm25 <= 250) return 'Very Unhealthy';
  return 'Hazardous';
}

Color aqiColor(double pm25) {
  if (pm25 <= 12) return AuraColors.healthy;
  if (pm25 <= 35) return const Color(0xFF84CC16);
  if (pm25 <= 55) return AuraColors.warning;
  if (pm25 <= 150) return AuraColors.moderate;
  if (pm25 <= 250) return AuraColors.critical;
  return const Color(0xFF7F1D1D);
}

// ─── Heat Index Calculator ───────────────────────────────────────────────────
/// Simplified heat index (Steadman's formula variant)
double calculateHeatIndex(double tempC, double humidity) {
  final t = tempC * 9 / 5 + 32; // Convert to F
  final rh = humidity;

  if (t < 80) return tempC;

  double hi = -42.379 +
      2.04901523 * t +
      10.14333127 * rh -
      0.22475541 * t * rh -
      6.83783e-3 * t * t -
      5.481717e-2 * rh * rh +
      1.22874e-3 * t * t * rh +
      8.5282e-4 * t * rh * rh -
      1.99e-6 * t * t * rh * rh;

  return (hi - 32) * 5 / 9; // Convert back to C
}

String heatIndexLabel(double heatIndexC) {
  if (heatIndexC < 27) return 'Comfortable';
  if (heatIndexC < 32) return 'Caution';
  if (heatIndexC < 40) return 'Extreme Caution';
  if (heatIndexC < 54) return 'Danger';
  return 'Extreme Danger';
}

Color heatIndexColor(double heatIndexC) {
  if (heatIndexC < 27) return AuraColors.healthy;
  if (heatIndexC < 32) return AuraColors.warning;
  if (heatIndexC < 40) return AuraColors.moderate;
  return AuraColors.critical;
}

// ─── Sensor Validation ───────────────────────────────────────────────────────
bool isValidHr(double hr) => hr >= SensorRanges.hrMin && hr <= SensorRanges.hrMax;
bool isValidSpo2(double spo2) => spo2 >= SensorRanges.spo2Min && spo2 <= SensorRanges.spo2Max;
bool isValidBodyTemp(double temp) =>
    temp >= SensorRanges.bodyTempMin && temp <= SensorRanges.bodyTempMax;

// ─── Clamp Utility ───────────────────────────────────────────────────────────
double clampValue(double value, double minVal, double maxVal) =>
    max(minVal, min(maxVal, value));

// ─── UUID Generator (simple) ─────────────────────────────────────────────────
String generateId() {
  final r = Random();
  return List.generate(20, (_) => r.nextInt(36).toRadixString(36)).join();
}
