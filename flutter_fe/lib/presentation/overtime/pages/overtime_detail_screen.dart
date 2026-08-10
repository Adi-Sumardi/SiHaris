import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/components/widgets.dart';
import '../../../../data/models/responses/overtime_model.dart';
import '../bloc/action/overtime_action_bloc.dart';

class OvertimeDetailScreen extends StatelessWidget {
  final OvertimeModel overtime;

  const OvertimeDetailScreen({super.key, required this.overtime});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OvertimeActionBloc, OvertimeActionState>(
      listener: (context, state) {
        if (state is OvertimeActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true); // Return true to refresh list
        } else if (state is OvertimeActionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: const JagoAppBar(title: 'Detail Lembur'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(context),
              const SizedBox(height: 16),
              _buildDetailSection(context),
              if (overtime.status == 'pending') ...[
                const SizedBox(height: 32),
                BlocBuilder<OvertimeActionBloc, OvertimeActionState>(
                  builder: (context, state) {
                    return JagoButton(
                      text: 'Batalkan Pengajuan',
                      onPressed: state is OvertimeActionLoading
                          ? null
                          : () => _showCancelDialog(context),
                      type: JagoButtonType.danger,
                      isLoading: state is OvertimeActionLoading,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (overtime.status) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = AppColors.danger;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.access_time_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Pengajuan',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  overtime.statusLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Tanggal',
            DateFormat(
              'EEEE, d MMMM yyyy',
              'id_ID',
            ).format(DateTime.parse(overtime.date)),
            Icons.calendar_today_rounded,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Waktu',
            '${overtime.startTime.substring(0, 5)} - ${overtime.endTime.substring(0, 5)}',
            Icons.access_time_rounded,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Durasi',
            overtime.overtimeHours,
            Icons.timer_rounded,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Jenis Lembur',
            overtime.overtimeTypeLabel,
            Icons.category_rounded,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Estimasi Upah',
            overtime.formattedAmount,
            Icons.monetization_on_rounded,
            valueColor: AppColors.success,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Alasan',
            overtime.reason ?? '-',
            Icons.note_alt_rounded,
            isLongText: true,
          ),
          if (overtime.rejectionReason != null &&
              overtime.status == 'rejected') ...[
            const Divider(height: 24),
            _buildDetailRow(
              'Alasan Penolakan',
              overtime.rejectionReason!,
              Icons.warning_rounded,
              valueColor: AppColors.danger,
              isLongText: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool isLongText = false,
  }) {
    return Row(
      crossAxisAlignment: isLongText
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Lembur'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pengajuan lembur ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<OvertimeActionBloc>().add(
                CancelOvertime(overtime.id),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}
