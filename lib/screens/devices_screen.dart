import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../data/models.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceStateProvider);
    final settings = ref.watch(settingsProvider);
    
    final subtextColor = AuraColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Manager'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Sensor Device ──────────────────────────────────────────
          _DeviceDetailCard(
            title: 'AURA Sensor',
            subtitle: 'Health & Environment Sensor',
            icon: Icons.sensors_rounded,
            device: devices.sensor,
            onConnect: () => ref.read(deviceStateProvider.notifier).connectSensor(),
            onDisconnect: () => ref.read(deviceStateProvider.notifier).disconnectSensor(),
          ),

          const SizedBox(height: 12),

          // ── Data Flow Animation ────────────────────────────────────
          if (devices.sensor.isConnected || devices.wearable.isConnected)
            const _SystemFlowVisualizer(),

          const SizedBox(height: 12),

          // ── Wearable Device ────────────────────────────────────────
          _DeviceDetailCard(
            title: 'AURA Wearable',
            subtitle: 'Alert & Haptic Device',
            icon: Icons.watch_rounded,
            device: devices.wearable,
            onConnect: () => ref.read(deviceStateProvider.notifier).connectWearable(),
            onDisconnect: () => ref.read(deviceStateProvider.notifier).disconnectWearable(),
          ),

          const SizedBox(height: 24),

          // ── Test Alerts (Demo Mode) ────────────────────────────────
          if (settings.demoMode) ...[
            SectionHeader(title: 'Test Wearable Alerts'),
            Text(
              'Send test alerts to the wearable device',
              style: TextStyle(color: subtextColor, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TestAlertChip(
                  label: 'Warning',
                  color: AuraColors.warning,
                  onTap: () => _sendTestCommand(ref, context, WearableCommand.warning),
                ),
                _TestAlertChip(
                  label: 'High Risk',
                  color: AuraColors.moderate,
                  onTap: () => _sendTestCommand(ref, context, WearableCommand.highRisk),
                ),
                _TestAlertChip(
                  label: 'Fall Alert',
                  color: AuraColors.critical,
                  onTap: () => _sendTestCommand(ref, context, WearableCommand.fallAlert),
                ),
                _TestAlertChip(
                  label: 'Heat Alert',
                  color: AuraColors.warning,
                  onTap: () => _sendTestCommand(ref, context, WearableCommand.heatAlert),
                ),
                _TestAlertChip(
                  label: 'SOS',
                  color: AuraColors.critical,
                  onTap: () => _sendTestCommand(ref, context, WearableCommand.sos),
                ),
                _TestAlertChip(
                  label: 'Cancel',
                  color: AuraColors.healthy,
                  onTap: () => _sendTestCommand(ref, context, WearableCommand.cancelAlert),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendTestCommand(WidgetRef ref, BuildContext context, WearableCommand cmd) async {
    final success = await ref.read(deviceStateProvider.notifier).sendCommand(cmd);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Sent ${cmd.code} to wearable'
              : 'Failed — wearable not connected'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _DeviceDetailCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final DeviceInfo device;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _DeviceDetailCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;
    final connected = device.isConnected;
    final stateColor = connected ? AuraColors.healthy : AuraColors.textTertiary;

    return AuraCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: stateColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(color: subtextColor, fontSize: 12)),
                  ],
                ),
              ),
              StatusBadge(
                label: connected ? 'CONNECTED' : 'DISCONNECTED',
                color: stateColor,
              ),
            ],
          ),
          if (connected) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                _DeviceInfoItem(label: 'Battery', value: '${device.battery}%',
                    color: device.battery > 20 ? AuraColors.healthy : AuraColors.warning),
                _DeviceInfoItem(label: 'Signal', value: '${device.signalStrength} dBm', color: AuraColors.techBlue),
                _DeviceInfoItem(label: 'Last Sync',
                    value: device.lastSeen != null ? timeAgo(device.lastSeen!) : '--',
                    color: subtextColor),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: connected
                ? OutlinedButton.icon(
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.bluetooth_disabled_rounded, size: 16),
                    label: const Text('Disconnect'),
                  )
                : ElevatedButton.icon(
                    onPressed: onConnect,
                    icon: const Icon(Icons.bluetooth_searching_rounded, size: 16),
                    label: const Text('Connect'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeviceInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DeviceInfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
              color: AuraColors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TestAlertChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TestAlertChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SystemFlowVisualizer extends StatelessWidget {
  const _SystemFlowVisualizer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNode(Icons.sensors_rounded, 'Sensor', AuraColors.techBlue),
          _buildArrow(),
          _buildNode(Icons.cloud_rounded, 'AURA AI', AuraColors.healthy, scale: 1.2),
          _buildArrow(),
          _buildNode(Icons.watch_rounded, 'Wearable', AuraColors.moderate),
        ],
      ),
    );
  }

  Widget _buildNode(IconData icon, String label, Color color, {double scale = 1.0}) {
    return Column(
      children: [
        Container(
          width: 48 * scale,
          height: 48 * scale,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2),
            ],
          ),
          child: Icon(icon, color: color, size: 24 * scale),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.05, duration: 1500.ms, curve: Curves.easeInOut),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AuraColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.arrow_forward_rounded, color: AuraColors.glassBorder, size: 20)
              .animate(onPlay: (c) => c.repeat())
              .moveX(begin: -4, end: 4, duration: 800.ms)
              .fade(begin: 0.2, end: 1),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
