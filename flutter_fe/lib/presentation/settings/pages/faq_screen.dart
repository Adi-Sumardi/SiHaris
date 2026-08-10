import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<FaqItem> _faqItems = [
    FaqItem(
      question: 'Bagaimana cara melakukan absensi?',
      answer:
          'Untuk melakukan absensi, tekan tombol "Absensi" di halaman utama atau tab navigasi bawah. '
          'Pastikan Anda berada di lokasi kantor yang terdaftar dan izinkan akses lokasi serta kamera untuk verifikasi wajah.',
    ),
    FaqItem(
      question: 'Mengapa absensi saya gagal?',
      answer:
          'Absensi dapat gagal karena beberapa alasan:\n'
          '• Anda tidak berada di radius lokasi kantor\n'
          '• Wajah tidak terdeteksi atau tidak cocok\n'
          '• Koneksi internet tidak stabil\n'
          '• GPS/Lokasi tidak aktif\n\n'
          'Pastikan semua izin aplikasi sudah diberikan dan Anda berada di lokasi yang benar.',
    ),
    FaqItem(
      question: 'Bagaimana cara mengajukan cuti?',
      answer:
          'Untuk mengajukan cuti:\n'
          '1. Buka menu "Cuti" dari halaman utama\n'
          '2. Tekan tombol "+" atau "Ajukan Cuti"\n'
          '3. Pilih jenis cuti dan tanggal\n'
          '4. Isi alasan pengajuan\n'
          '5. Tekan "Kirim"\n\n'
          'Pengajuan akan dikirim ke atasan untuk disetujui.',
    ),
    FaqItem(
      question: 'Berapa lama pengajuan cuti diproses?',
      answer:
          'Waktu proses pengajuan cuti tergantung pada kebijakan perusahaan dan ketersediaan atasan. '
          'Umumnya pengajuan akan diproses dalam 1-3 hari kerja. '
          'Anda akan menerima notifikasi ketika pengajuan disetujui atau ditolak.',
    ),
    FaqItem(
      question: 'Bagaimana cara melihat slip gaji?',
      answer:
          'Untuk melihat slip gaji:\n'
          '1. Buka menu "Slip Gaji" dari halaman utama atau tab navigasi\n'
          '2. Pilih periode/bulan yang ingin dilihat\n'
          '3. Tekan untuk melihat detail slip gaji\n\n'
          'Anda juga dapat mengunduh slip gaji dalam format PDF.',
    ),
    FaqItem(
      question: 'Bagaimana cara mengajukan lembur?',
      answer:
          'Untuk mengajukan lembur:\n'
          '1. Buka menu "Lembur" dari halaman utama\n'
          '2. Tekan tombol "+" atau "Ajukan Lembur"\n'
          '3. Pilih tanggal dan durasi lembur\n'
          '4. Isi alasan/deskripsi pekerjaan\n'
          '5. Tekan "Kirim"\n\n'
          'Pengajuan lembur harus disetujui atasan sebelum dikerjakan.',
    ),
    FaqItem(
      question: 'Bagaimana cara mendaftarkan wajah untuk absensi?',
      answer:
          'Untuk mendaftarkan wajah:\n'
          '1. Buka "Profil" > "Pengaturan" > "Face Recognition"\n'
          '2. Tekan "Daftarkan Wajah"\n'
          '3. Ikuti instruksi untuk mengambil foto wajah\n'
          '4. Pastikan pencahayaan cukup dan wajah terlihat jelas\n\n'
          'Setelah terdaftar, Anda dapat menggunakan wajah untuk verifikasi absensi.',
    ),
    FaqItem(
      question: 'Bagaimana cara mengubah password?',
      answer:
          'Untuk mengubah password:\n'
          '1. Buka "Profil"\n'
          '2. Pilih "Ubah Password"\n'
          '3. Masukkan password lama\n'
          '4. Masukkan password baru (minimal 8 karakter)\n'
          '5. Konfirmasi password baru\n'
          '6. Tekan "Simpan"',
    ),
    FaqItem(
      question: 'Bagaimana cara menghubungi HR/Admin?',
      answer:
          'Jika Anda memiliki pertanyaan atau masalah yang tidak dapat diselesaikan melalui aplikasi, '
          'silakan hubungi HR/Admin perusahaan Anda melalui:\n'
          '• Email: hr@perusahaan.com\n'
          '• Telepon: (021) xxx-xxxx\n\n'
          'Atau kunjungi kantor HR pada jam kerja.',
    ),
    FaqItem(
      question: 'Apakah data saya aman?',
      answer:
          'Ya, keamanan data Anda adalah prioritas kami. Aplikasi ini menggunakan:\n'
          '• Enkripsi data end-to-end\n'
          '• Autentikasi yang aman\n'
          '• Server yang terproteksi\n'
          '• Kebijakan privasi yang ketat\n\n'
          'Data biometrik wajah hanya digunakan untuk verifikasi absensi dan tidak dibagikan ke pihak ketiga.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bantuan & FAQ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary600, AppColors.primary700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ada pertanyaan?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Temukan jawaban dari pertanyaan yang sering diajukan',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // FAQ List
          const Text(
            'Pertanyaan Umum',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_faqItems.length, (index) {
            return _buildFaqCard(_faqItems[index], index);
          }),
          const SizedBox(height: 24),
          // Contact Support
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary600,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Masih butuh bantuan?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hubungi tim support kami',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Open email
                        },
                        icon: const Icon(Icons.email_outlined, size: 18),
                        label: const Text('Email'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary600,
                          side: const BorderSide(color: AppColors.primary600),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Open WhatsApp
                        },
                        icon: const Icon(Icons.chat_outlined, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFaqCard(FaqItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isExpanded ? AppColors.primary200 : AppColors.border,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary600,
                ),
              ),
            ),
          ),
          title: Text(
            item.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: Icon(
            item.isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary600,
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              item.isExpanded = expanded;
            });
          },
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.answer,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaqItem {
  final String question;
  final String answer;
  bool isExpanded;

  FaqItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}
