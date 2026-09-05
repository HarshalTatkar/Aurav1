import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class EnvironmentScreen extends ConsumerWidget {
  const EnvironmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(sensorDataProvider);
    
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;

    final heatIndex = reading.ambientTemperature > 0
        ? calculateHeatIndex(reading.ambientTemperature, reading.humidity)
        : 0.0;

    return Scaffold(
      backgroundColor: AuraColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Environment', style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                    LiveIndicator(lastUpdated: reading.timestamp),
                  ],
                ),
              ),
            ),

            // ── Temperature Hero ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: AuraCard(
                  gradient: reading.ambientTemperature > 35
                      ? LinearGradient(
                          colors: [
                            AuraColors.warning.withValues(alpha: 0.15),
                            AuraColors.critical.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.thermostat_rounded,
                        color: reading.ambientTemperature > 35
                            ? AuraColors.warning
                            : AuraColors.moderate,
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      AnimatedValue(
                        value: reading.ambientTemperature > 0
                            ? '${reading.ambientTemperature.round()}°C'
                            : '--',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reading.ambientTemperature > 38
                            ? 'Extreme Heat'
                            : reading.ambientTemperature > 35
                                ? 'High Heat'
                                : reading.ambientTemperature > 30
                                    ? 'Warm'
                                    : 'Comfortable',
                        style: TextStyle(
                          color: reading.ambientTemperature > 35
                              ? AuraColors.warning
                              : AuraColors.healthy,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Metrics Grid ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildListDelegate([
                  VitalTile(
                    icon: Icons.water_drop_rounded,
                    iconColor: AuraColors.techBlue,
                    label: 'Humidity',
                    value: reading.humidity > 0 ? '${reading.humidity.round()}' : '--',
                    unit: '%',
                    subtitle: reading.humidity > 70 ? 'High humidity' : 'Normal',
                  ),
                  VitalTile(
                    icon: Icons.whatshot_rounded,
                    iconColor: heatIndexColor(heatIndex),
                    label: 'Heat Index',
                    value: heatIndex > 0 ? '${heatIndex.round()}' : '--',
                    unit: '°C',
                    subtitle: heatIndexLabel(heatIndex),
                  ),
                  VitalTile(
                    icon: Icons.blur_on_rounded,
                    iconColor: aqiColor(reading.pm25),
                    label: 'PM2.5',
                    value: reading.pm25 > 0 ? '${reading.pm25.round()}' : '--',
                    unit: 'µg/m³',
                    subtitle: aqiLabel(reading.pm25),
                  ),
                  VitalTile(
                    icon: Icons.grain_rounded,
                    iconColor: aqiColor(reading.pm10 * 0.7),
                    label: 'PM10',
                    value: reading.pm10 > 0 ? '${reading.pm10.round()}' : '--',
                    unit: 'µg/m³',
                    subtitle: reading.pm10 > 100 ? 'Elevated' : 'Normal',
                  ),
                ]),
              ),
            ),

            // ── Air Quality Summary ──────────────────────────────────
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
                              color: aqiColor(reading.pm25).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.cloud_rounded, color: aqiColor(reading.pm25), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text('Air Quality', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          StatusBadge(
                            label: aqiLabel(reading.pm25).toUpperCase(),
                            color: aqiColor(reading.pm25),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // AQI bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: (reading.pm25 / 300).clamp(0, 1)),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, child) => Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AuraColors.healthy,
                                        AuraColors.warning,
                                        AuraColors.moderate,
                                        AuraColors.critical,
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: value * (MediaQuery.of(context).size.width - 74),
                                  child: Container(
                                    width: 4,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Environmental Advisory ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: AuraCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AuraColors.techBlue, size: 18),
                          const SizedBox(width: 8),
                          Text('Environmental Advisory', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _getAdvisory(reading.ambientTemperature, reading.humidity, reading.pm25),
                        style: TextStyle(color: subtextColor, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Chart ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: AuraCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Temperature Trend', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SensorChart(
                        data: ref.read(sensorDataProvider.notifier)
                            .getHistoryFor('ambientTemp', window: const Duration(hours: 1)),
                        color: AuraColors.warning,
                        minY: 20,
                        maxY: 50,
                        unit: '°C',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  String _getAdvisory(double temp, double humidity, double pm25) {
    final parts = <String>[];
    if (temp > 38 && humidity > 70) {
      parts.add('High heat combined with high humidity significantly increases heat-stress risk during physical activity. Consider staying indoors and hydrating frequently.');
    } else if (temp > 35) {
      parts.add('Elevated ambient temperature may increase heat-related health risks. Limit prolonged outdoor exposure.');
    } else if (temp > 30) {
      parts.add('Warm conditions. Stay hydrated during outdoor activities.');
    } else {
      parts.add('Temperature is within comfortable range.');
    }

    if (pm25 > 150) {
      parts.add('Air quality is poor. Consider wearing a mask and reducing outdoor time.');
    } else if (pm25 > 75) {
      parts.add('Air quality is moderate. Sensitive individuals should limit prolonged outdoor exertion.');
    }

    return parts.join('\n\n');
  }
}
