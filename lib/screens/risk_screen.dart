import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class RiskScreen extends ConsumerWidget {
  const RiskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risk = ref.watch(riskProvider);
    final aiRecAsync = ref.watch(cloudRiskRecommendationProvider);
    
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text('AI Health Analysis', style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              ),
            ),

            // ── Risk Score ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: AuraCard(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  child: Column(
                    children: [
                      HealthRiskIndicator(score: risk.score, size: 180),
                      const SizedBox(height: 24),
                      if (risk.disasterContext != null) ...[
                        StatusBadge(
                          label: '${risk.disasterContext!.toUpperCase()} ACTIVE',
                          color: AuraColors.critical,
                          icon: Icons.warning_rounded,
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 800.ms),
                        const SizedBox(height: 10),
                      ],
                      // Confidence
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_rounded, color: AuraColors.healthy, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Confidence: ${(risk.confidence * 100).round()}%',
                            style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Detected Pattern ─────────────────────────────────────
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
                              color: AuraColors.techBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.pattern_rounded, color: AuraColors.techBlue, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Text('Detected Pattern', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        risk.pattern,
                        style: TextStyle(color: subtextColor, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Contributing Factors ─────────────────────────────────
            if (risk.factors.isNotEmpty)
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
                                color: AuraColors.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.analytics_rounded, color: AuraColors.warning, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text('Contributing Factors', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...risk.factors.asMap().entries.map((e) =>
                          ContributingFactorBar(factor: e.value)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 200 + e.key * 100))
                              .slideX(begin: -0.1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Why your risk changed ────────────────────────────────
            if (risk.factors.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: AuraCard(
                    color: AuraColors.riskDimColor(risk.score),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why your risk ${risk.score > 30 ? 'increased' : 'is low'}',
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        ...risk.factors.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.circle, color: AuraColors.riskColor(risk.score), size: 6),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  f.description,
                                  style: TextStyle(
                                    color: AuraColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Recommendations ──────────────────────────────────────
            if (risk.recommendations.isNotEmpty)
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
                              child: const Icon(Icons.lightbulb_outline_rounded, color: AuraColors.healthy, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text('Suggested Next Steps', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...risk.recommendations.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AuraColors.healthy.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(color: AuraColors.healthy, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: TextStyle(color: subtextColor, fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),

            // ── AI Recommendations ─────────────────────────────────────
            aiRecAsync.when(
              data: (aiRec) => aiRec != null
                  ? SliverToBoxAdapter(
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
                                      color: AuraColors.techBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.cloud_rounded, color: AuraColors.techBlue, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('Deep AI Analysis', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                aiRec,
                                style: TextStyle(color: subtextColor, fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SliverToBoxAdapter(child: SizedBox.shrink()),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),


            // ── Disclaimer ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  'This analysis is a prototype health indicator and does not constitute medical advice or diagnosis. Consult a healthcare professional for medical concerns.',
                  style: TextStyle(
                    color: AuraColors.textTertiary,
                    fontSize: 11,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
