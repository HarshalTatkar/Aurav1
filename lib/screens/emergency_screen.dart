import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  bool _sosActivated = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final reading = ref.watch(sensorDataProvider);
    final settings = ref.watch(settingsProvider);
    
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── SOS Button ─────────────────────────────────────────────
          AuraCard(
            gradient: _sosActivated
                ? AuraColors.primaryGradient
                : null,
            color: _sosActivated ? null : (AuraColors.criticalDim),
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Icon(
                  _sosActivated ? Icons.emergency_rounded : Icons.sos_rounded,
                  color: _sosActivated ? Colors.white : AuraColors.critical,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _sosActivated ? 'SOS ACTIVATED' : 'Emergency Assistance',
                  style: TextStyle(
                    color: _sosActivated ? Colors.white : textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _sosActivated
                      ? 'Your emergency event has been created.\nEmergency contacts are being notified.'
                      : 'Activate SOS to create an emergency event\nand notify your emergency contacts.',
                  style: TextStyle(
                    color: _sosActivated ? Colors.white70 : subtextColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (!_sosActivated)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showSosConfirmation(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraColors.critical,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('SEND SOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _sosActivated = false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('CANCEL SOS'),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Disaster Mode ──────────────────────────────────────────
          const SectionHeader(title: 'Disaster Mode'),
          AuraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active: ${settings.disasterMode.label}',
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  settings.disasterMode.description,
                  style: TextStyle(color: subtextColor, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DisasterMode.values.map((mode) {
                    final active = settings.disasterMode == mode;
                    return ChoiceChip(
                      label: Text(mode.label),
                      selected: active,
                      onSelected: (_) => ref.read(settingsProvider.notifier).setDisasterMode(mode),
                      selectedColor: mode == DisasterMode.none
                          ? AuraColors.healthy.withValues(alpha: 0.15)
                          : AuraColors.warning.withValues(alpha: 0.15),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: active
                            ? (mode == DisasterMode.none ? AuraColors.healthy : AuraColors.warning)
                            : subtextColor,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Emergency Contacts ─────────────────────────────────────
          const SectionHeader(title: 'Emergency Contacts'),
          ...profile.emergencyContacts.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AuraCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AuraColors.healthy.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_rounded, color: AuraColors.healthy, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contact ${e.key + 1}', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(e.value, style: TextStyle(color: subtextColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.call_rounded, color: AuraColors.healthy, size: 20),
                ],
              ),
            ),
          )),

          if (profile.emergencyContacts.isEmpty)
            AuraCard(
              child: Column(
                children: [
                  const Icon(Icons.contacts_outlined, color: AuraColors.textTertiary, size: 32),
                  const SizedBox(height: 8),
                  Text('No emergency contacts set', style: TextStyle(color: subtextColor, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Add Contact'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // ── Current Health Snapshot ─────────────────────────────────
          const SectionHeader(title: 'Current Health Snapshot'),
          AuraCard(
            child: Column(
              children: [
                _SnapshotRow(label: 'Heart Rate', value: '${reading.heartRate.round()} BPM'),
                _SnapshotRow(label: 'SpO2', value: '${reading.spo2.round()}%'),
                _SnapshotRow(label: 'Body Temp', value: formatTemp(reading.bodyTemperature)),
                _SnapshotRow(label: 'Ambient Temp', value: formatTemp(reading.ambientTemperature)),
                _SnapshotRow(label: 'Fall Detected', value: reading.fallDetected ? 'YES' : 'No'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSosConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm SOS'),
        content: const Text(
          'This will create an emergency event and notify your configured emergency contacts.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _sosActivated = true);
              // Send SOS to wearable
              ref.read(deviceStateProvider.notifier).sendCommand(WearableCommand.sos);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AuraColors.critical),
            child: const Text('CONFIRM SOS'),
          ),
        ],
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  final String label;
  final String value;

  const _SnapshotRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
              color: AuraColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(
              color: AuraColors.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
