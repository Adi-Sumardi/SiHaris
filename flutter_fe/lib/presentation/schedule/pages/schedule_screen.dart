import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/components/widgets.dart';
import '../../../core/components/jago_header_band.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/responses/employee_schedule_model.dart';
import '../bloc/schedule/schedule_bloc.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String? _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateFormat('yyyy-MM').format(now);
    context.read<ScheduleBloc>().add(LoadSchedule(month: _currentMonth));
  }

  void _loadMonth(String month) {
    setState(() => _currentMonth = month);
    context.read<ScheduleBloc>().add(LoadSchedule(month: month));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          _buildHeader(context),
          const JagoHeaderBand(),
          Expanded(
            child: BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, state) {
                if (state is ScheduleLoading || state is ScheduleInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ScheduleError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: AppColors.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadMonth(_currentMonth ?? ''),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is ScheduleLoaded) {
                  return _buildContent(state.data);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
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
                  'Jadwal Shift',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(EmployeeScheduleResponse data) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Collect unique shift names for the legend
    final uniqueShifts = <String>{};
    for (final day in data.days) {
      if (day.schedule != null) {
        uniqueShifts.add(day.schedule!.name);
      }
    }

    return RefreshIndicator(
      onRefresh: () async => _loadMonth(_currentMonth ?? ''),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMonthNavigator(data),
          const SizedBox(height: 12),
          if (uniqueShifts.length > 1) ...[
            _buildShiftLegend(uniqueShifts.toList()),
            const SizedBox(height: 12),
          ],
          _buildWeeklySummary(data),
          const SizedBox(height: 12),
          ...data.days.map((day) => _buildDayCard(day, day.date == today)),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator(EmployeeScheduleResponse data) {
    return JagoCard(
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => _loadMonth(data.prevMonth),
          ),
          Expanded(
            child: Center(
              child: Text(
                data.monthLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _loadMonth(data.nextMonth),
          ),
        ],
      ),
    );
  }

  /// Shift legend showing color coding for each shift type
  Widget _buildShiftLegend(List<String> shiftNames) {
    return JagoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keterangan Shift',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final name in shiftNames)
                _buildLegendItem(name, _getShiftColor(name)),
              _buildLegendItem('Libur', AppColors.danger),
              _buildLegendItem('Hari Libur', AppColors.textTertiary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// Weekly summary: compact row showing Mon-Sun shift assignments
  Widget _buildWeeklySummary(EmployeeScheduleResponse data) {
    // Find the current week's days from the data
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // Find the Monday of the current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final weekDays = <String>['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final dayMap = {for (final d in data.days) d.date: d};

    return JagoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jadwal Minggu Ini',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (i) {
              final date = monday.add(Duration(days: i));
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final day = dayMap[dateStr];
              final isToday = dateStr == todayStr;

              Color bgColor;
              String shortLabel;

              if (day == null) {
                // Date is outside the loaded month
                bgColor = AppColors.secondary100;
                shortLabel = '-';
              } else if (day.isHoliday) {
                bgColor = AppColors.dangerLight;
                shortLabel = 'L';
              } else if (day.schedule != null) {
                bgColor = _getShiftColor(
                  day.schedule!.name,
                ).withValues(alpha: 0.15);
                shortLabel = _getShiftAbbreviation(day.schedule!.name);
              } else {
                bgColor = AppColors.secondary100;
                shortLabel = '-';
              }

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
                  child: Column(
                    children: [
                      Text(
                        weekDays[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isToday
                              ? AppColors.primary600
                              : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday
                              ? Border.all(
                                  color: AppColors.primary600,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            shortLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: day?.isHoliday == true
                                  ? AppColors.danger
                                  : day?.schedule != null
                                  ? _getShiftColor(day!.schedule!.name)
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(EmployeeScheduleDay day, bool isToday) {
    final date = DateTime.parse(day.date);
    final dayOfMonth = DateFormat('d').format(date);

    Color bgColor = AppColors.surface;
    Color accentColor = AppColors.textSecondary;
    String statusLabel;

    if (day.isHoliday) {
      accentColor = AppColors.danger;
      statusLabel = day.holidayName ?? 'Libur';
    } else if (day.isWorkingDay && day.schedule != null) {
      accentColor = _getShiftColor(day.schedule!.name);
      statusLabel = day.schedule!.name;
    } else {
      statusLabel = 'Hari Libur';
    }

    if (isToday) {
      bgColor = AppColors.primary50;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: JagoCard(
        backgroundColor: bgColor,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  dayOfMonth,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        day.dayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Hari Ini',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (day.schedule?.isOvernight == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.overtime.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.nightlight_round,
                                size: 10,
                                color: AppColors.overtime,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '+1',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.overtime,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel,
                    style: TextStyle(fontSize: 12, color: accentColor),
                  ),
                ],
              ),
            ),
            if (day.schedule != null && day.isWorkingDay)
              Text(
                '${day.schedule!.startTime} - ${day.schedule!.endTime}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Get a color for a shift name - uses a consistent hash-based approach
  /// so the same shift name always gets the same color.
  Color _getShiftColor(String shiftName) {
    final name = shiftName.toLowerCase();
    if (name.contains('pagi') || name.contains('morning')) {
      return const Color(
        0xFF00897B,
      ); // Teal/Emerald (Pagi - Fresh & Eye-friendly)
    }
    if (name.contains('siang') || name.contains('afternoon')) {
      return AppColors.primary600; // Blue (Siang - Professional)
    }
    if (name.contains('sore') || name.contains('evening')) {
      return const Color(0xFFD84315); // Deep Orange (Sore - Warm Sunset)
    }
    if (name.contains('malam') || name.contains('night')) {
      return AppColors.overtime; // Purple/Indigo (Malam - Night Sky)
    }
    // Fallback: use success green for generic/default shifts
    return AppColors.success;
  }

  /// Get a short abbreviation for the shift name
  String _getShiftAbbreviation(String shiftName) {
    final name = shiftName.toLowerCase();
    if (name.contains('pagi') || name.contains('morning')) return 'P';
    if (name.contains('siang') || name.contains('afternoon')) return 'S';
    if (name.contains('malam') || name.contains('night')) return 'M';
    if (name.contains('sore') || name.contains('evening')) return 'Sr';
    // Fallback: first letter of shift name
    return shiftName.isNotEmpty ? shiftName[0].toUpperCase() : '?';
  }
}
