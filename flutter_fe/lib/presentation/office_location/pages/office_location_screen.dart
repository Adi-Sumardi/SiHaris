import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/colors.dart';
import '../../../core/components/widgets.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/responses/office_location_model.dart';
import '../bloc/office_location/office_location_bloc.dart';
import '../bloc/office_location/office_location_event.dart';
import '../bloc/office_location/office_location_state.dart';
import '../bloc/gps_validation/gps_validation_bloc.dart';
import '../bloc/gps_validation/gps_validation_event.dart';
import '../bloc/gps_validation/gps_validation_state.dart';

/// Office Location Screen with 8-point grid system
/// Spacing: 4, 8, 12, 16, 24, 32 px
/// Font sizes: 10, 12, 14, 16, 20 px
/// Icon sizes: 16, 20, 24, 32 px
/// Container sizes: 48, 56, 96 px
/// Border radius: 4, 8, 12, 16 px
class OfficeLocationScreen extends StatefulWidget {
  const OfficeLocationScreen({super.key});

  @override
  State<OfficeLocationScreen> createState() => _OfficeLocationScreenState();
}

class _OfficeLocationScreenState extends State<OfficeLocationScreen> {
  int? _selectedLocationIndex;
  OfficeLocationModel? _selectedLocation;
  bool _isValidatingGPS = false;
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  String _currentAddress = 'Mengambil lokasi...';
  bool _isGpsAccurate = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _getCurrentLocation();
  }

  void _loadData() {
    context.read<OfficeLocationBloc>().add(GetAssignedOffices());
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _locationService.checkPermission();
    if (!hasPermission) {
      final granted = await _locationService.requestPermission();
      if (!granted) {
        if (mounted) {
          setState(() {
            _currentAddress = 'Izin lokasi tidak diberikan';
            _isGpsAccurate = false;
          });
        }
        return;
      }
    }

    final isEnabled = await _locationService.isLocationServiceEnabled();
    if (!isEnabled) {
      if (mounted) {
        setState(() {
          _currentAddress = 'GPS tidak aktif';
          _isGpsAccurate = false;
        });
      }
      return;
    }

    final position = await _locationService.getCurrentPosition(
      accuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
        _currentAddress =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _isGpsAccurate = position.accuracy <= 50;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const JagoAppBar(
        title: 'Pilih Lokasi',
      ),
      body: BlocListener<GpsValidationBloc, GpsValidationState>(
        listener: (context, state) {
          if (state is GpsValidationLoading) {
            setState(() => _isValidatingGPS = true);
          } else if (state is GpsValidationSuccess) {
            setState(() => _isValidatingGPS = false);
            if (state.response.valid) {
              Navigator.pop(context, _selectedLocation);
            } else {
              _showOutOfRadiusDialog(state.response.errorMessage ?? 'Validasi gagal');
            }
          } else if (state is GpsValidationFailure) {
            setState(() => _isValidatingGPS = false);
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
            // Current GPS status
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lokasi Anda Saat Ini',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentAddress,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isGpsAccurate
                              ? AppColors.successLight
                              : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.gps_fixed_rounded,
                              size: 12,
                              color: _isGpsAccurate
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isGpsAccurate ? 'Akurat' : 'Tidak Akurat',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _isGpsAccurate
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Refresh button
                  InkWell(
                    onTap: _getCurrentLocation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondary100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              color: AppColors.secondary600,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Refresh Lokasi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondary600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Available locations header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Lokasi Kantor Tersedia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Location list
            Expanded(
              child: BlocBuilder<OfficeLocationBloc, OfficeLocationState>(
                builder: (context, state) {
                  if (state is OfficeLocationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is OfficeLocationError) {
                    return JagoEmptyState(
                      title: 'Gagal Memuat Data',
                      message: state.message,
                      icon: Icons.error_outline_rounded,
                      actionText: 'Coba Lagi',
                      onAction: _loadData,
                    );
                  }

                  if (state is OfficeLocationLoaded) {
                    final offices = state.offices;
                    if (offices.isEmpty) {
                      return const JagoEmptyState(
                        title: 'Tidak Ada Lokasi',
                        message: 'Anda belum ditugaskan ke lokasi kantor manapun',
                        icon: Icons.location_off_outlined,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        _loadData();
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: offices.length,
                        itemBuilder: (context, index) {
                          final location = offices[index];
                          return _buildLocationCard(location, index);
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            // Bottom action
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: JagoButton(
                text: _selectedLocation != null
                    ? 'Pilih Lokasi Ini'
                    : 'Pilih Lokasi',
                onPressed:
                    _selectedLocation != null && !_isValidatingGPS && _currentPosition != null
                        ? _confirmLocation
                        : null,
                isLoading: _isValidatingGPS,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(OfficeLocationModel location, int index) {
    final isSelected = _selectedLocationIndex == index;

    // Calculate distance and check if within radius
    double? distance;
    bool isInRadius = false;
    String distanceText = '-';

    if (_currentPosition != null) {
      distance = _locationService.calculateDistance(
        startLatitude: _currentPosition!.latitude,
        startLongitude: _currentPosition!.longitude,
        endLatitude: location.latitude,
        endLongitude: location.longitude,
      );
      isInRadius = distance <= location.radius;
      distanceText = _formatDistance(distance);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocationIndex = index;
          _selectedLocation = location;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary600 : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Location icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isInRadius
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.secondary100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: isInRadius ? AppColors.success : AppColors.secondary400,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              location.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary600,
                              size: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.fullAddress.isNotEmpty
                            ? location.fullAddress
                            : 'Alamat tidak tersedia',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status & distance row
            Row(
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInRadius
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isInRadius
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        size: 12,
                        color: isInRadius ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isInRadius ? 'Dalam Radius' : 'Di Luar Radius',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isInRadius ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Distance
                Row(
                  children: [
                    const Icon(
                      Icons.straighten_rounded,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distanceText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Radius
                Row(
                  children: [
                    const Icon(
                      Icons.radar_rounded,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Radius ${location.radius}m',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (location.isPrimary) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Lokasi Utama',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  void _confirmLocation() {
    if (_currentPosition == null || _selectedLocation == null) return;

    context.read<GpsValidationBloc>().add(
          ValidateGpsLocation(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          ),
        );
  }

  void _showOutOfRadiusDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.warningLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Validasi Gagal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              JagoButton(
                text: 'Mengerti',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
