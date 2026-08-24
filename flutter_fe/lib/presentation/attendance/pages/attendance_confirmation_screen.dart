import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:gaji_pro/core/constants/colors.dart';
import 'package:gaji_pro/core/services/location_service.dart';
import 'package:gaji_pro/data/models/requests/clock_in_request_model.dart';
import 'package:gaji_pro/data/models/requests/clock_out_request_model.dart';
import 'package:gaji_pro/data/models/responses/office_location_model.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance/attendance_bloc.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_today/attendance_today_bloc.dart';

enum AttendanceType { clockIn, clockOut }

/// Confirmation screen shown after face verification succeeds.
/// Displays:
/// - flutter_map with user location marker + office marker + radius circle
/// - GPS status (dalam/luar radius)
/// - Face verification confidence
/// - Submit button (Clock In / Clock Out)
class AttendanceConfirmationScreen extends StatelessWidget {
  const AttendanceConfirmationScreen({
    super.key,
    required this.type,
    required this.userLatitude,
    required this.userLongitude,
    required this.office,
    required this.faceConfidence,
    required this.faceDescriptors,
    this.facePhoto,
    required this.livenessPassed,
    this.notes,
  });

  final AttendanceType type;
  final double userLatitude;
  final double userLongitude;
  final OfficeLocationModel office;
  final double faceConfidence;
  final List<double> faceDescriptors;
  final XFile? facePhoto;

  /// Whether a live blink was observed during face verification (see
  /// [FaceVerificationResult.livenessPassed]). Forwarded to the backend as
  /// `liveness_passed` instead of blindly claiming `true`.
  final bool livenessPassed;
  final String? notes;

  bool get _isWithinRadius {
    return LocationService().isWithinRadius(
      currentLatitude: userLatitude,
      currentLongitude: userLongitude,
      targetLatitude: office.latitude,
      targetLongitude: office.longitude,
      radiusInMeters: office.radius.toDouble(),
    );
  }

  double get _distanceMeters {
    return LocationService().calculateDistance(
      startLatitude: userLatitude,
      startLongitude: userLongitude,
      endLatitude: office.latitude,
      endLongitude: office.longitude,
    );
  }

  String get _title => type == AttendanceType.clockIn
      ? 'Konfirmasi Clock In'
      : 'Konfirmasi Clock Out';

  String get _buttonLabel => type == AttendanceType.clockIn
      ? 'Clock In Sekarang'
      : 'Clock Out Sekarang';

  /// Format distance: show km if >= 1000m, otherwise show m
  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters.toStringAsFixed(0)}m';
  }

  void _submit(BuildContext context) {
    final withinRadius = _isWithinRadius;

    final photo = facePhoto != null ? File(facePhoto!.path) : null;

    if (type == AttendanceType.clockIn) {
      context.read<AttendanceBloc>().add(
        AttendanceClockIn(
          ClockInRequestModel(
            latitude: userLatitude,
            longitude: userLongitude,
            officeLocationId: office.id,
            gpsVerified: withinRadius,
            faceVerified: true,
            faceConfidence: faceConfidence,
            faceDescriptors:
                faceDescriptors.length == 128 ? faceDescriptors : null,
            photo: photo,
            notes: notes,
          ),
        ),
      );
    } else {
      context.read<AttendanceBloc>().add(
        AttendanceClockOut(
          ClockOutRequestModel(
            latitude: userLatitude,
            longitude: userLongitude,
            officeLocationId: office.id,
            gpsVerified: withinRadius,
            faceVerified: true,
            faceConfidence: faceConfidence,
            faceDescriptors:
                faceDescriptors.length == 128 ? faceDescriptors : null,
            photo: photo,
            notes: notes,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLatLng = LatLng(userLatitude, userLongitude);
    final officeLatLng = LatLng(office.latitude, office.longitude);
    final withinRadius = _isWithinRadius;
    final distance = _distanceMeters;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );

            // Refresh today status
            if (context.mounted) {
              try {
                context.read<AttendanceTodayBloc>().add(GetTodayStatus());
              } catch (_) {
                // AttendanceTodayBloc may not be in context tree on this screen
              }
            }

            // Pop back to AttendanceScreen with result=true to trigger refresh
            // Use popUntil to ensure we go back to the right screen
            if (context.mounted) {
              Navigator.of(context).pop(true); // Return true to indicate success
            }
          } else if (state is AttendanceFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        child: Column(
          children: [
            _buildHeader(context),
            // Map
            Expanded(
              flex: 5,
              child: _buildMap(userLatLng, officeLatLng),
            ),
            // Info panel
            Expanded(
              flex: 4,
              child: _buildInfoPanel(
                context,
                withinRadius: withinRadius,
                distance: distance,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary600, AppColors.primary700],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(LatLng userLatLng, LatLng officeLatLng) {
    // Center map on user location for better UX
    return FlutterMap(
      options: MapOptions(
        initialCenter: userLatLng,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.gajipro.app',
        ),
        // Office radius circle
        CircleLayer(
          circles: [
            CircleMarker(
              point: officeLatLng,
              radius: office.radius.toDouble(),
              color: AppColors.primary600.withValues(alpha: 0.15),
              borderColor: AppColors.primary600,
              borderStrokeWidth: 2,
              useRadiusInMeter: true,
            ),
          ],
        ),
        // Markers
        MarkerLayer(
          markers: [
            // Office marker (red pin)
            Marker(
              point: officeLatLng,
              width: 50,
              height: 50,
              alignment: Alignment.topCenter,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 50,
              ),
            ),
            // User marker (blue pin with person icon)
            Marker(
              point: userLatLng,
              width: 50,
              height: 50,
              alignment: Alignment.topCenter,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary600,
                    size: 50,
                  ),
                  Positioned(
                    top: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primary600,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoPanel(
    BuildContext context, {
    required bool withinRadius,
    required double distance,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Office name
          Row(
            children: [
              const Icon(Icons.business, color: AppColors.primary600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  office.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // GPS status row
          Row(
            children: [
              _buildInfoChip(
                icon: withinRadius ? Icons.location_on : Icons.location_off,
                label: withinRadius ? 'Dalam Radius' : 'Luar Radius',
                color: withinRadius ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.straighten,
                label: _formatDistance(distance),
                color: AppColors.textSecondary,
              ),
            ],
          ),

          if (!withinRadius) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Anda berada di luar radius kantor (${office.radius}m). '
                      'Absensi tetap bisa dilakukan.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Submit button
          BlocBuilder<AttendanceBloc, AttendanceState>(
            builder: (context, state) {
              final isLoading = state is AttendanceLoading;
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _submit(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == AttendanceType.clockIn
                        ? AppColors.success
                        : AppColors.danger,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _buttonLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
