import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/spacing.dart';

/// Text input field with JagoGaji styling
class JagoTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helper;
  final String? error;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final bool showCounter;
  final AutovalidateMode? autovalidateMode;
  final FormFieldValidator<String>? validator;

  const JagoTextField({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.onSuffixTap,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.showCounter = false,
    this.autovalidateMode,
    this.validator,
  });

  @override
  State<JagoTextField> createState() => _JagoTextFieldState();
}

class _JagoTextFieldState extends State<JagoTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          inputFormatters: widget.inputFormatters,
          autovalidateMode: widget.autovalidateMode,
          validator: widget.validator,
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.enabled ? AppColors.textPrimary : AppColors.textTertiary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: widget.showCounter ? null : '',
            filled: true,
            fillColor: widget.enabled ? AppColors.surface : AppColors.secondary50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused ? AppColors.primary500 : AppColors.textTertiary,
                    size: 20,
                  )
                : widget.prefix,
            suffixIcon: _buildSuffix(),
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusInput,
              borderSide: BorderSide(
                color: widget.error != null ? AppColors.danger : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusInput,
              borderSide: BorderSide(
                color: widget.error != null ? AppColors.danger : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusInput,
              borderSide: BorderSide(
                color: widget.error != null ? AppColors.danger : AppColors.primary500,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusInput,
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusInput,
              borderSide: const BorderSide(color: AppColors.danger, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusInput,
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
          ),
        ),
        if (widget.error != null || widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.error ?? widget.helper!,
            style: AppTextStyles.bodySmall.copyWith(
              color: widget.error != null ? AppColors.danger : AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffix() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textTertiary,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    if (widget.suffix != null) return widget.suffix;

    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: AppColors.textTertiary,
          size: 20,
        ),
        onPressed: widget.onSuffixTap,
      );
    }

    return null;
  }
}

/// Search input field
class JagoSearchField extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  const JagoSearchField({
    super.key,
    this.hint = 'Cari...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.secondary50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textTertiary,
          size: 20,
        ),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.primary500, width: 2),
        ),
      ),
    );
  }
}

/// Dropdown field
class JagoDropdownField<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? error;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final IconData? prefixIcon;

  const JagoDropdownField({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          hint: hint != null
              ? Text(
                  hint!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                )
              : null,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textTertiary,
          ),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.secondary50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textTertiary, size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusInput,
              borderSide: BorderSide(
                color: error != null ? AppColors.danger : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusInput,
              borderSide: BorderSide(
                color: error != null ? AppColors.danger : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusInput,
              borderSide: BorderSide(
                color: error != null ? AppColors.danger : AppColors.primary500,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadiusInput,
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

/// Date picker field
class JagoDateField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? error;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onChanged;
  final bool enabled;

  const JagoDateField({
    super.key,
    this.label,
    this.hint = 'Pilih tanggal',
    this.error,
    this.value,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return JagoTextField(
      label: label,
      hint: hint,
      error: error,
      readOnly: true,
      enabled: enabled,
      controller: TextEditingController(
        text: value != null ? _formatDate(value!) : '',
      ),
      prefixIcon: Icons.calendar_today_outlined,
      suffixIcon: Icons.keyboard_arrow_down_rounded,
      onTap: enabled
          ? () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: firstDate ?? DateTime(2020),
                lastDate: lastDate ?? DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary600,
                        onPrimary: AppColors.textOnPrimary,
                        surface: AppColors.surface,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                onChanged?.call(date);
              }
            }
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
