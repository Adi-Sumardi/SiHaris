import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../constants/spacing.dart';
import 'jago_button.dart';

/// Empty state widget for lists and pages
class JagoEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;

  const JagoEmptyState({
    super.key,
    required this.title,
    this.message,
    required this.icon,
    this.actionText,
    this.onAction,
    this.iconColor,
  });

  factory JagoEmptyState.noData({
    String title = 'Tidak Ada Data',
    String? message = 'Data yang Anda cari tidak ditemukan',
    String? actionText,
    VoidCallback? onAction,
  }) {
    return JagoEmptyState(
      title: title,
      message: message,
      icon: Icons.inbox_outlined,
      actionText: actionText,
      onAction: onAction,
    );
  }

  factory JagoEmptyState.noConnection({
    VoidCallback? onRetry,
  }) {
    return JagoEmptyState(
      title: 'Tidak Ada Koneksi',
      message: 'Periksa koneksi internet Anda dan coba lagi',
      icon: Icons.wifi_off_rounded,
      iconColor: AppColors.warning,
      actionText: 'Coba Lagi',
      onAction: onRetry,
    );
  }

  factory JagoEmptyState.error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return JagoEmptyState(
      title: 'Terjadi Kesalahan',
      message: message ?? 'Silakan coba lagi nanti',
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.danger,
      actionText: 'Coba Lagi',
      onAction: onRetry,
    );
  }

  factory JagoEmptyState.noHistory() {
    return const JagoEmptyState(
      title: 'Belum Ada Riwayat',
      message: 'Riwayat aktivitas akan muncul di sini',
      icon: Icons.history_rounded,
    );
  }

  factory JagoEmptyState.noNotification() {
    return const JagoEmptyState(
      title: 'Tidak Ada Notifikasi',
      message: 'Notifikasi baru akan muncul di sini',
      icon: Icons.notifications_none_rounded,
    );
  }

  factory JagoEmptyState.searchNotFound({String? query}) {
    return JagoEmptyState(
      title: 'Tidak Ditemukan',
      message: query != null
          ? 'Hasil pencarian untuk "$query" tidak ditemukan'
          : 'Hasil pencarian tidak ditemukan',
      icon: Icons.search_off_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.secondary400).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: iconColor ?? AppColors.secondary400,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              JagoButton(
                text: actionText!,
                onPressed: onAction,
                isFullWidth: false,
                size: JagoButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading state widget
class JagoLoadingState extends StatelessWidget {
  final String? message;

  const JagoLoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary600,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder
class JagoShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const JagoShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  State<JagoShimmer> createState() => _JagoShimmerState();
}

class _JagoShimmerState extends State<JagoShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                AppColors.secondary100,
                AppColors.secondary50,
                AppColors.secondary100,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Card shimmer placeholder
class JagoCardShimmer extends StatelessWidget {
  const JagoCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const JagoShimmer(width: 48, height: 48, borderRadius: 8),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JagoShimmer(height: 14, width: MediaQuery.of(context).size.width * 0.4),
                    const SizedBox(height: 8),
                    JagoShimmer(height: 12, width: MediaQuery.of(context).size.width * 0.6),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
