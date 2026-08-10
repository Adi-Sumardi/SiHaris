import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/colors.dart';
import '../../../data/models/responses/attendance_history_model.dart';
import '../../home/pages/main_screen.dart';

/// Attendance Detail Screen - Shows detailed info for a specific attendance record
class AttendanceDetailScreen extends StatelessWidget {
  const AttendanceDetailScreen({
    super.key,
    required this.attendance,
  });

  final AttendanceHistoryModel attendance;

  Color get _statusColor {
    switch (attendance.status.toLowerCase()) {
      case 'present':
        return AppColors.success;
      case 'late':
        return AppColors.warning;
      case 'leave':
        return AppColors.statusLeave;
      case 'absent':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _formattedDate {
    final date = DateTime.tryParse(attendance.date) ?? DateTime.now();
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildTimeCard(),
                  const SizedBox(height: 16),
                  if (attendance.clockInLocation != null) _buildLocationSection(),
                  if (attendance.workingFormatted != null) ...[
                    const SizedBox(height: 16),
                    _buildWorkingHoursCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                        );
                      }
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Detail Kehadiran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Text(
                _formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(),
              color: _statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Kehadiran',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    attendance.statusLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (attendance.status.toLowerCase()) {
      case 'present':
        return Icons.check_circle_outline_rounded;
      case 'late':
        return Icons.schedule_rounded;
      case 'leave':
        return Icons.event_available_rounded;
      case 'absent':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Waktu Kehadiran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeItem(
                  icon: Icons.login_rounded,
                  label: 'Clock In',
                  time: attendance.clockIn ?? '--:--',
                  color: AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _buildTimeItem(
                  icon: Icons.logout_rounded,
                  label: 'Clock Out',
                  time: attendance.clockOut ?? '--:--',
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: time == '--:--' ? AppColors.textTertiary : color,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    final clockInLoc = attendance.clockInLocation;
    final clockOutLoc = attendance.clockOutLocation;
    final office = clockInLoc?.office;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lokasi Absensi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (office != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        office.name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (office?.address != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      office!.address!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Map widget
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: _buildMap(clockInLoc!, clockOutLoc, office),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          _buildMapLegend(clockInLoc, clockOutLoc),
        ],
      ),
    );
  }

  Widget _buildMap(
    AttendanceLocationModel clockInLoc,
    AttendanceLocationModel? clockOutLoc,
    OfficeLocationModel? office,
  ) {
    final markers = <Marker>[];
    final circles = <CircleMarker>[];

    // Office location marker and radius circle
    if (office != null) {
      final officeLatLng = LatLng(office.latitude, office.longitude);

      // Add radius circle for office
      circles.add(
        CircleMarker(
          point: officeLatLng,
          radius: office.radius.toDouble(),
          useRadiusInMeter: true,
          color: AppColors.primary.withValues(alpha: 0.1),
          borderColor: AppColors.primary.withValues(alpha: 0.4),
          borderStrokeWidth: 2,
        ),
      );

      // Office marker
      markers.add(
        Marker(
          point: officeLatLng,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    // Clock In marker
    final clockInLatLng = LatLng(clockInLoc.latitude, clockInLoc.longitude);
    markers.add(
      Marker(
        point: clockInLatLng,
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.login_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );

    // Clock Out marker
    if (clockOutLoc != null) {
      final clockOutLatLng = LatLng(clockOutLoc.latitude, clockOutLoc.longitude);
      markers.add(
        Marker(
          point: clockOutLatLng,
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }

    // Calculate bounds to fit all points
    final points = [clockInLatLng];
    if (clockOutLoc != null) {
      points.add(LatLng(clockOutLoc.latitude, clockOutLoc.longitude));
    }
    if (office != null) {
      points.add(LatLng(office.latitude, office.longitude));
    }

    // Center on clock in location or office
    final centerLat = office?.latitude ?? clockInLoc.latitude;
    final centerLng = office?.longitude ?? clockInLoc.longitude;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.jagogaji.gaji_pro',
        ),
        CircleLayer(circles: circles),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildMapLegend(
    AttendanceLocationModel clockInLoc,
    AttendanceLocationModel? clockOutLoc,
  ) {
    return Column(
      children: [
        _buildLegendItem(
          color: AppColors.primary,
          icon: Icons.business_rounded,
          label: 'Lokasi Kantor',
          subtitle: clockInLoc.office?.name,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          color: AppColors.success,
          icon: Icons.login_rounded,
          label: 'Clock In',
          subtitle: attendance.clockIn,
        ),
        if (clockOutLoc != null) ...[
          const SizedBox(height: 8),
          _buildLegendItem(
            color: AppColors.info,
            icon: Icons.logout_rounded,
            label: 'Clock Out',
            subtitle: attendance.clockOut,
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required IconData icon,
    required String label,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHoursCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: AppColors.accent500,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Jam Kerja',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  attendance.workingFormatted!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
