import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Syarat dan Ketentuan',
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
              'Syarat dan Ketentuan Penggunaan',
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
              '1. Penerimaan Syarat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Dengan menggunakan aplikasi HRIS, Anda menyetujui untuk terikat oleh syarat dan ketentuan ini. Jika Anda tidak setuju, mohon untuk tidak menggunakan aplikasi ini.',
              style: TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            SizedBox(height: 24),
            Text(
              '2. Akun Pengguna',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Anda bertanggung jawab untuk menjaga kerahasiaan akun dan kata sandi Anda. Segala aktivitas yang terjadi di akun Anda adalah tanggung jawab Anda sepenuhnya.',
              style: TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            SizedBox(height: 24),
            Text(
              '3. Penggunaan yang Dilarang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Dilarang menggunakan aplikasi untuk tujuan ilegal, melanggar hak kekayaan intelektual, atau mengganggu operasi aplikasi.',
              style: TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            SizedBox(height: 24),
            Text(
              '4. Batasan Tanggung Jawab',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'HRIS tidak bertanggung jawab atas kerugian langsung atau tidak langsung yang timbul dari penggunaan aplikasi ini, termasuk kehilangan data atau gangguan layanan.',
              style: TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
