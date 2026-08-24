import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../data/models/responses/attendance_history_model.dart';
import '../bloc/attendance_history/attendance_history_bloc.dart';

class AttendanceCalendar extends StatefulWidget {
  const AttendanceCalendar({super.key});

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedMonth = DateTime.now();
    _loadMonth(_focusedMonth);
  }

  void _loadMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    context.read<AttendanceHistoryBloc>().add(
      GetAttendanceHistory(
        startDate: _isoDate(firstDay),
        endDate: _isoDate(lastDay),
      ),
    );
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceHistoryBloc, AttendanceHistoryState>(
      builder: (context, state) {
        final records = <DateTime, AttendanceHistoryModel>{};
        if (state is AttendanceHistoryLoaded) {
          for (final record in state.data) {
            final date = DateTime.tryParse(record.date);
            if (date != null) {
              records[DateTime(date.year, date.month, date.day)] = record;
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _buildCalendar(records, isLoading: state is AttendanceHistoryLoading),
              const SizedBox(height: AppSpacing.lg),
              _buildLegend(),
              const SizedBox(height: AppSpacing.lg),
              _buildSelectedDateInfo(records[DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              )]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendar(
    Map<DateTime, AttendanceHistoryModel> records, {
    required bool isLoading,
  }) {
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
                  _loadMonth(_focusedMonth);
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getMonthYear(_focusedMonth),
                    style: AppTextStyles.titleMedium,
                  ),
                  if (isLoading) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    );
                  });
                  _loadMonth(_focusedMonth);
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
          _buildCalendarGrid(records),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, AttendanceHistoryModel> records) {
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
      final status = _statusFor(records[date]);
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

  Widget _buildSelectedDateInfo(AttendanceHistoryModel? record) {
    final status = _statusFor(record);

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
          if (status != null && record != null) ...[
            Row(
              children: [
                _buildInfoItem(
                  'Status',
                  _getStatusText(status),
                  _getStatusColor(status)!,
                ),
                const SizedBox(width: AppSpacing.lg),
                if (record.clockIn != null)
                  _buildInfoItem('Clock In', record.clockIn!, AppColors.success),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (record.clockOut != null) ...[
                  _buildInfoItem('Clock Out', record.clockOut!, AppColors.info),
                  const SizedBox(width: AppSpacing.lg),
                ],
                if (record.workingFormatted != null)
                  _buildInfoItem(
                    'Jam Kerja',
                    record.workingFormatted!,
                    AppColors.primary600,
                  ),
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

  /// Maps the backend's `status` string (see Attendance::getStatusLabelAttribute)
  /// to the local display enum. 'half_day' falls back to [AttendanceStatus.present]
  /// since there's no dedicated legend/color for it.
  AttendanceStatus? _statusFor(AttendanceHistoryModel? record) {
    switch (record?.status) {
      case 'present':
        return AttendanceStatus.present;
      case 'late':
        return AttendanceStatus.late;
      case 'leave':
        return AttendanceStatus.leave;
      case 'absent':
        return AttendanceStatus.absent;
      case 'weekend':
        return AttendanceStatus.weekend;
      case 'holiday':
        return AttendanceStatus.holiday;
      case 'half_day':
        return AttendanceStatus.present;
      default:
        return null;
    }
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
