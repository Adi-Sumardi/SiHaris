import 'package:equatable/equatable.dart';

class OvertimeRequestModel extends Equatable {
  final String date;
  final String startTime;
  final String endTime;
  final String? overtimeType; // weekday, weekend, holiday
  final String? reason;

  const OvertimeRequestModel({
    required this.date,
    required this.startTime,
    required this.endTime,
    this.overtimeType,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'overtime_type': overtimeType,
      'reason': reason,
    };
  }

  @override
  List<Object?> get props => [date, startTime, endTime, overtimeType, reason];
}
