import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/components/widgets.dart';
import '../../../data/models/responses/leave_balance_model.dart';
import '../../../data/models/responses/leave_model.dart';
import '../bloc/leave_balance/leave_balance_bloc.dart';
import '../bloc/leave_list/leave_list_bloc.dart';

/// Leave Screen with 8-point grid system
/// Spacing: 4, 8, 12, 16, 24, 32 px
/// Font sizes: 10, 12, 14, 16, 20, 24, 48 px
/// Icon sizes: 16, 20, 24 px
/// Container sizes: 40, 48 px
/// Border radius: 4, 8, 12, 16 px
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    context.read<LeaveBalanceBloc>().add(GetLeaveBalance());
    context.read<LeaveListBloc>().add(GetLeaveList());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cuti',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Saldo'),
            Tab(text: 'Riwayat'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'leave_fab',
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/leave/request');
          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('Ajukan Cuti'),
        backgroundColor: AppColors.primary600,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildBalanceTab(), _buildHistoryTab(), _buildPendingTab()],
      ),
    );
  }

  Widget _buildBalanceTab() {
    return BlocBuilder<LeaveBalanceBloc, LeaveBalanceState>(
      builder: (context, state) {
        if (state is LeaveBalanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is LeaveBalanceError) {
          return JagoEmptyState(
            title: 'Gagal Memuat Data',
            message: state.message,
            icon: Icons.error_outline_rounded,
            actionText: 'Coba Lagi',
            onAction: _loadData,
          );
        }

        if (state is LeaveBalanceLoaded) {
          final balances = state.balances;
          if (balances.isEmpty) {
            return const JagoEmptyState(
              title: 'Tidak Ada Data Saldo',
              message: 'Data saldo cuti belum tersedia',
              icon: Icons.event_busy_outlined,
            );
          }

          // Calculate total remaining
          final totalRemaining = balances.fold<double>(
            0,
            (sum, b) => sum + b.remainingDays,
          );
          final totalUsed = balances.fold<double>(
            0,
            (sum, b) => sum + b.usedDays,
          );
          final totalEntitled = balances.fold<double>(
            0,
            (sum, b) => sum + b.entitledDays,
          );

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total balance card
                  JagoGradientCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Sisa Cuti',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textOnDark.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              totalRemaining.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textOnDark,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8, left: 8),
                              child: Text(
                                'Hari',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      AppColors.textOnDark.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildBalanceInfo(
                              'Terpakai',
                              totalUsed.toStringAsFixed(0),
                              AppColors.textOnDark,
                            ),
                            const SizedBox(width: 32),
                            _buildBalanceInfo(
                              'Total Tahun Ini',
                              totalEntitled.toStringAsFixed(0),
                              AppColors.textOnDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Balance by type
                  const Text(
                    'Saldo per Jenis Cuti',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...balances.map((balance) => _buildBalanceCard(balance)),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBalanceInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 4),
        Text(
          '$value Hari',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(LeaveBalanceModel balance) {
    final used = balance.usedDays;
    final total = balance.entitledDays;
    final remaining = balance.remainingDays;
    final progress = total > 0 ? used / total : 0.0;

    // Assign color based on leave type name
    Color typeColor = _getLeaveTypeColor(balance.leaveTypeName);
    IconData typeIcon = _getLeaveTypeIcon(balance.leaveTypeName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balance.leaveTypeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sisa ${remaining.toStringAsFixed(0)} dari ${total.toStringAsFixed(0)} hari',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                remaining.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.secondary100,
              valueColor: AlwaysStoppedAnimation<Color>(typeColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLeaveTypeColor(String typeName) {
    final lowerName = typeName.toLowerCase();
    if (lowerName.contains('tahunan')) return AppColors.accent500;
    if (lowerName.contains('sakit')) return AppColors.info;
    if (lowerName.contains('penting')) return AppColors.danger;
    if (lowerName.contains('melahirkan')) return AppColors.success;
    if (lowerName.contains('haji') || lowerName.contains('umroh')) {
      return AppColors.warning;
    }
    return AppColors.primary600;
  }

  IconData _getLeaveTypeIcon(String typeName) {
    final lowerName = typeName.toLowerCase();
    if (lowerName.contains('tahunan')) return Icons.beach_access_outlined;
    if (lowerName.contains('sakit')) return Icons.local_hospital_outlined;
    if (lowerName.contains('penting')) return Icons.priority_high_rounded;
    if (lowerName.contains('melahirkan')) return Icons.child_friendly_outlined;
    if (lowerName.contains('haji') || lowerName.contains('umroh')) {
      return Icons.mosque_outlined;
    }
    return Icons.event_available_outlined;
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<LeaveListBloc, LeaveListState>(
      builder: (context, state) {
        if (state is LeaveListLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is LeaveListError) {
          return JagoEmptyState(
            title: 'Gagal Memuat Data',
            message: state.message,
            icon: Icons.error_outline_rounded,
            actionText: 'Coba Lagi',
            onAction: _loadData,
          );
        }

        if (state is LeaveListLoaded) {
          final leaves = state.leaves;
          if (leaves.isEmpty) {
            return const JagoEmptyState(
              title: 'Tidak Ada Riwayat',
              message: 'Belum ada pengajuan cuti',
              icon: Icons.history_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: leaves.length,
              itemBuilder: (context, index) {
                final item = leaves[index];
                return _buildHistoryCard(item);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHistoryCard(LeaveModel item) {
    final status = item.status;
    Color statusColor;
    String statusLabel = item.statusLabel;

    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        break;
      case 'rejected':
        statusColor = AppColors.danger;
        break;
      case 'cancelled':
        statusColor = AppColors.secondary500;
        break;
      default:
        statusColor = AppColors.warning;
    }

    final typeColor = _getLeaveTypeColor(item.leaveType.name);
    final dateFormat = DateFormat('d MMM yyyy', 'id_ID');
    String dateText;

    try {
      final startDate = DateTime.parse(item.startDate);
      final endDate = DateTime.parse(item.endDate);

      if (startDate == endDate) {
        dateText = dateFormat.format(startDate);
      } else {
        dateText =
            '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
      }
    } catch (e) {
      dateText = '${item.startDate} - ${item.endDate}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.leaveType.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                '${item.totalDays.toStringAsFixed(0)} Hari',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 24),
              const Icon(
                Icons.note_outlined,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.reason ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return BlocBuilder<LeaveListBloc, LeaveListState>(
      builder: (context, state) {
        if (state is LeaveListLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is LeaveListError) {
          return JagoEmptyState(
            title: 'Gagal Memuat Data',
            message: state.message,
            icon: Icons.error_outline_rounded,
            actionText: 'Coba Lagi',
            onAction: _loadData,
          );
        }

        if (state is LeaveListLoaded) {
          final pendingItems =
              state.leaves.where((item) => item.status == 'pending').toList();

          if (pendingItems.isEmpty) {
            return const JagoEmptyState(
              title: 'Tidak Ada Pengajuan Pending',
              message: 'Semua pengajuan cuti Anda sudah diproses',
              icon: Icons.check_circle_outline_rounded,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: pendingItems.length,
              itemBuilder: (context, index) {
                return _buildHistoryCard(pendingItems[index]);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
