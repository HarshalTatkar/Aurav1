import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;
    final baseline = profile.baseline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Avatar + Name ──────────────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AuraColors.healthy.withValues(alpha: 0.12),
                  child: Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AuraColors.healthy,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(profile.name, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w700)),
                Text(profile.email, style: TextStyle(color: subtextColor, fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Personal Info ──────────────────────────────────────────
          const SectionHeader(title: 'Personal Information'),
          AuraCard(
            child: Column(
              children: [
                _ProfileRow(label: 'Age', value: profile.age != null ? '${profile.age} years' : '--'),
                _ProfileRow(label: 'Weight', value: profile.weight != null ? '${profile.weight} kg' : '--'),
                _ProfileRow(label: 'Height', value: profile.height != null ? '${profile.height} cm' : '--'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Baseline ───────────────────────────────────────────────
          const SectionHeader(title: 'Personal Baseline'),
          AuraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(
                      label: baseline.isCalibrated ? 'CALIBRATED' : 'DEFAULT',
                      color: baseline.isCalibrated ? AuraColors.healthy : AuraColors.warning,
                    ),
                    if (baseline.calibratedAt != null) ...[
                      const SizedBox(width: 8),
                      Text('${baseline.readingsCount} readings', style: TextStyle(color: subtextColor, fontSize: 11)),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                _ProfileRow(label: 'Heart Rate', value: '${baseline.hrLow.round()}-${baseline.hrHigh.round()} BPM'),
                _ProfileRow(label: 'SpO2', value: '≥ ${baseline.spo2Low.round()}%'),
                _ProfileRow(label: 'Body Temp', value: '${baseline.bodyTempLow.toStringAsFixed(1)}-${baseline.bodyTempHigh.toStringAsFixed(1)}°C'),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Recalibrate Baseline'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Emergency Contacts ─────────────────────────────────────
          const SectionHeader(title: 'Emergency Contacts'),
          ...profile.emergencyContacts.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AuraCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.phone_rounded, color: AuraColors.healthy, size: 18),
                  const SizedBox(width: 12),
                  Text(c, style: TextStyle(color: textColor, fontSize: 14)),
                ],
              ),
            ),
          )),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AuraColors.critical,
                side: BorderSide(color: AuraColors.critical.withValues(alpha: 0.3)),
              ),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

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
              fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
