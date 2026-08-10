import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/spacing.dart';
import '../constants/shadows.dart';

enum JagoButtonType { primary, secondary, outline, text, danger, success }
enum JagoButtonSize { small, medium, large }

class JagoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final JagoButtonType type;
  final JagoButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final bool hasShadow;

  const JagoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = JagoButtonType.primary,
    this.size = JagoButtonSize.large,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: _shouldShowShadow ? _getShadow() : null,
        borderRadius: AppSpacing.borderRadiusButton,
      ),
      child: _buildButton(),
    );
  }

  bool get _shouldShowShadow => hasShadow && type == JagoButtonType.primary && onPressed != null;

  List<BoxShadow>? _getShadow() {
    return AppShadows.buttonShadow;
  }

  Widget _buildButton() {
    switch (type) {
      case JagoButtonType.primary:
        return _buildPrimaryButton();
      case JagoButtonType.secondary:
        return _buildSecondaryButton();
      case JagoButtonType.outline:
        return _buildOutlineButton();
      case JagoButtonType.text:
        return _buildTextButton();
      case JagoButtonType.danger:
        return _buildDangerButton();
      case JagoButtonType.success:
        return _buildSuccessButton();
    }
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary600,
        foregroundColor: AppColors.textOnPrimary,
        disabledBackgroundColor: AppColors.secondary200,
        disabledForegroundColor: AppColors.secondary400,
        elevation: 0,
        minimumSize: Size(isFullWidth ? double.infinity : 0, _getHeight()),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusButton,
        ),
        textStyle: _getTextStyle(),
      ),
      child: _buildContent(AppColors.textOnPrimary),
    );
  }

  Widget _buildSecondaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary50,
        foregroundColor: AppColors.primary600,
        disabledBackgroundColor: AppColors.secondary100,
        disabledForegroundColor: AppColors.secondary400,
        elevation: 0,
        minimumSize: Size(isFullWidth ? double.infinity : 0, _getHeight()),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusButton,
        ),
        textStyle: _getTextStyle(),
      ),
      child: _buildContent(AppColors.primary600),
    );
  }

  Widget _buildOutlineButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary600,
        disabledForegroundColor: AppColors.secondary400,
        elevation: 0,
        minimumSize: Size(isFullWidth ? double.infinity : 0, _getHeight()),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusButton,
        ),
        side: BorderSide(
          color: onPressed != null ? AppColors.primary600 : AppColors.secondary300,
          width: 1.5,
        ),
        textStyle: _getTextStyle(),
      ),
      child: _buildContent(AppColors.primary600),
    );
  }

  Widget _buildTextButton() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary600,
        disabledForegroundColor: AppColors.secondary400,
        minimumSize: Size(isFullWidth ? double.infinity : 0, _getHeight()),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        textStyle: _getTextStyle(),
      ),
      child: _buildContent(AppColors.primary600),
    );
  }

  Widget _buildDangerButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.danger,
        foregroundColor: AppColors.textOnPrimary,
        disabledBackgroundColor: AppColors.secondary200,
        disabledForegroundColor: AppColors.secondary400,
        elevation: 0,
        minimumSize: Size(isFullWidth ? double.infinity : 0, _getHeight()),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusButton,
        ),
        textStyle: _getTextStyle(),
      ),
      child: _buildContent(AppColors.textOnPrimary),
    );
  }

  Widget _buildSuccessButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.textOnPrimary,
        disabledBackgroundColor: AppColors.secondary200,
        disabledForegroundColor: AppColors.secondary400,
        elevation: 0,
        minimumSize: Size(isFullWidth ? double.infinity : 0, _getHeight()),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusButton,
        ),
        textStyle: _getTextStyle(),
      ),
      child: _buildContent(AppColors.textOnPrimary),
    );
  }

  Widget _buildContent(Color iconColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == JagoButtonType.outline || type == JagoButtonType.text
                ? AppColors.primary600
                : AppColors.textOnPrimary,
          ),
        ),
      );
    }

    final children = <Widget>[];

    if (leadingIcon != null) {
      children.add(Icon(leadingIcon, size: _getIconSize(), color: iconColor));
      children.add(const SizedBox(width: 8));
    }

    children.add(Text(text));

    if (trailingIcon != null) {
      children.add(const SizedBox(width: 8));
      children.add(Icon(trailingIcon, size: _getIconSize(), color: iconColor));
    }

    return Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  double _getHeight() {
    switch (size) {
      case JagoButtonSize.small:
        return AppSpacing.buttonHeightSm;
      case JagoButtonSize.medium:
        return AppSpacing.buttonHeightMd;
      case JagoButtonSize.large:
        return AppSpacing.buttonHeightLg;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case JagoButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case JagoButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
      case JagoButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case JagoButtonSize.small:
        return AppTextStyles.buttonSmall;
      case JagoButtonSize.medium:
        return AppTextStyles.buttonMedium;
      case JagoButtonSize.large:
        return AppTextStyles.buttonLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case JagoButtonSize.small:
        return 16;
      case JagoButtonSize.medium:
        return 18;
      case JagoButtonSize.large:
        return 20;
    }
  }
}

/// Icon Button with consistent styling
class JagoIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final bool hasBorder;

  const JagoIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size / 2),
            border: hasBorder
                ? Border.all(color: AppColors.border, width: 1)
                : null,
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.textPrimary,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
