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
    final month = DateFormat('MMM').format(date);
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
        children: [
          // Date container - 44px
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (item.clockIn != null)
                  Row(
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.clockIn!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.logout_rounded,
                        size: 12,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.clockOut ?? '--:--',
                        style: TextStyle(
                          fontSize: 12,
                          color: item.clockOut != null
                              ? AppColors.info
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    '-', // Notes not in model
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          // Work hours
          if (item.workingFormatted != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    item.workingFormatted!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary600,
                    ),
                  ),
                  const Text(
                    'Jam Kerja',
                    style: TextStyle(fontSize: 9, color: AppColors.primary400),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
        ],
      ),
    ),
    );
  }
}
