import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/components/widgets.dart';

/// Face Enrollment Screen with 8-point grid system
/// Spacing: 4, 8, 12, 16, 24, 32, 48 px
/// Font sizes: 12, 14, 16, 20, 24 px
/// Icon sizes: 24, 32, 48, 64 px
/// Container sizes: 64, 120, 200 px
/// Border radius: 8, 12, 16, 24 px
class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  int _currentStep = 0;
  bool _isCapturing = false;
  bool _isProcessing = false;
  final List<bool> _capturedPhotos = [false, false, false];

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Wajah Depan',
      'subtitle': 'Hadapkan wajah Anda ke depan',
      'icon': Icons.face,
      'instruction': 'Pastikan wajah berada di tengah frame',
    },
    {
      'title': 'Wajah Kiri',
      'subtitle': 'Putar kepala ke kiri 45°',
      'icon': Icons.rotate_left_rounded,
      'instruction': 'Tunjukkan sisi kiri wajah Anda',
    },
    {
      'title': 'Wajah Kanan',
      'subtitle': 'Putar kepala ke kanan 45°',
      'icon': Icons.rotate_right_rounded,
      'instruction': 'Tunjukkan sisi kanan wajah Anda',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daftarkan Wajah',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? AppColors.primary500
                          : AppColors.secondary700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          // Step info
          Text(
            'Langkah ${_currentStep + 1} dari 3',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _steps[_currentStep]['title'] as String,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _steps[_currentStep]['subtitle'] as String,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          // Camera preview placeholder
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera preview frame
                  Container(
                    width: 280,
                    height: 360,
                    decoration: BoxDecoration(
                      color: AppColors.secondary800,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isCapturing
                            ? AppColors.primary500
                            : AppColors.secondary600,
                        width: 4,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _capturedPhotos[_currentStep]
                          ? _buildCapturedPreview()
                          : _buildCameraPreview(),
                    ),
                  ),
                  // Face guide overlay
                  if (!_capturedPhotos[_currentStep])
                    Positioned(
                      child: Container(
                        width: 200,
                        height: 240,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary400.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(120),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Instruction
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary500.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.primary400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _steps[_currentStep]['instruction'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary300,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Captured photos indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _capturedPhotos[index]
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.secondary800,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: index == _currentStep
                        ? AppColors.primary500
                        : _capturedPhotos[index]
                            ? AppColors.success
                            : AppColors.secondary600,
                    width: 2,
                  ),
                ),
                child: _capturedPhotos[index]
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 32,
                      )
                    : Icon(
                        _steps[index]['icon'] as IconData,
                        color: index == _currentStep
                            ? AppColors.primary400
                            : AppColors.secondary500,
                        size: 24,
                      ),
              );
            }),
          ),
          const SizedBox(height: 32),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _capturedPhotos[_currentStep]
                ? Row(
                    children: [
                      Expanded(
                        child: JagoButton(
                          text: 'Ulangi',
                          type: JagoButtonType.outline,
                          onPressed: _retakePhoto,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: JagoButton(
                          text: _currentStep < 2 ? 'Lanjut' : 'Selesai',
                          onPressed: _isProcessing ? null : _nextStep,
                          isLoading: _isProcessing,
                        ),
                      ),
                    ],
                  )
                : JagoButton(
                    text: 'Ambil Foto',
                    leadingIcon: Icons.camera_alt_rounded,
                    onPressed: _capturePhoto,
                    isLoading: _isCapturing,
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      color: AppColors.secondary900,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face_retouching_natural_rounded,
              size: 64,
              color: AppColors.secondary600,
            ),
            const SizedBox(height: 16),
            Text(
              'Kamera Preview',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondary500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedPreview() {
    return Container(
      color: AppColors.secondary800,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Foto Berhasil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _capturePhoto() {
    setState(() => _isCapturing = true);

    // Simulate capture delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _capturedPhotos[_currentStep] = true;
        });
      }
    });
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhotos[_currentStep] = false;
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitEnrollment();
    }
  }

  void _submitEnrollment() {
    setState(() => _isProcessing = true);

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessDialog();
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.face_retouching_natural_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pendaftaran Berhasil!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Wajah Anda telah terdaftar. Sekarang Anda dapat menggunakan face recognition untuk absensi.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              JagoButton(
                text: 'Selesai',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
