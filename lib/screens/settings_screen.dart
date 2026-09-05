import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    
    final subtextColor = AuraColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Monitoring ─────────────────────────────────────────────
          const SectionHeader(title: 'Monitoring'),
          AuraCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.monitor_heart_outlined,
                  title: 'Continuous Monitoring',
                  subtitle: 'Keep monitoring sensor data',
                  trailing: Switch(
                    value: settings.continuousMonitoring,
                    onChanged: (_) => notifier.update((s) =>
                        s.copyWith(continuousMonitoring: !s.continuousMonitoring)),
                  ),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.speed_rounded,
                  title: 'Sensor Refresh',
                  subtitle: 'Every ${settings.sensorRefreshMs / 1000}s',
                  trailing: Icon(Icons.chevron_right_rounded, color: subtextColor),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Alerts ─────────────────────────────────────────────────
          const SectionHeader(title: 'Alerts'),
          AuraCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.favorite_rounded,
                  title: 'Health Alerts',
                  subtitle: 'HR, SpO2, temperature alerts',
                  trailing: Switch(value: settings.healthAlerts, onChanged: (_) => notifier.toggleHealthAlerts()),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.whatshot_rounded,
                  title: 'Heat Alerts',
                  subtitle: 'Heat stress warnings',
                  trailing: Switch(value: settings.heatAlerts, onChanged: (_) => notifier.toggleHeatAlerts()),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.cloud_rounded,
                  title: 'Air Quality Alerts',
                  subtitle: 'PM2.5 and PM10 warnings',
                  trailing: Switch(value: settings.airQualityAlerts, onChanged: (_) => notifier.toggleAirQualityAlerts()),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.watch_rounded,
                  title: 'Wearable Alerts',
                  subtitle: 'Send alerts to wearable device',
                  trailing: Switch(value: settings.wearableAlerts, onChanged: (_) => notifier.toggleWearableAlerts()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Privacy ────────────────────────────────────────────────
          const SectionHeader(title: 'Privacy & Security'),
          AuraCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.share_rounded,
                  title: 'Data Sharing',
                  subtitle: 'Share anonymized data with backend',
                  trailing: Switch(value: settings.dataSharing, onChanged: (_) => notifier.toggleDataSharing()),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.location_on_rounded,
                  title: 'Location',
                  subtitle: 'Used for emergencies only',
                  trailing: Switch(value: settings.locationEnabled, onChanged: (_) => notifier.toggleLocation()),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.security_rounded,
                  title: 'On-Device Processing',
                  subtitle: 'Risk analysis runs locally',
                  trailing: Icon(Icons.check_circle_rounded, color: AuraColors.healthy, size: 20),
                ),
                const Divider(),
                _SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete My Data',
                  subtitle: 'Remove all stored health data',
                  trailing: Icon(Icons.chevron_right_rounded, color: subtextColor),
                  onTap: () => _showDeleteConfirmation(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Appearance ─────────────────────────────────────────────
          const SectionHeader(title: 'Appearance'),
          AuraCard(
            child: Column(
              children: [
                ...ThemeMode.values.map((mode) => _SettingsTile(
                  icon: mode == ThemeMode.light
                      ? Icons.dark_mode_rounded
                      : mode == ThemeMode.light
                          ? Icons.light_mode_rounded
                          : Icons.auto_mode_rounded,
                  title: mode == ThemeMode.system ? 'System' : mode == ThemeMode.light ? 'Dark' : 'Light',
                  subtitle: null,
                  trailing: Radio<ThemeMode>(
                    value: mode,
                    groupValue: settings.themeMode,
                    onChanged: (v) => notifier.setThemeMode(v!),
                    activeColor: AuraColors.healthy,
                  ),
                  onTap: () => notifier.setThemeMode(mode),
                )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Demo Mode ──────────────────────────────────────────────
          const SectionHeader(title: 'Developer'),
          AuraCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.science_rounded,
                  title: 'Demo Mode',
                  subtitle: 'Use simulated sensor data',
                  trailing: Switch(
                    value: settings.demoMode,
                    onChanged: (_) => notifier.setDemoMode(!settings.demoMode),
                  ),
                ),
                if (settings.demoMode) ...[
                  const Divider(),
                  _SettingsTile(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Demo Scenario',
                    subtitle: settings.demoScenario.label,
                    trailing: Icon(Icons.chevron_right_rounded, color: subtextColor),
                    onTap: () => _showScenarioPicker(context, ref),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showScenarioPicker(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Demo Scenario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ...DemoScenario.values.map((s) => ListTile(
              leading: Icon(
                s == settings.demoScenario ? Icons.radio_button_checked : Icons.radio_button_off,
                color: s == settings.demoScenario ? AuraColors.healthy : null,
              ),
              title: Text(s.label),
              subtitle: Text(s.description, style: const TextStyle(fontSize: 12)),
              onTap: () {
                ref.read(settingsProvider.notifier).setDemoScenario(s);
                ref.read(demoEngineProvider).setScenario(s);
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text('This will permanently delete all your stored health data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AuraColors.critical),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AuraColors.healthy, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(color: subtextColor, fontSize: 12)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
