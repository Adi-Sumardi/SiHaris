import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/core/constants/colors.dart';
import 'package:gaji_pro/presentation/office_location/bloc/gps_validation/gps_validation_bloc.dart';
import 'package:gaji_pro/presentation/office_location/bloc/gps_validation/gps_validation_event.dart';
import 'package:gaji_pro/presentation/office_location/bloc/gps_validation/gps_validation_state.dart';

/// Widget reusable untuk menampilkan status validasi GPS.
/// Perlu diletakkan di dalam BlocProvider<GpsValidationBloc>.
class GpsValidationWidget extends StatelessWidget {
  final double latitude;
  final double longitude;

  const GpsValidationWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GpsValidationBloc, GpsValidationState>(
      builder: (context, state) {
        if (state is GpsValidationInitial) {
          return _buildValidateButton(context);
        }
        if (state is GpsValidationLoading) {
          return _buildLoading();
        }
        if (state is GpsValidationSuccess) {
          final response = state.response;
          if (response.valid) {
            return _buildValid(response.distance);
          } else {
            return _buildInvalid(
              response.errorMessage ?? 'Lokasi tidak valid',
              response.distance,
            );
          }
        }
        if (state is GpsValidationFailure) {
          return _buildError(context, state.message);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildValidateButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.read<GpsValidationBloc>().add(
            ValidateGpsLocation(latitude: latitude, longitude: longitude),
          ),
      icon: const Icon(Icons.gps_fixed, size: 16),
      label: const Text('Validasi GPS'),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Memvalidasi GPS...', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildValid(double? distance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: AppColors.success, size: 16),
          const SizedBox(width: 6),
          Text(
            distance != null
                ? 'Dalam Radius (${distance.toStringAsFixed(0)}m)'
                : 'Dalam Radius',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalid(String message, double? distance) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: AppColors.danger, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Luar Radius',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
                Text(
                  distance != null
                      ? '$message (${distance.toStringAsFixed(0)}m)'
                      : message,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, color: AppColors.warning),
            ),
          ),
          TextButton(
            onPressed: () => context.read<GpsValidationBloc>().add(
                  ValidateGpsLocation(latitude: latitude, longitude: longitude),
                ),
            child: const Text('Coba Lagi', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
