import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:gaji_pro/data/datasources/attendance_remote_datasource.dart';
import 'package:gaji_pro/data/models/responses/office_location_model.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance/attendance_bloc.dart';
import 'package:gaji_pro/presentation/attendance/bloc/attendance_today/attendance_today_bloc.dart';
import 'package:gaji_pro/presentation/attendance/pages/attendance_confirmation_screen.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_bloc.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_event.dart';
import 'package:gaji_pro/presentation/face_recognition/bloc/face_recognition_status/face_recognition_status_state.dart';
import 'package:gaji_pro/presentation/face_recognition/pages/face_enroll_screen.dart';
import 'package:gaji_pro/presentation/face_recognition/pages/face_verify_attendance_screen.dart';
import 'package:gaji_pro/presentation/home/pages/main_screen.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_bloc.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_event.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_state.dart';
import '../../../core/constants/colors.dart';
import '../../../core/components/widgets.dart';
import '../../../core/components/jago_header_band.dart';
import '../widgets/clock_button.dart';
import '../widgets/attendance_calendar.dart';
import 'attendance_history_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    // Coba kirim absensi offline yang tertunda, lalu muat ulang status hari ini
    // agar UI mencerminkan hasil sinkronisasi.
    AttendanceRemoteDatasource().syncPendingAttendance().then((synced) {
      if (synced > 0 && mounted) {
        context.read<AttendanceTodayBloc>().add(GetTodayStatus());
      }
    });
    context.read<AttendanceTodayBloc>().add(GetTodayStatus());
    context.read<FaceRecognitionStatusBloc>().add(LoadFaceRecognitionStatus());
    context.read<OfficeLocationBloc>().add(GetAssignedOffices());
  }

  String _formatMinutesToHoursMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}j ${minutes}m';
    } else if (hours > 0) {
      return '${hours}j';
    } else {
      return '${minutes}m';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied.'),
          ),
        );
      }
      return null;
    }

    final position = await Geolocator.getCurrentPosition();

    // Anti-fraud: tolak fake GPS / mock location (Android `isFromMockProvider`).
    if (position.isMocked) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.gpp_bad_rounded, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Expanded(child: Text('Lokasi Palsu Terdeteksi')),
              ],
            ),
            content: const Text(
              'Aplikasi mendeteksi penggunaan fake GPS / mock location. '
              'Nonaktifkan aplikasi lokasi palsu terlebih dahulu untuk dapat melakukan absensi.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
      }
      return null;
    }

    return position;
  }

  void _showEnrollmentRequiredDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wajah Belum Terdaftar'),
        content: const Text(
          'Anda perlu mendaftarkan wajah terlebih dahulu untuk melakukan absensi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToEnroll();
            },
            child: const Text('Daftarkan Wajah'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEnroll() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FaceEnrollScreen()),
    );
    // Refresh face status after enrollment
    if (result == true && mounted) {
      context.read<FaceRecognitionStatusBloc>().add(
        LoadFaceRecognitionStatus(),
      );
    }
  }

  void _showFaceStatusErrorDialog(
    BuildContext blocContext,
    String errorMessage,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wajah Belum Terdaftar'),
        content: const Text(
          'Anda perlu mendaftarkan wajah terlebih dahulu untuk melakukan absensi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToEnroll();
            },
            child: const Text('Daftarkan Wajah'),
          ),
        ],
      ),
    );
  }

  Future<void> _startAttendanceFlow({
    required BuildContext blocContext,
    required AttendanceType type,
    required OfficeLocationModel? office,
  }) async {
    if (office == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data kantor tidak tersedia. Coba lagi.'),
          ),
        );
      }
      return;
    }

    // Check enrollment status before proceeding
    if (mounted) {
      final statusState = blocContext.read<FaceRecognitionStatusBloc>().state;
      if (statusState is FaceRecognitionStatusLoading ||
          statusState is FaceRecognitionStatusInitial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sedang memeriksa status wajah, coba lagi sebentar.'),
          ),
        );
        return;
      }
      if (statusState is FaceRecognitionStatusError) {
        // Show dialog with retry option
        _showFaceStatusErrorDialog(blocContext, statusState.message);
        return;
      }
      if (statusState is FaceRecognitionStatusLoaded &&
          !statusState.status.enrolled) {
        _showEnrollmentRequiredDialog();
        return;
      }
    }

    // Ambang kecocokan wajah dari company settings. Frontend & backend kini
    // sama-sama memakai cosine similarity (0.0-1.0, makin tinggi makin cocok),
    // jadi nilai threshold dipakai langsung tanpa konversi.
    double matchThreshold = 0.48;
    final faceStatusState = context.read<FaceRecognitionStatusBloc>().state;
    if (faceStatusState is FaceRecognitionStatusLoaded) {
      matchThreshold =
          faceStatusState.status.companySettings?.matchThreshold ?? 0.48;
    }
    if (matchThreshold > 0.50) {
      matchThreshold = 0.50;
    }

    final position = await _getCurrentLocation();
    if (position == null || !mounted) return;

    // Validate GPS location before proceeding to face recognition
    final distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      office.latitude,
      office.longitude,
    );
    final isWithinRadius = distanceInMeters <= office.radius;

    if (!isWithinRadius) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_off_rounded, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text('Di Luar Radius'),
              ],
            ),
            content: Text(
              'Anda berada ${(distanceInMeters).round()}m dari ${office.name}.\n'
              'Radius yang diizinkan: ${office.radius}m.\n\n'
              'Silakan mendekat ke lokasi kantor untuk melakukan absensi.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final attendanceBloc = context.read<AttendanceBloc>();

    final isClockIn = type == AttendanceType.clockIn;

    if (!mounted) return;

    final result = await Navigator.push<FaceVerificationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FaceVerifyAttendanceScreen(
          isClockIn: isClockIn,
          matchThreshold: matchThreshold,
        ),
      ),
    );

    if (result != null && result.isValid && mounted) {
      // Navigate to confirmation screen with verified face data
      final confirmationResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: attendanceBloc,
            child: AttendanceConfirmationScreen(
              type: type,
              userLatitude: position.latitude,
              userLongitude: position.longitude,
              office: office,
              faceConfidence: result.confidence ?? 0.0,
              faceDescriptors: result.embedding ?? [],
              facePhoto: result.image,
              livenessPassed: result.livenessPassed,
            ),
          ),
        ),
      );

      // Refresh data after successful clock in/out
      if (confirmationResult == true && mounted) {
        // Refresh attendance today status from server
        context.read<AttendanceTodayBloc>().add(GetTodayStatus());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          context.read<AttendanceTodayBloc>().add(GetTodayStatus());
        } else if (state is AttendanceFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Column(
          children: [
            _buildHeader(),
            const JagoHeaderBand(),
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Hari Ini'),
                  Tab(text: 'Kalender'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildTodayTab(), const AttendanceCalendar()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<AttendanceTodayBloc, AttendanceTodayState>(
      builder: (context, todayState) {
        return BlocBuilder<OfficeLocationBloc, OfficeLocationState>(
          builder: (context, officeState) {
            String clockInTime = '--:--';
            String clockOutTime = '--:--';
            bool hasClockedIn = false;
            bool hasClockedOut = false;
            OfficeLocationModel? office;

            int? todayOfficeId;
            if (todayState is AttendanceTodayLoaded) {
              // Server sudah kirim waktu dalam timezone company, tidak perlu convert
              clockInTime = todayState.data.clockIn ?? '--:--';
              clockOutTime = todayState.data.clockOut ?? '--:--';
              hasClockedIn = todayState.data.clockIn != null;
              hasClockedOut = todayState.data.clockOut != null;
              todayOfficeId = todayState.data.officeLocation?.id;
            }

            // The office_location returned by /attendance/today only has
            // id+name — lat/lng/radius are missing, so resolve full data
            // from OfficeLocationBloc (assigned offices) by matching id.
            if (officeState is OfficeLocationLoaded &&
                officeState.offices.isNotEmpty) {
              final offices = officeState.offices;
              if (todayOfficeId != null) {
                office = offices.firstWhere(
                  (o) => o.id == todayOfficeId,
                  orElse: () => offices.firstWhere(
                    (o) => o.isPrimary,
                    orElse: () => offices.first,
                  ),
                );
              } else {
                office = offices.firstWhere(
                  (o) => o.isPrimary,
                  orElse: () => offices.first,
                );
              }
            } else if (todayState is AttendanceTodayLoaded) {
              // Fallback: assigned offices not loaded yet, use partial
              // today's office (radius check may fail until offices load).
              office = todayState.data.officeLocation;
            }

            return Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  MaterialPageRoute(
                                    builder: (_) => const MainScreen(),
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.history_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AttendanceHistoryScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (context, snapshot) {
                          final now = DateTime.now();
                          return Text(
                            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<AttendanceBloc, AttendanceState>(
                        builder: (context, blocState) {
                          final isLoading = blocState is AttendanceLoading;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTimeStatus(
                                'Clock In',
                                clockInTime,
                                hasClockedIn,
                              ),
                              const SizedBox(width: 16),
                              isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : ClockButton(
                                      hasClockedIn: hasClockedIn,
                                      hasClockedOut: hasClockedOut,
                                      onClockIn: () => _startAttendanceFlow(
                                        blocContext: context,
                                        type: AttendanceType.clockIn,
                                        office: office,
                                      ),
                                      onClockOut: () => _startAttendanceFlow(
                                        blocContext: context,
                                        type: AttendanceType.clockOut,
                                        office: office,
                                      ),
                                    ),
                              const SizedBox(width: 16),
                              _buildTimeStatus(
                                'Clock Out',
                                clockOutTime,
                                hasClockedOut,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeStatus(String label, String time, bool isDone) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.success.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTab() {
    return BlocBuilder<AttendanceTodayBloc, AttendanceTodayState>(
      builder: (context, state) {
        if (state is AttendanceTodayLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AttendanceTodayError) {
          return Center(child: Text(state.message));
        }
        if (state is AttendanceTodayNotFound) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada absensi hari ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gunakan tombol absensi untuk clock in',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        if (state is AttendanceTodayLoaded) {
          final data = state.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.clockInSource == 'fingerprint' ||
                    data.clockOutSource == 'fingerprint') ...[
                  JagoCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
                            color: AppColors.info,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kanal Absensi: Mesin Fingerprint',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Absensi Anda hari ini tercatat dari Mesin Fingerprint.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (data.officeLocation != null) ...[
                  JagoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.primary600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lokasi Terdeteksi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data.officeLocation!.name,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Jadwal Kerja',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (data.schedule?.name != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              data.schedule!.name!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary600,
                              ),
                            ),
                          ),
                          if (data.schedule != null &&
                              data.schedule!.startTime.compareTo(
                                    data.schedule!.endTime,
                                  ) >
                                  0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.overtime.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.nightlight_round,
                                    size: 12,
                                    color: AppColors.overtime,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Overnight',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.overtime,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                JagoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildScheduleItem(
                        'Jadwal Masuk',
                        data.schedule?.startTime ?? '-',
                        Icons.login_rounded,
                        AppColors.success,
                      ),
                      const Divider(height: 1),
                      _buildScheduleItem(
                        'Jadwal Pulang',
                        data.schedule?.isFlexible == true &&
                                data.targetClockOut != null &&
                                data.targetClockOut != data.schedule?.endTime
                            ? '${data.schedule?.endTime} (Fleksi ${data.targetClockOut})'
                            : (data.schedule?.endTime ?? '-'),
                        Icons.logout_rounded,
                        AppColors.info,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Status Hari Ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    int activeWorkingMinutes = data.workingMinutes;
                    if (activeWorkingMinutes <= 0 &&
                        data.clockIn != null &&
                        data.clockOut == null) {
                      try {
                        final parts = data.clockIn!.split(':');
                        final clockInHour = int.parse(parts[0]);
                        final clockInMinute = int.parse(parts[1]);
                        final now = DateTime.now();
                        final clockInDt = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          clockInHour,
                          clockInMinute,
                        );
                        if (now.isAfter(clockInDt)) {
                          activeWorkingMinutes = now
                              .difference(clockInDt)
                              .inMinutes;
                        }
                      } catch (_) {}
                    }

                    int computedLateMinutes = data.lateMinutes;
                    if (computedLateMinutes <= 0 &&
                        data.clockIn != null &&
                        data.schedule != null) {
                      try {
                        final inParts = data.clockIn!.split(':');
                        final startParts = data.schedule!.startTime.split(':');
                        final inMinutes =
                            int.parse(inParts[0]) * 60 + int.parse(inParts[1]);
                        final startMinutes =
                            int.parse(startParts[0]) * 60 +
                            int.parse(startParts[1]);
                        if (inMinutes > startMinutes) {
                          final diff = inMinutes - startMinutes;
                          final tol = data.schedule!.lateTolerance;
                          if (!data.schedule!.isFlexible && diff > tol) {
                            computedLateMinutes = diff;
                          }
                        }
                      } catch (_) {}
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatusCard(
                            'Jam Kerja',
                            _formatMinutesToHoursMinutes(activeWorkingMinutes),
                            Icons.access_time_rounded,
                            AppColors.primary600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatusCard(
                            'Keterlambatan',
                            _formatMinutesToHoursMinutes(computedLateMinutes),
                            Icons.timer_off_outlined,
                            computedLateMinutes > 0
                                ? AppColors.warning
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('No data'));
      },
    );
  }

  Widget _buildScheduleItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return JagoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
