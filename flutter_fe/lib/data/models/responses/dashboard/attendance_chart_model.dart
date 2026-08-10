/// Attendance Chart Model
/// Sesuai dengan API docs: GET /dashboard/attendance-chart
class AttendanceChartModel {
  final List<String> labels;
  final List<ChartDataset> datasets;

  AttendanceChartModel({
    required this.labels,
    required this.datasets,
  });

  factory AttendanceChartModel.fromJson(Map<String, dynamic> json) {
    return AttendanceChartModel(
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      datasets: (json['datasets'] as List<dynamic>?)
              ?.map((e) => ChartDataset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labels': labels,
      'datasets': datasets.map((e) => e.toJson()).toList(),
    };
  }
}

/// Chart Dataset - Single data series
class ChartDataset {
  final String label;
  final List<double> data;

  ChartDataset({
    required this.label,
    required this.data,
  });

  factory ChartDataset.fromJson(Map<String, dynamic> json) {
    return ChartDataset(
      label: json['label'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'data': data,
    };
  }
}
