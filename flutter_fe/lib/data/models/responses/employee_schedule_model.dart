class EmployeeScheduleResponse {
  final String month;
  final String monthLabel;
  final String prevMonth;
  final String nextMonth;
  final List<EmployeeScheduleDay> days;

  const EmployeeScheduleResponse({
    required this.month,
    required this.monthLabel,
    required this.prevMonth,
    required this.nextMonth,
    required this.days,
  });

  factory EmployeeScheduleResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeScheduleResponse(
      month: json['month'] ?? '',
      monthLabel: json['month_label'] ?? '',
      prevMonth: json['prev_month'] ?? '',
      nextMonth: json['next_month'] ?? '',
      days: (json['days'] as List<dynamic>? ?? [])
          .map((e) => EmployeeScheduleDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EmployeeScheduleDay {
  final String date;
  final String dayName;
  final bool isWorkingDay;
  final bool isHoliday;
  final String? holidayName;
  final EmployeeScheduleShift? schedule;

  const EmployeeScheduleDay({
    required this.date,
    required this.dayName,
    required this.isWorkingDay,
    required this.isHoliday,
    this.holidayName,
    this.schedule,
  });

  factory EmployeeScheduleDay.fromJson(Map<String, dynamic> json) {
    return EmployeeScheduleDay(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      isWorkingDay: json['is_working_day'] ?? false,
      isHoliday: json['is_holiday'] ?? false,
      holidayName: json['holiday_name'],
      schedule: json['schedule'] != null
          ? EmployeeScheduleShift.fromJson(
              json['schedule'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class EmployeeScheduleShift {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final bool isOvernight;

  const EmployeeScheduleShift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.isOvernight,
  });

  factory EmployeeScheduleShift.fromJson(Map<String, dynamic> json) {
    return EmployeeScheduleShift(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      isOvernight: json['is_overnight'] ?? false,
    );
  }
}
