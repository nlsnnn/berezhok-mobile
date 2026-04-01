import 'package:flutter/material.dart';

import 'package:berezhok/core/theme/app_colors.dart';
import 'package:berezhok/core/theme/app_spacing.dart';
import 'package:berezhok/core/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, text }

enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  double get _height => switch (widget.size) {
        AppButtonSize.small => 36.0,
        AppButtonSize.medium => 48.0,
        AppButtonSize.large => 56.0,
      };

  double get _borderRadius => switch (widget.size) {
        AppButtonSize.large => AppSpacing.radiusLg,
        _ => AppSpacing.radiusMd,
      };

  double get _fontSize => switch (widget.size) {
        AppButtonSize.small => 13.0,
        AppButtonSize.medium => 16.0,
        AppButtonSize.large => 17.0,
      };

  double get _iconSize => switch (widget.size) {
        AppButtonSize.small => 16.0,
        AppButtonSize.medium => 20.0,
        AppButtonSize.large => 22.0,
      };

  EdgeInsets get _padding => switch (widget.size) {
        AppButtonSize.small =>
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        AppButtonSize.medium =>
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        AppButtonSize.large =>
          const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      };

  Color get _backgroundColor => switch (widget.variant) {
        AppButtonVariant.primary => AppColors.primary,
        AppButtonVariant.secondary => AppColors.accent,
        AppButtonVariant.outline => Colors.transparent,
        AppButtonVariant.text => Colors.transparent,
      };

  Color get _foregroundColor => switch (widget.variant) {
        AppButtonVariant.primary => Colors.white,
        AppButtonVariant.secondary => Colors.white,
        AppButtonVariant.outline => AppColors.primary,
        AppButtonVariant.text => AppColors.primary,
      };

  Color get _disabledBackground => switch (widget.variant) {
        AppButtonVariant.primary ||
        AppButtonVariant.secondary =>
          AppColors.divider,
        AppButtonVariant.outline || AppButtonVariant.text => Colors.transparent,
      };

  Color get _disabledForeground => AppColors.textHint;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final bg = _isEnabled ? _backgroundColor : _disabledBackground;
    final fg = _isEnabled ? _foregroundColor : _disabledForeground;

    final buttonContent = SizedBox(
      height: _height,
      child: Padding(
        padding: _padding,
        child: Row(
          mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading) ...[
              SizedBox(
                width: _iconSize,
                height: _iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ] else if (widget.icon != null) ...[
              Icon(widget.icon, size: _iconSize, color: fg),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              widget.label,
              style: AppTypography.button.copyWith(
                fontSize: _fontSize,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
      side: widget.variant == AppButtonVariant.outline
          ? BorderSide(
              color: _isEnabled ? AppColors.primary : AppColors.divider,
              width: 1.5,
            )
          : BorderSide.none,
    );

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: SizedBox(
        width: widget.fullWidth ? double.infinity : null,
        child: Material(
          color: bg,
          shape: shape,
          child: _isEnabled
              ? InkWell(
                  onTap: widget.onPressed,
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) => setState(() => _isPressed = false),
                  onTapCancel: () => setState(() => _isPressed = false),
                  customBorder: shape,
                  splashColor: fg.withValues(alpha: 0.08),
                  highlightColor: fg.withValues(alpha: 0.04),
                  child: buttonContent,
                )
              : IgnorePointer(
                  child: InkWell(
                    customBorder: shape,
                    child: buttonContent,
                  ),
                ),
        ),
      ),
    );
  }
}
