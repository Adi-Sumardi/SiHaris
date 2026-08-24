import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/components/widgets.dart';
import '../../../../data/models/responses/leave_model.dart';
import '../bloc/leave_crud/leave_crud_bloc.dart';

class LeaveDetailScreen extends StatelessWidget {
  final LeaveModel leave;

  const LeaveDetailScreen({super.key, required this.leave});

  /// Mirrors the backend's `LeaveRequest::canBeCancelled()`: pending, or
  /// approved but not yet started.
  bool get _canCancel {
    if (leave.status == 'pending') return true;
    if (leave.status != 'approved') return false;
    final startDate = DateTime.tryParse(leave.startDate);
    return startDate != null && startDate.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaveCrudBloc, LeaveCrudState>(
      listener: (context, state) {
        if (state is LeaveCrudSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true); // Return true to refresh list
        } else if (state is LeaveCrudFailure) {
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
        appBar: const JagoAppBar(title: 'Detail Cuti'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(context),
              const SizedBox(height: 16),
              _buildDetailSection(context),
              if (_canCancel) ...[
                const SizedBox(height: 32),
                BlocBuilder<LeaveCrudBloc, LeaveCrudState>(
                  builder: (context, state) {
                    return JagoButton(
                      text: 'Batalkan Pengajuan',
                      onPressed: state is LeaveCrudLoading
                          ? null
                          : () => _showCancelDialog(context),
                      type: JagoButtonType.danger,
                      isLoading: state is LeaveCrudLoading,
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

    switch (leave.status) {
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
                  leave.statusLabel,
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
            'Nomor Pengajuan',
            leave.requestNumber,
            Icons.receipt_long_rounded,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Jenis Cuti',
            leave.leaveType.name,
            Icons.category_rounded,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Tanggal Mulai',
            DateFormat(
              'EEEE, d MMMM yyyy',
              'id_ID',
            ).format(DateTime.parse(leave.startDate)),
            Icons.calendar_today_rounded,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Tanggal Selesai',
            DateFormat(
              'EEEE, d MMMM yyyy',
              'id_ID',
            ).format(DateTime.parse(leave.endDate)),
            Icons.event_busy_rounded,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Durasi',
            '${leave.totalDays} Hari',
            Icons.timer_rounded,
          ),
          if (leave.isHalfDay) ...[
            const Divider(height: 24),
            _buildDetailRow(
              'Tipe Setengah Hari',
              leave.halfDayType ?? '-',
              Icons.hourglass_bottom_rounded,
            ),
          ],
          const Divider(height: 24),
          _buildDetailRow(
            'Alasan',
            leave.reason ?? '-',
            Icons.note_alt_rounded,
            isLongText: true,
          ),
          if (leave.attachment != null) ...[
            const Divider(height: 24),
            _buildDetailRow(
              'Lampiran',
              'Lihat Lampiran', // Placeholder, implement view/download later
              Icons.attach_file_rounded,
              valueColor: AppColors.primary,
            ),
          ],
          if (leave.rejectionReason != null && leave.status == 'rejected') ...[
            const Divider(height: 24),
            _buildDetailRow(
              'Alasan Penolakan',
              leave.rejectionReason!,
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
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Cuti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Apakah Anda yakin ingin membatalkan pengajuan cuti ini?',
            ),
            const SizedBox(height: 16),
            JagoTextField(
              label: 'Alasan Pembatalan (Opsional)',
              controller: reasonController,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<LeaveCrudBloc>().add(
                CancelLeave(leave.id, reasonController.text),
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
