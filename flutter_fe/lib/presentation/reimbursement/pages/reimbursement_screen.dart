import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/components/widgets.dart';
import '../../../data/models/responses/reimbursement_model.dart';
import '../bloc/reimbursement_list/reimbursement_list_bloc.dart';
import '../bloc/reimbursement_summary/reimbursement_summary_bloc.dart';
import 'reimbursement_form_screen.dart';

class ReimbursementScreen extends StatefulWidget {
  const ReimbursementScreen({super.key});

  @override
  State<ReimbursementScreen> createState() => _ReimbursementScreenState();
}

class _ReimbursementScreenState extends State<ReimbursementScreen> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final now = DateTime.now();
    context.read<ReimbursementSummaryBloc>().add(
      LoadReimbursementSummary(month: now.month, year: now.year),
    );
    context.read<ReimbursementListBloc>().add(
      LoadReimbursements(status: _selectedStatus),
    );
  }

  Future<void> _onRefresh() async {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const JagoAppBar(title: 'Reimbursement'),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'reimbursement_fab',
        onPressed: () async {
          final submitted = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ReimbursementFormScreen()),
          );
          if (submitted == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajukan'),
        backgroundColor: AppColors.primary600,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              BlocBuilder<ReimbursementSummaryBloc, ReimbursementSummaryState>(
                builder: (context, state) {
                  if (state is ReimbursementSummaryLoaded) {
                    final summary = state.summary;
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Total Diajukan',
                                _formatCurrency(summary.totalAmount),
                                Icons.receipt_long_outlined,
                                AppColors.primary600,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildSummaryCard(
                                'Pending',
                                _formatCurrency(summary.pendingAmount),
                                Icons.pending_outlined,
                                AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Disetujui',
                                _formatCurrency(summary.approvedAmount),
                                Icons.check_circle_outline,
                                AppColors.success,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildSummaryCard(
                                'Dibayar',
                                _formatCurrency(summary.paidAmount),
                                Icons.account_balance_wallet_outlined,
                                AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  return _buildSummaryLoading();
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              // Filter
              Row(
                children: [
                  Text('Riwayat Pengajuan', style: AppTextStyles.titleSmall),
                  const Spacer(),
                  _buildStatusFilter(),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // History
              BlocBuilder<ReimbursementListBloc, ReimbursementListState>(
                builder: (context, state) {
                  if (state is ReimbursementListLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (state is ReimbursementListError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.danger,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Gagal memuat data',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextButton(
                              onPressed: _loadData,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ReimbursementListLoaded) {
                    if (state.reimbursements.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Belum ada pengajuan',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: state.reimbursements
                          .map((item) => _buildHistoryCard(item))
                          .toList(),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryLoading() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCardSkeleton()),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildSummaryCardSkeleton()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildSummaryCardSkeleton()),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildSummaryCardSkeleton()),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCardSkeleton() {
    return JagoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return PopupMenuButton<String?>(
      initialValue: _selectedStatus,
      onSelected: (value) {
        setState(() {
          _selectedStatus = value;
        });
        context.read<ReimbursementListBloc>().add(
          LoadReimbursements(status: value),
        );
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('Semua Status')),
        const PopupMenuItem(value: 'pending', child: Text('Pending')),
        const PopupMenuItem(value: 'approved', child: Text('Disetujui')),
        const PopupMenuItem(value: 'rejected', child: Text('Ditolak')),
        const PopupMenuItem(value: 'paid', child: Text('Dibayar')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedStatus == null
                  ? 'Filter'
                  : _getStatusLabel(_selectedStatus!),
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'paid':
        return 'Dibayar';
      default:
        return status;
    }
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return JagoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(ReimbursementModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.category, style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(item.description, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow('Tanggal Pengeluaran', _formatDate(item.expenseDate)),
            _buildDetailRow('Nominal', item.formattedAmount),
            _buildDetailRow('Status', item.statusLabel),
            if (item.approvedBy != null)
              _buildDetailRow('Disetujui Oleh', item.approvedBy!),
            if (item.rejectionReason != null)
              _buildDetailRow('Alasan Ditolak', item.rejectionReason!),
            if (item.paymentMethod != null)
              _buildDetailRow('Metode Pembayaran', item.paymentMethod!),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ReimbursementModel item) {
    final status = item.status;
    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        break;
      case 'rejected':
        statusColor = AppColors.danger;
        break;
      case 'paid':
        statusColor = AppColors.info;
        break;
      default:
        statusColor = AppColors.warning;
    }

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
      child: InkWell(
        onTap: () => _showDetailSheet(item),
        borderRadius: AppSpacing.borderRadiusCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary600.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    item.category,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.statusLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              item.description,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(item.expenseDate),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  item.formattedAmount,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('d MMM yyyy', 'id_ID');
      return formatter.format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
