import 'package:equatable/equatable.dart';

class RegisterTokenRequestModel extends Equatable {
  final String token;
  final String platform;
  final String? deviceName;
  final String? deviceModel;
  final String? appVersion;

  const RegisterTokenRequestModel({
    required this.token,
    required this.platform,
    this.deviceName,
    this.deviceModel,
    this.appVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'platform': platform,
      if (deviceName != null) 'device_name': deviceName,
      if (deviceModel != null) 'device_model': deviceModel,
      if (appVersion != null) 'app_version': appVersion,
    };
  }

  @override
  List<Object?> get props => [
    token,
    platform,
    deviceName,
    deviceModel,
    appVersion,
  ];
}
