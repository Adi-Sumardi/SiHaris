import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';

class AttendanceCalendar extends StatefulWidget {
  const AttendanceCalendar({super.key});

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;

  // Mock data for attendance
  final Map<DateTime, AttendanceStatus> _attendanceData = {
    DateTime(2026, 2, 1): AttendanceStatus.present,
    DateTime(2026, 2, 2): AttendanceStatus.weekend,
    DateTime(2026, 2, 3): AttendanceStatus.present,
    DateTime(2026, 2, 4): AttendanceStatus.present,
    DateTime(2026, 2, 5): AttendanceStatus.late,
    DateTime(2026, 2, 6): AttendanceStatus.present,
    DateTime(2026, 2, 7): AttendanceStatus.present,
    DateTime(2026, 2, 8): AttendanceStatus.weekend,
    DateTime(2026, 2, 9): AttendanceStatus.weekend,
    DateTime(2026, 2, 10): AttendanceStatus.present,
    DateTime(2026, 2, 11): AttendanceStatus.leave,
    DateTime(2026, 2, 12): AttendanceStatus.present,
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Calendar
          _buildCalendar(),
          const SizedBox(height: AppSpacing.lg),
          // Legend
          _buildLegend(),
          const SizedBox(height: AppSpacing.lg),
          // Selected date info
          _buildSelectedDateInfo(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                _getMonthYear(_focusedMonth),
                style: AppTextStyles.titleMedium,
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                .map((day) => SizedBox(
                      width: 40,
                      child: Text(
                        day,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Calendar grid
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final days = <Widget>[];

    // Empty cells for days before the first day
    for (var i = 0; i < firstWeekday; i++) {
      days.add(const SizedBox(width: 40, height: 40));
    }

    // Day cells
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final status = _attendanceData[date];
      final isSelected = _isSameDay(date, _selectedDate);
      final isToday = _isSameDay(date, DateTime.now());

      days.add(
        GestureDetector(
          onTap: () {
            setState(() => _selectedDate = date);
          },
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary600
                  : _getStatusColor(status)?.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primary600, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : (status != null
                          ? _getStatusColor(status)
                          : AppColors.textPrimary),
                  fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.start,
      children: days,
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusCard,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Hadir', AppColors.success),
          _buildLegendItem('Terlambat', AppColors.warning),
          _buildLegendItem('Cuti', AppColors.statusLeave),
          _buildLegendItem('Libur', AppColors.secondary400),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateInfo() {
    final status = _attendanceData[DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    )];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(_selectedDate),
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (status != null) ...[
            Row(
              children: [
                _buildInfoItem(
                  'Status',
                  _getStatusText(status),
                  _getStatusColor(status)!,
                ),
                const SizedBox(width: AppSpacing.lg),
                if (status == AttendanceStatus.present || status == AttendanceStatus.late)
                  _buildInfoItem('Clock In', '08:02', AppColors.success),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (status == AttendanceStatus.present || status == AttendanceStatus.late) ...[
                  _buildInfoItem('Clock Out', '17:15', AppColors.info),
                  const SizedBox(width: AppSpacing.lg),
                  _buildInfoItem('Jam Kerja', '8j 13m', AppColors.primary600),
                ],
              ],
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 40,
                      color: AppColors.secondary300,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tidak ada data',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Expanded(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthYear(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color? _getStatusColor(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.leave:
        return AppColors.statusLeave;
      case AttendanceStatus.absent:
        return AppColors.danger;
      case AttendanceStatus.weekend:
        return AppColors.secondary400;
      case AttendanceStatus.holiday:
        return AppColors.info;
      case null:
        return null;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Hadir';
      case AttendanceStatus.late:
        return 'Terlambat';
      case AttendanceStatus.leave:
        return 'Cuti';
      case AttendanceStatus.absent:
        return 'Tidak Hadir';
      case AttendanceStatus.weekend:
        return 'Libur Weekend';
      case AttendanceStatus.holiday:
        return 'Hari Libur';
    }
  }
}

enum AttendanceStatus {
  present,
  late,
  leave,
  absent,
  weekend,
  holiday,
}
