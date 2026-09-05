import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  TimeRange _timeRange = TimeRange.oneHour;

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(sensorDataProvider);
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(sensorDataProvider.notifier);
    
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Health',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    LiveIndicator(lastUpdated: reading.timestamp),
                  ],
                ),
              ),
            ),

            // ── Time Range Selector ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: TimeRange.values.map((range) {
                    final selected = range == _timeRange;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(range.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _timeRange = range),
                        selectedColor: AuraColors.healthy.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: selected ? AuraColors.healthy : subtextColor,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AuraColors.healthy.withValues(alpha: 0.3)
                              : (AuraColors.glassBorder),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Heart Rate ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _HealthSection(
                  title: 'Heart Rate',
                  icon: Icons.favorite_rounded,
                  iconColor: AuraColors.critical,
                  currentValue: reading.heartRate > 0 ? '${reading.heartRate.round()}' : '--',
                  unit: 'BPM',
                  stats: [
                    _Stat('Baseline', '${profile.baseline.hrLow.round()}-${profile.baseline.hrHigh.round()}'),
                    _Stat('Average', '${profile.baseline.hrAvg.round()}'),
                  ],
                  statusText: reading.heartRate > profile.baseline.hrHigh
                      ? 'Above your baseline'
                      : reading.heartRate < profile.baseline.hrLow && reading.heartRate > 0
                          ? 'Below your baseline'
                          : 'Within normal range',
                  statusColor: reading.heartRate > profile.baseline.hrHigh
                      ? AuraColors.warning
                      : AuraColors.healthy,
                  chart: SensorChart(
                    data: notifier.getHistoryFor('hr', window: _timeRange.duration),
                    color: AuraColors.critical,
                    minY: 40,
                    maxY: 160,
                    unit: ' BPM',
                  ),
                ),
              ),
            ),

            // ── SpO2 ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _HealthSection(
                  title: 'Blood Oxygen (SpO2)',
                  icon: Icons.air_rounded,
                  iconColor: AuraColors.healthy,
                  currentValue: reading.spo2 > 0 ? '${reading.spo2.round()}' : '--',
                  unit: '%',
                  stats: [
                    _Stat('Normal', '≥ ${profile.baseline.spo2Low.round()}%'),
                  ],
                  statusText: reading.spo2 > 0 && reading.spo2 < 94
                      ? 'Below normal range'
                      : 'Normal',
                  statusColor: reading.spo2 > 0 && reading.spo2 < 94
                      ? AuraColors.warning
                      : AuraColors.healthy,
                  chart: SensorChart(
                    data: notifier.getHistoryFor('spo2', window: _timeRange.duration),
                    color: AuraColors.healthy,
                    minY: 85,
                    maxY: 100,
                    unit: '%',
                  ),
                ),
              ),
            ),

            // ── Body Temperature ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _HealthSection(
                  title: 'Body Temperature',
                  icon: Icons.thermostat_rounded,
                  iconColor: AuraColors.warning,
                  currentValue: reading.bodyTemperature > 0
                      ? reading.bodyTemperature.toStringAsFixed(1)
                      : '--',
                  unit: '°C',
                  stats: [
                    _Stat('Baseline', '${profile.baseline.bodyTempLow.toStringAsFixed(1)}-${profile.baseline.bodyTempHigh.toStringAsFixed(1)}°C'),
                  ],
                  statusText: reading.bodyTemperature > profile.baseline.bodyTempHigh + 0.5
                      ? 'Above your baseline'
                      : 'Normal',
                  statusColor: reading.bodyTemperature > profile.baseline.bodyTempHigh + 0.5
                      ? AuraColors.warning
                      : AuraColors.healthy,
                  chart: SensorChart(
                    data: notifier.getHistoryFor('bodyTemp', window: _timeRange.duration),
                    color: AuraColors.warning,
                    minY: 35,
                    maxY: 40,
                    unit: '°C',
                  ),
                ),
              ),
            ),

            // ── Activity ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: AuraCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AuraColors.healthy.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.directions_run_rounded,
                                color: AuraColors.healthy, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text('Activity', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          AnimatedValue(
                            value: reading.activityLevel > 0
                                ? '${(reading.activityLevel * 100).round()}'
                                : '--',
                            style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          Text('%', style: TextStyle(color: subtextColor, fontSize: 16)),
                          const SizedBox(width: 16),
                          StatusBadge(
                            label: reading.activityLevel > 0.7
                                ? 'HIGH'
                                : reading.activityLevel > 0.4
                                    ? 'MODERATE'
                                    : 'LIGHT',
                            color: reading.activityLevel > 0.7
                                ? AuraColors.warning
                                : AuraColors.healthy,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Fall Detection ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: AuraCard(
                  color: reading.fallDetected
                      ? (AuraColors.criticalDim)
                      : null,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: reading.fallDetected
                              ? AuraColors.critical.withValues(alpha: 0.2)
                              : AuraColors.healthy.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          reading.fallDetected
                              ? Icons.warning_rounded
                              : Icons.check_circle_rounded,
                          color: reading.fallDetected ? AuraColors.critical : AuraColors.healthy,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fall Detection',
                              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reading.fallDetected
                                  ? 'Fall detected — please confirm you are safe'
                                  : 'No fall detected',
                              style: TextStyle(color: subtextColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ─── Health Section Widget ───────────────────────────────────────────────────
class _HealthSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String currentValue;
  final String unit;
  final List<_Stat> stats;
  final String statusText;
  final Color statusColor;
  final Widget chart;

  const _HealthSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.currentValue,
    required this.unit,
    required this.stats,
    required this.statusText,
    required this.statusColor,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              StatusBadge(label: statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),

          // Current value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedValue(
                value: currentValue,
                style: TextStyle(color: textColor, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(unit, style: TextStyle(color: subtextColor, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stats row
          Row(
            children: stats.map((s) => Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.label, style: TextStyle(color: subtextColor, fontSize: 11)),
                  Text(s.value, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),

          // Chart
          chart,
        ],
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  const _Stat(this.label, this.value);
}
