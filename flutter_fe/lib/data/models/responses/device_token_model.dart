import 'package:equatable/equatable.dart';

class DeviceTokenModel extends Equatable {
  final int id;
  final String platform;
  final String? deviceName;
  final String? deviceModel;
  final String? appVersion;
  final bool isActive;
  final DateTime? lastUsedAt;

  const DeviceTokenModel({
    required this.id,
    required this.platform,
    this.deviceName,
    this.deviceModel,
    this.appVersion,
    required this.isActive,
    this.lastUsedAt,
  });

  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) {
    return DeviceTokenModel(
      id: json['id'],
      platform: json['platform'],
      deviceName: json['device_name'],
      deviceModel: json['device_model'],
      appVersion: json['app_version'],
      isActive: json['is_active'] ?? true,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        platform,
        deviceName,
        deviceModel,
        appVersion,
        isActive,
        lastUsedAt,
      ];
}
