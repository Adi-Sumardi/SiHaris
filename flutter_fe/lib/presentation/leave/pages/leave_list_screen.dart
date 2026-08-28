import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_list/leave_list_bloc.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_balance/leave_balance_bloc.dart';
import 'package:gaji_pro/presentation/leave/pages/leave_form_screen.dart';
import 'package:gaji_pro/presentation/leave/pages/leave_detail_screen.dart';
import 'package:gaji_pro/data/models/responses/leave_model.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/components/jago_header_band.dart';

class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({super.key});

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LeaveListBloc>().add(GetLeaveList());
    context.read<LeaveBalanceBloc>().add(GetLeaveBalance());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaveFormScreen()),
          );
          // Refresh list when coming back
          if (!mounted) return;
          if (context.mounted) {
            context.read<LeaveListBloc>().add(GetLeaveList());
            context.read<LeaveBalanceBloc>().add(GetLeaveBalance());
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeader(),
          const JagoHeaderBand(),
          Expanded(
            child: BlocBuilder<LeaveListBloc, LeaveListState>(
              builder: (context, state) {
                if (state is LeaveListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is LeaveListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            context.read<LeaveListBloc>().add(GetLeaveList());
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is LeaveListLoaded) {
                  if (state.leaves.isEmpty) {
                    return const Center(child: Text('Belum ada riwayat cuti'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.leaves.length,
                    itemBuilder: (context, index) {
                      return _buildLeaveItem(state.leaves[index]);
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Cuti & Izin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<LeaveBalanceBloc, LeaveBalanceState>(
              builder: (context, state) {
                if (state is LeaveBalanceLoaded) {
                  // Calculate totals from all balances
                  final totalEntitled = state.balances.fold(
                    0.0,
                    (sum, b) => sum + b.entitledDays,
                  );
                  final totalRemaining = state.balances.fold(
                    0.0,
                    (sum, b) => sum + b.remainingDays,
                  );
                  final totalUsed = state.balances.fold(
                    0.0,
                    (sum, b) => sum + b.usedDays,
                  );

                  return Row(
                    children: [
                      _buildBalanceCard(
                        'Jatah Cuti',
                        '${totalEntitled.toInt()}',
                        Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 12),
                      _buildBalanceCard(
                        'Sisa Cuti',
                        '${totalRemaining.toInt()}',
                        Colors.white.withValues(alpha: 0.2),
                        isHighlight: true,
                      ),
                      const SizedBox(width: 12),
                      _buildBalanceCard(
                        'Terpakai',
                        '${totalUsed.toInt()}',
                        Colors.white.withValues(alpha: 0.2),
                      ),
                    ],
                  );
                }
                return const SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    String title,
    String value,
    Color color, {
    bool isHighlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: isHighlight
              ? Border.all(color: Colors.white, width: 1)
              : null,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveItem(LeaveModel leave) {
    Color statusColor;
    switch (leave.status) {
      case 'approved':
        statusColor = AppColors.success;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeaveDetailScreen(leave: leave),
              ),
            );

            if (result == true && mounted) {
              context.read<LeaveListBloc>().add(GetLeaveList());
              context.read<LeaveBalanceBloc>().add(GetLeaveBalance());
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      leave.requestNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        leave.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.date_range,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.leaveType.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                            style: const TextStyle(
                              fontSize: 12,
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
                          '${leave.totalDays == leave.totalDays.toInt() ? leave.totalDays.toInt() : leave.totalDays} Hari',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  Text(
                    leave.reason!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM y', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
