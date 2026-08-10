import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/spacing.dart';
import 'jago_button.dart';

/// Bottom sheet helper functions
class JagoBottomSheet {
  JagoBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => _BottomSheetContainer(
        title: title,
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }

  static Future<T?> showConfirmation<T>({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    bool isDanger = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show<T>(
      context: context,
      child: _ConfirmationContent(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDanger: isDanger,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  static Future<int?> showOptions({
    required BuildContext context,
    required String title,
    required List<String> options,
    List<IconData>? icons,
    int? selectedIndex,
  }) {
    return show<int>(
      context: context,
      title: title,
      child: _OptionsContent(
        options: options,
        icons: icons,
        selectedIndex: selectedIndex,
      ),
    );
  }

  static Future<DateTime?> showDateRangePicker({
    required BuildContext context,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return show<DateTime>(
      context: context,
      title: 'Pilih Tanggal',
      child: _DateRangeContent(
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  final String? title;
  final Widget child;
  final double? maxHeight;

  const _BottomSheetContainer({
    this.title,
    required this.child,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.secondary300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                title!,
                style: AppTextStyles.titleMedium,
              ),
            ),
            const Divider(height: 1),
          ],
          Flexible(child: child),
        ],
      ),
    );
  }
}

class _ConfirmationContent extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDanger;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _ConfirmationContent({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.isDanger,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDanger ? AppColors.dangerLight : AppColors.warningLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDanger ? Icons.delete_outline_rounded : Icons.help_outline_rounded,
              color: isDanger ? AppColors.danger : AppColors.warning,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: JagoButton(
                  text: cancelText,
                  type: JagoButtonType.outline,
                  onPressed: () {
                    Navigator.pop(context);
                    onCancel?.call();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: JagoButton(
                  text: confirmText,
                  type: isDanger ? JagoButtonType.danger : JagoButtonType.primary,
                  onPressed: () {
                    Navigator.pop(context, true);
                    onConfirm?.call();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _OptionsContent extends StatelessWidget {
  final List<String> options;
  final List<IconData>? icons;
  final int? selectedIndex;

  const _OptionsContent({
    required this.options,
    this.icons,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final isSelected = index == selectedIndex;
        return InkWell(
          onTap: () => Navigator.pop(context, index),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                if (icons != null && icons!.length > index) ...[
                  Icon(
                    icons![index],
                    color: isSelected ? AppColors.primary600 : AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Text(
                    options[index],
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary600 : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.primary600,
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DateRangeContent extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const _DateRangeContent({
    this.startDate,
    this.endDate,
  });

  @override
  State<_DateRangeContent> createState() => _DateRangeContentState();
}

class _DateRangeContentState extends State<_DateRangeContent> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate ?? DateTime.now();
    _endDate = widget.endDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _DateSelector(
                  label: 'Dari',
                  date: _startDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateSelector(
                  label: 'Sampai',
                  date: _endDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          JagoButton(
            text: 'Terapkan',
            onPressed: () => Navigator.pop(context, _startDate),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusInput,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: AppSpacing.borderRadiusInput,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
