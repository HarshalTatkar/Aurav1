import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Start sensor data stream after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDemo();
    });
  }

  Future<void> _initializeDemo() async {
    final settings = ref.read(settingsProvider);
    if (settings.demoMode) {
      // Connect devices
      await ref.read(deviceStateProvider.notifier).connectSensor();
      await ref.read(deviceStateProvider.notifier).connectWearable();
      // Start sensor listening
      ref.read(sensorDataProvider.notifier).startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(sensorDataProvider);
    final risk = ref.watch(riskProvider);
    final profile = ref.watch(profileProvider);
    final devices = ref.watch(deviceStateProvider);
    final settings = ref.watch(settingsProvider);
    final envData = ref.watch(environmentDataProvider);

    // Feed real env data into demo engine
    if (envData.isReal) {
      ref.read(demoEngineProvider).setRealEnvironmentData(envData);
    }

    // Trigger health processor
    ref.watch(healthProcessorProvider);

    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;

    return Scaffold(
      backgroundColor: AuraColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${getGreeting()}, ${profile.name}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            LiveIndicator(lastUpdated: reading.timestamp),
                            if (envData.locationName != null) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.location_on_rounded, color: subtextColor, size: 14),
                              const SizedBox(width: 4),
                              Text(envData.locationName!, style: TextStyle(color: subtextColor, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (settings.demoMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AuraColors.techBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEMO',
                              style: TextStyle(
                                color: AuraColors.techBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AuraColors.surfaceElevated,
                            child: Text(
                              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: AuraColors.healthy,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Risk Score Card ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: AuraCard(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  onTap: () => context.go('/risk'),
                  child: Column(
                    children: [
                      HealthRiskIndicator(score: risk.score, size: 240),
                      const SizedBox(height: 20),
                      if (settings.disasterMode != DisasterMode.none) ...[
                        const SizedBox(height: 12),
                        StatusBadge(
                          label: settings.disasterMode.label.toUpperCase(),
                          color: AuraColors.critical,
                          icon: Icons.warning_rounded,
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 800.ms),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Vital Signs Grid ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: const SectionHeader(title: 'Vital Signs'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0, // Perfect Square Symmetry
                ),
                delegate: SliverChildListDelegate([
                  VitalTile(
                    icon: Icons.favorite_rounded,
                    iconColor: AuraColors.critical,
                    label: 'Heart Rate',
                    value: reading.heartRate > 0 ? formatBpm(reading.heartRate) : '--',
                    numericValue: reading.heartRate > 0 ? reading.heartRate : null,
                    unit: 'BPM',
                    subtitle: reading.heartRate > 0
                        ? 'Baseline ${profile.baseline.hrLow.round()}-${profile.baseline.hrHigh.round()}'
                        : null,
                  ),
                  VitalTile(
                    icon: Icons.air_rounded,
                    iconColor: AuraColors.techBlue,
                    label: 'SpO2',
                    value: reading.spo2 > 0 ? reading.spo2.round().toString() : '--',
                    numericValue: reading.spo2 > 0 ? reading.spo2 : null,
                    unit: '%',
                    subtitle: reading.spo2 > 0 && reading.spo2 < 95
                        ? 'Below normal'
                        : 'Normal range',
                  ),
                  VitalTile(
                    icon: Icons.thermostat_rounded,
                    iconColor: AuraColors.warning,
                    label: 'Body Temp',
                    value: reading.bodyTemperature > 0
                        ? reading.bodyTemperature.toStringAsFixed(1)
                        : '--',
                    numericValue: reading.bodyTemperature > 0 ? reading.bodyTemperature : null,
                    fractionDigits: 1,
                    unit: '°C',
                    subtitle: reading.bodyTemperature > profile.baseline.bodyTempHigh
                        ? 'Above baseline'
                        : 'Normal',
                  ),
                  VitalTile(
                    icon: Icons.directions_run_rounded,
                    iconColor: AuraColors.healthy,
                    label: 'Activity',
                    value: reading.activityLevel > 0
                        ? '${(reading.activityLevel * 100).round()}'
                        : '--',
                    numericValue: reading.activityLevel > 0 ? (reading.activityLevel * 100) : null,
                    unit: '%',
                    subtitle: reading.activityLevel > 0.7
                        ? 'High activity'
                        : reading.activityLevel > 0.4
                            ? 'Moderate'
                            : 'Light',
                  ),
                ]),
              ),
            ),

            // ── Environment Summary ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SectionHeader(
                  title: 'Environment',
                  action: 'Details',
                  onAction: () => context.go('/environment'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AuraCard(
                  onTap: () => context.go('/environment'),
                  child: Row(
                    children: [
                      _EnvItem(
                        icon: Icons.thermostat_outlined,
                        value: envData.temperature > 0
                            ? '${envData.temperature.round()}°C'
                            : (reading.ambientTemperature > 0 ? '${reading.ambientTemperature.round()}°C' : '--'),
                        label: 'Ambient',
                        color: (envData.isReal ? envData.temperature : reading.ambientTemperature) > 35
                            ? AuraColors.warning
                            : AuraColors.healthy,
                      ),
                      _envDivider(),
                      _EnvItem(
                        icon: Icons.water_drop_outlined,
                        value: envData.humidity > 0
                            ? '${envData.humidity.round()}%'
                            : (reading.humidity > 0 ? '${reading.humidity.round()}%' : '--'),
                        label: 'Humidity',
                        color: (envData.isReal ? envData.humidity : reading.humidity) > 70
                            ? AuraColors.warning
                            : AuraColors.healthy,
                      ),
                      _envDivider(),
                      _EnvItem(
                        icon: Icons.cloud_outlined,
                        value: envData.pm25 > 0
                            ? aqiLabel(envData.pm25).split(' ').first
                            : (reading.pm25 > 0 ? aqiLabel(reading.pm25).split(' ').first : '--'),
                        label: 'Air',
                        color: aqiColor(envData.isReal ? envData.pm25 : reading.pm25),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── AI Insight ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: const SectionHeader(title: 'AI Insight'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AuraCard(
                  onTap: () => context.go('/risk'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AuraColors.techBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.psychology_rounded,
                                color: AuraColors.techBlue, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Health Analysis',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AuraColors.textTertiary, size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        risk.pattern,
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      if (risk.recommendations.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AuraColors.riskColor(risk.score).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(AuraRadius.sm),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb_outline_rounded,
                                  color: AuraColors.riskColor(risk.score), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  risk.recommendations.first,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Device Status ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SectionHeader(
                  title: 'Devices',
                  action: 'Manage',
                  onAction: () => context.push('/devices'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _DeviceChip(
                        icon: Icons.sensors_rounded,
                        name: 'Sensor',
                        connected: devices.sensor.isConnected,
                        battery: devices.sensor.battery,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DeviceChip(
                        icon: Icons.watch_rounded,
                        name: 'Wearable',
                        connected: devices.wearable.isConnected,
                        battery: devices.wearable.battery,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick Actions ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: const SectionHeader(title: 'Quick Actions'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _QuickAction(
                      icon: Icons.sos_rounded,
                      label: 'SOS',
                      color: AuraColors.critical,
                      onTap: () => context.push('/emergency'),
                    ),
                    _QuickAction(
                      icon: Icons.warning_rounded,
                      label: 'Disaster',
                      color: AuraColors.warning,
                      onTap: () => context.push('/emergency'),
                    ),
                    _QuickAction(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      color: AuraColors.healthy,
                      onTap: () => context.push('/settings'),
                    ),
                  ],
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

  Widget _envDivider() => Container(
        width: 0.5,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: AuraColors.glassBorder,
      );
}

// ─── Environment item in home card ───────────────────────────────────────────
class _EnvItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _EnvItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    
    final subtextColor = AuraColors.textSecondary;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          AnimatedValue(
            value: value,
            style: TextStyle(
              color: AuraColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: subtextColor, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Device chip ─────────────────────────────────────────────────────────────
class _DeviceChip extends StatelessWidget {
  final IconData icon;
  final String name;
  final bool connected;
  final int battery;

  const _DeviceChip({
    required this.icon,
    required this.name,
    required this.connected,
    required this.battery,
  });

  @override
  Widget build(BuildContext context) {
    
    final color = connected ? AuraColors.healthy : AuraColors.textTertiary;

    return AuraCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AuraColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  connected ? '$battery%' : 'Disconnected',
                  style: TextStyle(
                    color: AuraColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action ────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AuraRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AuraRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
