import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class MatchRing extends StatelessWidget {
  final double score; // 0 to 100 (or 0.0 to 1.0)
  final double size;
  final double strokeWidth;
  final String? label;
  final Color? ringColor;

  const MatchRing({
    super.key,
    required this.score,
    this.size = 56,
    this.strokeWidth = 4.5,
    this.label,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = score > 1.0 ? (score / 100.0).clamp(0.0, 1.0) : score.clamp(0.0, 1.0);
    final displayInt = score > 1.0 ? score.round() : (score * 100).round();
    final effectiveColor = ringColor ?? (normalized >= 0.7 ? AppColors.primaryRed : (normalized >= 0.4 ? AppColors.amber : AppColors.textSecondary));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _MatchRingPainter(
                  progress: normalized,
                  strokeWidth: strokeWidth,
                  color: effectiveColor,
                  trackColor: AppColors.borderLight,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$displayInt%',
                    style: AppTypography.display(
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            label!,
            style: AppTypography.label(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _MatchRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  _MatchRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MatchRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}
