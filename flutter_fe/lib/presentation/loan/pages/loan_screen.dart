import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/components/widgets.dart';

class LoanScreen extends StatelessWidget {
  const LoanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const JagoAppBar(title: 'Pinjaman'),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'loan_fab',
        onPressed: () {
          // Show loan request form
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajukan Pinjaman'),
        backgroundColor: AppColors.primary600,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active loan card
            _buildActiveLoanCard(),
            const SizedBox(height: AppSpacing.lg),
            // Payment schedule
            Text('Jadwal Cicilan', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.md),
            _buildPaymentSchedule(),
            const SizedBox(height: AppSpacing.lg),
            // Loan history
            Text('Riwayat Pinjaman', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.md),
            _buildLoanHistoryCard(
              'Pinjaman Darurat',
              '3.000.000',
              '10 Jan 2025',
              'Lunas',
              AppColors.success,
            ),
            _buildLoanHistoryCard(
              'Pinjaman Pendidikan',
              '5.000.000',
              '15 Jun 2024',
              'Lunas',
              AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveLoanCard() {
    return JagoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Aktif',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Pinjaman #LN2026001',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Sisa Pinjaman',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp 2.200.000',
                style: AppTextStyles.amountLarge.copyWith(
                  color: AppColors.primary600,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 8),
                child: Text(
                  'dari Rp 5.000.000',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.56,
              backgroundColor: AppColors.secondary100,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary600,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '56% Terbayar',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '5/9 Cicilan',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cicilan per Bulan',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      'Rp 550.000',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cicilan Berikutnya',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      '1 Mar 2026',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tenor',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      '9 Bulan',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSchedule() {
    final schedules = [
      {'month': 'Feb 2026', 'amount': '550.000', 'status': 'paid'},
      {'month': 'Mar 2026', 'amount': '550.000', 'status': 'upcoming'},
      {'month': 'Apr 2026', 'amount': '550.000', 'status': 'pending'},
      {'month': 'Mei 2026', 'amount': '550.000', 'status': 'pending'},
    ];

    return JagoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: schedules.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isPaid = item['status'] == 'paid';
          final isUpcoming = item['status'] == 'upcoming';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppColors.success
                            : (isUpcoming
                                  ? AppColors.warning
                                  : AppColors.secondary200),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPaid
                            ? Icons.check_rounded
                            : (isUpcoming
                                  ? Icons.schedule_rounded
                                  : Icons.circle_outlined),
                        color: isPaid || isUpcoming
                            ? AppColors.textOnPrimary
                            : AppColors.textTertiary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cicilan ke-${5 + index}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            item['month']!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rp ${item['amount']}',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? AppColors.successLight
                                : (isUpcoming
                                      ? AppColors.warningLight
                                      : AppColors.secondary100),
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Text(
                            isPaid
                                ? 'Lunas'
                                : (isUpcoming ? 'Mendatang' : 'Belum'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isPaid
                                  ? AppColors.success
                                  : (isUpcoming
                                        ? AppColors.warning
                                        : AppColors.textTertiary),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (index < schedules.length - 1)
                const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoanHistoryCard(
    String title,
    String amount,
    String date,
    String status,
    Color statusColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp $amount',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Text(
                  status,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
