import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../data/models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AURA CARD
// ═══════════════════════════════════════════════════════════════════════════════
class AuraCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final LinearGradient? gradient;
  final Color? color;
  final VoidCallback? onTap;

  const AuraCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.color,
    this.onTap,
  });

  @override
  State<AuraCard> createState() => _AuraCardState();
}

class _AuraCardState extends State<AuraCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, _isHovered ? -2.0 : 0, 0),
      decoration: BoxDecoration(
        gradient: widget.gradient,
        color: widget.gradient == null ? (widget.color ?? AuraColors.surface) : null,
        borderRadius: BorderRadius.circular(AuraRadius.md),
        border: Border.all(color: AuraColors.glassBorder, width: 1.0),
        boxShadow: _isHovered ? AuraShadows.cardElevated : AuraShadows.card,
      ),
      padding: widget.padding ?? const EdgeInsets.all(AuraSpacing.lg),
      child: widget.child,
    );

    card = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: card,
    );

    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () {
          _controller.forward().then((_) => _controller.reverse());
          widget.onTap!();
        },
        child: ScaleTransition(scale: _scaleAnim, child: card),
      );
    }

    return card;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VITAL TILE — displays a sensor value with icon, label, and trend
// ═══════════════════════════════════════════════════════════════════════════════
class VitalTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final num? numericValue;
  final int fractionDigits;
  final String? unit;
  final String? subtitle;
  final VoidCallback? onTap;

  const VitalTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.numericValue,
    this.fractionDigits = 0,
    this.unit,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;

    return AuraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                numericValue != null
                    ? AnimatedFlipCounter(
                        value: numericValue!,
                        fractionDigits: fractionDigits,
                        textStyle: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      )
                    : AnimatedValue(
                        value: value,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      unit!,
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Tiny sparkline
                SizedBox(
                  width: 40,
                  height: 20,
                  child: CustomPaint(
                    painter: _SparklinePainter(color: iconColor),
                  ),
                ),
              ],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  final bool isUp; // true = trending up, false = trending down
  _SparklinePainter({required this.color, this.isUp = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isUp) {
      path.moveTo(0, size.height * 0.7);
      path.lineTo(size.width * 0.3, size.height * 0.5);
      path.lineTo(size.width * 0.6, size.height * 0.6);
      path.lineTo(size.width, size.height * 0.2);
    } else {
      path.moveTo(0, size.height * 0.3);
      path.lineTo(size.width * 0.3, size.height * 0.5);
      path.lineTo(size.width * 0.6, size.height * 0.4);
      path.lineTo(size.width, size.height * 0.7);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.isUp != isUp || old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED VALUE — smoothly transitions displayed text
// ═══════════════════════════════════════════════════════════════════════════════
class AnimatedValue extends StatefulWidget {
  final String value;
  final TextStyle? style;

  const AnimatedValue({super.key, required this.value, this.style});

  @override
  State<AnimatedValue> createState() => _AnimatedValueState();
}

class _AnimatedValueState extends State<AnimatedValue>
    with SingleTickerProviderStateMixin {
  String _displayValue = '';

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
  }

  @override
  void didUpdateWidget(AnimatedValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() => _displayValue = widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: Text(
        _displayValue,
        key: ValueKey(_displayValue),
        style: widget.style,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HEALTH RISK INDICATOR — premium 3D layered risk score indicator
// ═══════════════════════════════════════════════════════════════════════════════
class HealthRiskIndicator extends StatelessWidget {
  final int score;
  final double size;
  final bool showLabel;

  const HealthRiskIndicator({
    super.key,
    required this.score,
    this.size = 200,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AuraColors.riskColor(score);
    final level = RiskLevel.fromScore(score);
    final textColor = AuraColors.textPrimary;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ring Layer with subtle breathing
              CustomPaint(
                size: Size(size, size),
                painter: _HealthRiskIndicatorPainter(
                  progress: value,
                  color: color,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.015, duration: 4000.ms, curve: Curves.easeInOut),
              
              // Central Value Layer
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: score),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) => AnimatedFlipCounter(
                      value: val.toDouble(),
                      textStyle: TextStyle(
                        color: textColor,
                        fontSize: size * 0.28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                  if (showLabel)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AuraColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AuraRadius.pill),
                        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
                        boxShadow: AuraShadows.subtle,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            level.label.toUpperCase(),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HealthRiskIndicatorPainter extends CustomPainter {
  final double progress;
  final Color color;

  _HealthRiskIndicatorPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const startAngle = -pi / 2;
    const sweepMax = 2 * pi;

    // Background ring
    final bgPaint = Paint()
      ..color = AuraColors.glassBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepMax, false, bgPaint);

    // Progress ring
    if (progress > 0) {
      final sweepAngle = sweepMax * progress;

      // Subtle glow behind progress
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, glowPaint);

      // Solid progress
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HealthRiskIndicatorPainter old) => old.progress != progress || old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ═══════════════════════════════════════════════════════════════════════════════
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.fromRisk(int score) {
    final level = RiskLevel.fromScore(score);
    return StatusBadge(
      label: level.label.toUpperCase(),
      color: AuraColors.riskColor(score),
      icon: riskIcon(score),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AuraRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LIVE INDICATOR — pulsing dot
// ═══════════════════════════════════════════════════════════════════════════════
class LiveIndicator extends StatelessWidget {
  final DateTime? lastUpdated;

  const LiveIndicator({super.key, this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    
    final subtextColor = AuraColors.textTertiary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AuraColors.healthy,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AuraColors.healthy.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.3, 1.3),
              duration: 1200.ms,
            )
            .then()
            .scale(
              begin: const Offset(1.3, 1.3),
              end: const Offset(1, 1),
              duration: 1200.ms,
            ),
        const SizedBox(width: 6),
        Text(
          'Live',
          style: TextStyle(
            color: AuraColors.healthy,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (lastUpdated != null) ...[
          Text(
            ' · ${timeAgo(lastUpdated!)}',
            style: TextStyle(color: subtextColor, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONTRIBUTING FACTOR BAR — animated horizontal progress
// ═══════════════════════════════════════════════════════════════════════════════
class ContributingFactorBar extends StatelessWidget {
  final ContributingFactor factor;

  const ContributingFactorBar({super.key, required this.factor});

  @override
  Widget build(BuildContext context) {
    
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;
    final bgColor = AuraColors.glassBorder;
    final barColor = AuraColors.riskColor((factor.weight * 100).round());

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  factor.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${factor.rawValue.toStringAsFixed(factor.rawValue >= 100 ? 0 : 1)} ${factor.unit}',
                style: TextStyle(color: subtextColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: factor.weight),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Stack(
                  children: [
                    Container(color: bgColor),
                    FractionallySizedBox(
                      widthFactor: value.clamp(0, 1),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [barColor.withValues(alpha: 0.7), barColor],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            factor.description,
            style: TextStyle(color: subtextColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SENSOR LINE CHART — reusable chart wrapper
// ═══════════════════════════════════════════════════════════════════════════════
class SensorChart extends StatelessWidget {
  final List<SensorHistoryPoint> data;
  final Color color;
  final double? minY;
  final double? maxY;
  final String? unit;

  const SensorChart({
    super.key,
    required this.data,
    required this.color,
    this.minY,
    this.maxY,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    
    final gridColor = (AuraColors.glassBorder).withValues(alpha: 0.5);

    if (data.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Collecting data...',
            style: TextStyle(
              color: AuraColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: null,
            getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(v >= 100 ? 0 : 1),
                  style: TextStyle(
                    color: AuraColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  '${s.y.toStringAsFixed(1)}${unit ?? ''}',
                  TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                );
              }).toList(),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ALERT CARD
// ═══════════════════════════════════════════════════════════════════════════════
class AlertCard extends StatelessWidget {
  final HealthAlert alert;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;

  const AlertCard({
    super.key,
    required this.alert,
    this.onAcknowledge,
    this.onResolve,
  });

  Color _severityColor() {
    switch (alert.severity) {
      case AlertSeverity.info:
        return AuraColors.healthy;
      case AlertSeverity.warning:
        return AuraColors.warning;
      case AlertSeverity.high:
        return AuraColors.moderate;
      case AlertSeverity.critical:
        return AuraColors.critical;
    }
  }

  IconData _severityIcon() {
    switch (alert.severity) {
      case AlertSeverity.info:
        return Icons.info_outline_rounded;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.high:
        return Icons.warning_rounded;
      case AlertSeverity.critical:
        return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor();
    
    final subtextColor = AuraColors.textSecondary;
    final isResolved = alert.status == AlertStatus.resolved;

    return Opacity(
      opacity: isResolved ? 0.5 : 1.0,
      child: AuraCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_severityIcon(), color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.type.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeAgo(alert.timestamp),
                        style: TextStyle(color: subtextColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: alert.status.name.toUpperCase(),
                  color: alert.status == AlertStatus.active
                      ? color
                      : AuraColors.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              alert.reason,
              style: TextStyle(
                color: AuraColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              alert.recommendation,
              style: TextStyle(color: subtextColor, fontSize: 12, height: 1.4),
            ),
            if (alert.wearableNotified) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.watch_rounded, color: AuraColors.healthy, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    alert.wearableAcknowledged
                        ? 'Wearable acknowledged'
                        : 'Wearable alert sent',
                    style: TextStyle(
                      color: AuraColors.healthy,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (alert.status == AlertStatus.active) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onAcknowledge != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onAcknowledge,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text('Acknowledge', style: TextStyle(color: color, fontSize: 12)),
                      ),
                    ),
                  if (onAcknowledge != null && onResolve != null)
                    const SizedBox(width: 10),
                  if (onResolve != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onResolve,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Resolve', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════════
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AuraColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  color: AuraColors.healthy,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHIMMER LOADER
// ═══════════════════════════════════════════════════════════════════════════════
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AuraColors.glassBorder,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1500.ms, color: (Colors.white).withValues(alpha: 0.05));
  }
}
