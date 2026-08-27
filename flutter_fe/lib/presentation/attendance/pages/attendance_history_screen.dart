import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gaji_pro/data/models/responses/attendance_history_model.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_history/attendance_history_bloc.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_summary/attendance_summary_bloc.dart';
import 'package:gaji_pro/presentation/attendance/pages/attendance_detail_screen.dart';
import 'package:gaji_pro/presentation/home/pages/main_screen.dart';
import '../../../core/constants/colors.dart';

/// Attendance History Screen with 8-point grid system
/// Spacing: 4, 8, 12, 16, 24, 32 px
/// Font sizes: 10, 11, 12, 14, 16, 20 px
/// Icon sizes: 14, 16, 20, 24 px
/// Container sizes: 40, 44, 48 px
/// Border radius: 4, 8, 12, 16 px
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Hadir',
    'Terlambat',
    'Cuti',
    'Tidak Hadir',
  ];

  @override
  Widget build(BuildContext context) {
    // Load data when screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceHistoryBloc>().add(const GetAttendanceHistory());
      context.read<AttendanceSummaryBloc>().add(
        GetAttendanceSummary(
          month: DateTime.now().month,
          year: DateTime.now().year,
        ),
      );
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          // Header with gradient
          _buildHeader(),
          // Filter chips
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary600
                              : AppColors.secondary50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // History list
          Expanded(
            child: BlocBuilder<AttendanceHistoryBloc, AttendanceHistoryState>(
              builder: (context, state) {
                if (state is AttendanceHistoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AttendanceHistoryError) {
                  return Center(child: Text(state.message));
                }
                if (state is AttendanceHistoryLoaded) {
                  final data = state.data;
                  if (data.isEmpty) {
                    return const Center(child: Text('Belum ada riwayat'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return _buildHistoryItem(item);
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary600, AppColors.primary700],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                        );
                      }
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Riwayat Kehadiran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.calendar_month_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Summary cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: BlocBuilder<AttendanceSummaryBloc, AttendanceSummaryState>(
                builder: (context, state) {
                  if (state is AttendanceSummaryLoaded) {
                    final summary = state.data;
                    return Row(
                      children: [
                        _buildSummaryCard(
                          '${summary.totalWorkingDays}',
                          'Total',
                          Colors.white,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryCard(
                          '${summary.present}',
                          'Hadir',
                          AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryCard(
                          '${summary.late}',
                          'Terlambat',
                          AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        _buildSummaryCard(
                          '${summary.leave}',
                          'Cuti',
                          AppColors.statusLeave,
                        ),
                      ],
                    );
                  }
                  if (state is AttendanceSummaryError) {
                    return Center(
                      child: Text(
                        'Gagal memuat ringkasan',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  if (state is AttendanceSummaryLoading) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  return const SizedBox(height: 60); // Placeholder height (Initial)
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String value, String label, Color color) {
    final isWhite = color == Colors.white;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isWhite ? Colors.white.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isWhite ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isWhite
                    ? Colors.white.withValues(alpha: 0.8)
                    : color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(AttendanceHistoryModel item) {
    final date = DateTime.tryParse(item.date) ?? DateTime.now();
    final day = DateFormat('d').format(date);
    final month = DateFormat('MMM', 'id_ID').format(date);
    final dayName = DateFormat('EEEE', 'id_ID').format(date);

    Color color;
    switch (item.status.toLowerCase()) {
      case 'present':
        color = AppColors.success;
        break;
      case 'late':
        color = AppColors.warning;
        break;
      case 'leave':
        color = AppColors.statusLeave;
        break;
      case 'absent':
        color = AppColors.danger;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceDetailScreen(attendance: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row: Date Pill, Day Name, Status Badge, and Navigation Chevron
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        month,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  dayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textTertiary,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            // Bottom Row: Clock In, Clock Out, and Work Hours
            Row(
              children: [
                // Masuk
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.login_rounded,
                          size: 13,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              item.clockIn ?? '--:--',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: item.clockIn != null
                                    ? AppColors.textPrimary
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Pulang
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          size: 13,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pulang',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              item.clockOut ?? '--:--',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: item.clockOut != null
                                    ? AppColors.textPrimary
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Jam Kerja Badge
                if (item.workingFormatted != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary600.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.primary600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.workingFormatted!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary600,
                          ),
                        ),
                      ],
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
