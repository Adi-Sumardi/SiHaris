import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/feature_config.dart';
import '../../../../data/datasources/device_token_remote_datasource.dart';
import 'device_token_event.dart';
import 'device_token_state.dart';

class DeviceTokenBloc extends Bloc<DeviceTokenEvent, DeviceTokenState> {
  final DeviceTokenRemoteDatasource datasource;

  DeviceTokenBloc(this.datasource) : super(DeviceTokenInitial()) {
    on<RegisterDeviceToken>(_onRegisterDeviceToken);
    on<UnregisterDeviceToken>(_onUnregisterDeviceToken);
    on<RefreshDeviceToken>(_onRefreshDeviceToken);
    on<LoadDeviceTokens>(_onLoadDeviceTokens);
  }

  Future<void> _onRegisterDeviceToken(
    RegisterDeviceToken event,
    Emitter<DeviceTokenState> emit,
  ) async {
    if (!FeatureConfig.enablePushNotification) {
      emit(const DeviceTokenSuccess('Push notifications disabled'));
      return;
    }
    emit(DeviceTokenLoading());
    try {
      await datasource.registerToken(event.request);
      emit(const DeviceTokenSuccess('Device token registered successfully'));
    } catch (e) {
      emit(DeviceTokenFailure(e.toString()));
    }
  }

  Future<void> _onUnregisterDeviceToken(
    UnregisterDeviceToken event,
    Emitter<DeviceTokenState> emit,
  ) async {
    if (!FeatureConfig.enablePushNotification) {
      emit(const DeviceTokenSuccess('Push notifications disabled'));
      return;
    }
    emit(DeviceTokenLoading());
    try {
      await datasource.unregisterToken(event.token);
      emit(const DeviceTokenSuccess('Device token unregistered successfully'));
    } catch (e) {
      emit(DeviceTokenFailure(e.toString()));
    }
  }

  Future<void> _onRefreshDeviceToken(
    RefreshDeviceToken event,
    Emitter<DeviceTokenState> emit,
  ) async {
    if (!FeatureConfig.enablePushNotification) {
      emit(const DeviceTokenSuccess('Push notifications disabled'));
      return;
    }
    emit(DeviceTokenLoading());
    try {
      await datasource.refreshToken(event.oldToken, event.newToken);
      emit(const DeviceTokenSuccess('Device token refreshed successfully'));
    } catch (e) {
      emit(DeviceTokenFailure(e.toString()));
    }
  }

  Future<void> _onLoadDeviceTokens(
    LoadDeviceTokens event,
    Emitter<DeviceTokenState> emit,
  ) async {
    if (!FeatureConfig.enablePushNotification) {
      emit(const DeviceTokenListLoaded([]));
      return;
    }
    emit(DeviceTokenLoading());
    try {
      final tokens = await datasource.getDeviceTokens();
      emit(DeviceTokenListLoaded(tokens));
    } catch (e) {
      emit(DeviceTokenFailure(e.toString()));
    }
  }
}
