import 'package:flutter/material.dart';
import '../config/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;
  final double? width;
  final bool isFullWidth;
  final double fontSize;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.height = 52,
    this.width,
    this.isFullWidth = true,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = AppColors.primaryRed;
        fgColor = AppColors.white;
        break;
      case AppButtonVariant.secondary:
        bgColor = Colors.transparent;
        fgColor = AppColors.ink;
        borderSide = const BorderSide(color: AppColors.ink, width: 1.5);
        break;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = AppColors.ink;
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.redTint;
        fgColor = AppColors.primaryRed;
        borderSide = const BorderSide(color: AppColors.primaryRed, width: 1);
        break;
    }

    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget childContent;
    if (isLoading) {
      childContent = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == AppButtonVariant.primary
                ? AppColors.white
                : AppColors.primaryRed,
          ),
        ),
      );
    } else {
      childContent = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: fgColor),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            text,
            style: AppTypography.button(
              fontSize: fontSize,
              color: fgColor,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(trailingIcon, size: fontSize + 3, color: fgColor),
          ],
        ],
      );
    }

    final button = Material(
      color: effectiveOnPressed != null ? bgColor : bgColor.withValues(alpha: 0.5),
      borderRadius: AppRadius.radiusMd,
      child: InkWell(
        onTap: effectiveOnPressed,
        borderRadius: AppRadius.radiusMd,
        child: Container(
          height: height,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusMd,
            border: borderSide != BorderSide.none
                ? Border.fromBorderSide(borderSide)
                : null,
          ),
          child: Center(child: childContent),
        ),
      ),
    );

    if (isFullWidth && width == null) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
