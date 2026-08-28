import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/feature_config.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/datasources/auth_datasource.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/models/requests/register_token_request_model.dart';
import '../../auth/bloc/login/login_bloc.dart';
import '../../auth/bloc/login/login_state.dart';
import '../../auth/bloc/logout/logout_bloc.dart';
import '../../auth/bloc/logout/logout_state.dart';
import '../bloc/device_token/device_token_bloc.dart';
import '../bloc/device_token/device_token_event.dart';

class NotificationWrapper extends StatefulWidget {
  final Widget child;
  final NotificationService? notificationService;
  final AuthLocalDatasourceBase? authLocalDatasource;

  const NotificationWrapper({
    super.key,
    required this.child,
    this.notificationService,
    this.authLocalDatasource,
  });

  @override
  State<NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<NotificationWrapper> {
  late final NotificationService _notificationService =
      widget.notificationService ?? NotificationService();
  late final AuthLocalDatasourceBase _authLocalDatasource =
      widget.authLocalDatasource ?? AuthLocalDatasource();

  @override
  void initState() {
    super.initState();
    _initializeNotification();
  }

  Future<void> _initializeNotification() async {
    if (!FeatureConfig.enablePushNotification) {
      return;
    }
    await _notificationService.initialize();

    // Registrasi token hanya terpicu otomatis oleh event LoginSuccess, tapi
    // splash screen langsung ke MainScreen tanpa event itu kalau sesi lama
    // sudah tersimpan — jadi device yang sudah login sebelum fitur push ini
    // aktif tidak akan pernah ter-registrasi tanpa pengecekan ini.
    if (await _authLocalDatasource.isLoggedIn() && mounted) {
      _registerToken();
    }
  }

  Future<void> _registerToken() async {
    if (!FeatureConfig.enablePushNotification) {
      return;
    }
    final token = await _notificationService.getToken();
    if (token != null && mounted) {
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      if (mounted) {
        context.read<DeviceTokenBloc>().add(
          RegisterDeviceToken(
            RegisterTokenRequestModel(
              token: token,
              platform: Platform.operatingSystem,
              deviceName: deviceInfo['name'],
              deviceModel: deviceInfo['model'],
              appVersion: packageInfo.version,
            ),
          ),
        );
      }
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String? deviceName;
    String? deviceModel;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceName = androidInfo.brand;
        deviceModel = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceName = iosInfo.name;
        deviceModel = iosInfo.model;
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return {
      'name': deviceName ?? 'Unknown Device',
      'model': deviceModel ?? 'Unknown Model',
    };
  }

  Future<void> _unregisterToken() async {
    if (!FeatureConfig.enablePushNotification) {
      return;
    }
    final token = await _notificationService.getToken();
    if (token != null && mounted) {
      context.read<DeviceTokenBloc>().add(UnregisterDeviceToken(token));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              _registerToken();
            }
          },
        ),
        BlocListener<LogoutBloc, LogoutState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              _unregisterToken();
            }
          },
        ),
      ],
      child: widget.child,
    );
  }
}
