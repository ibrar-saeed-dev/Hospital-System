import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Red rounded square with white hospital cross logo
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.size = 36,
    this.showText = false,
    this.isDark = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final logoIcon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.add_rounded,
          color: AppColors.white,
          size: size * 0.75,
        ),
      ),
    );

    if (!showText) {
      return logoIcon;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoIcon,
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SMART HOSPITAL',
                style: AppTypography.display(
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.white : AppColors.ink,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  style: AppTypography.label(
                    fontSize: size * 0.26,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
