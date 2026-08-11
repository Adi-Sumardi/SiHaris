import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Kebijakan Privasi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Kebijakan Privasi HRIS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Terakhir diperbarui: 17 Februari 2026',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
            SizedBox(height: 24),
            Text(
              '1. Pengumpulan Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kami mengumpulkan informasi yang Anda berikan saat mendaftar akun, seperti nama, alamat email, nomor telepon, dan data kepegawaian lainnya. Kami juga mengumpulkan data lokasi dan biometrik (wajah) untuk keperluan absensi.',
              style: TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            SizedBox(height: 24),
            Text(
              '2. Penggunaan Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Data Anda digunakan untuk memproses penggajian, mencatat kehadiran, dan keperluan administrasi HR lainnya. Kami tidak menjual data Anda kepada pihak ketiga.',
              style: TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            SizedBox(height: 24),
            Text(
              '3. Keamanan Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kami menggunakan standar keamanan industri untuk melindungi data Anda dari akses yang tidak sah. Data sensitif dienkripsi saat penyimpanan dan transmisi.',
              style: TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            SizedBox(height: 24),
            Text(
              '4. Hak Pengguna',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Anda berhak mengakses, memperbaiki, atau menghapus data pribadi Anda. Hubungi tim HR perusahaan Anda untuk permintaan terkait data.',
              style: TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
