import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool showDot;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusChip({
    super.key,
    required this.status,
    this.showDot = true,
    this.fontSize = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final statusLower = status.toLowerCase().trim();

    Color dotColor;
    Color bgColor;
    Color textColor;

    if (statusLower.contains('accept') ||
        statusLower.contains('avail') ||
        statusLower.contains('complet') ||
        statusLower.contains('online') ||
        statusLower.contains('approv')) {
      dotColor = AppColors.green;
      bgColor = AppColors.greenTint;
      textColor = AppColors.greenDark;
    } else if (statusLower.contains('pend') ||
        statusLower.contains('in transit') ||
        statusLower.contains('dispatch') ||
        statusLower.contains('warn') ||
        statusLower.contains('medium')) {
      dotColor = AppColors.amber;
      bgColor = AppColors.amberTint;
      textColor = AppColors.amberDark;
    } else if (statusLower.contains('reject') ||
        statusLower.contains('expir') ||
        statusLower.contains('cancel') ||
        statusLower.contains('full') ||
        statusLower.contains('critic') ||
        statusLower.contains('offline')) {
      dotColor = AppColors.primaryRed;
      bgColor = AppColors.redTint;
      textColor = AppColors.redDark;
    } else if (statusLower.contains('info') ||
        statusLower.contains('icu') ||
        statusLower.contains('hdu')) {
      dotColor = AppColors.blue;
      bgColor = AppColors.blueTint;
      textColor = AppColors.blue;
    } else {
      dotColor = AppColors.textSecondary;
      bgColor = AppColors.borderLight;
      textColor = AppColors.textPrimary;
    }

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs,
          ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.radiusPill,
        border: Border.all(
          color: dotColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(
            status.toUpperCase(),
            style: AppTypography.label(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
