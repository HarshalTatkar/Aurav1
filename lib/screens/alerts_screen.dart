import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;

    final activeCount = alerts.where((a) => a.status == AlertStatus.active).length;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Alerts', style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                    if (activeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AuraColors.critical.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AuraRadius.pill),
                        ),
                        child: Text(
                          '$activeCount active',
                          style: const TextStyle(color: AuraColors.critical, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (alerts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          color: AuraColors.textTertiary,
                          size: 48),
                      const SizedBox(height: 16),
                      Text('No alerts yet', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        'Alerts will appear here when unusual\npatterns are detected.',
                        style: TextStyle(color: subtextColor, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final alert = alerts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AlertCard(
                          alert: alert,
                          onAcknowledge: alert.status == AlertStatus.active
                              ? () => ref.read(alertsProvider.notifier).acknowledge(alert.id)
                              : null,
                          onResolve: alert.status != AlertStatus.resolved
                              ? () => ref.read(alertsProvider.notifier).resolve(alert.id)
                              : null,
                        ),
                      );
                    },
                    childCount: alerts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
