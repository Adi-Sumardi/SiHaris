import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/responses/tax_form_detail_model.dart';
import '../bloc/tax_form_detail/tax_form_detail_bloc.dart';

/// Tax Form Detail Screen - Detail Bukti Potong 1721-A1
class TaxFormDetailScreen extends StatefulWidget {
  final int taxFormId;

  const TaxFormDetailScreen({super.key, required this.taxFormId});

  @override
  State<TaxFormDetailScreen> createState() => _TaxFormDetailScreenState();
}

class _TaxFormDetailScreenState extends State<TaxFormDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TaxFormDetailBloc>().add(GetTaxFormDetail(widget.taxFormId));
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _downloadPdf() async {
    context.read<TaxFormDetailBloc>().add(DownloadTaxForm(widget.taxFormId));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka PDF')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaxFormDetailBloc, TaxFormDetailState>(
      listener: (context, state) {
        if (state is TaxFormDownloadReady) {
          _openUrl(state.download.downloadUrl);
        }
        if (state is TaxFormDownloadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: BlocBuilder<TaxFormDetailBloc, TaxFormDetailState>(
          builder: (context, state) {
            if (state is TaxFormDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TaxFormDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal memuat data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<TaxFormDetailBloc>().add(GetTaxFormDetail(widget.taxFormId));
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }
            if (state is TaxFormDetailLoaded) {
              return _buildContent(state.taxForm);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildContent(TaxFormDetailModel taxForm) {
    return Column(
      children: [
        _buildHeader(taxForm),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildIdentitasSection(taxForm),
                const SizedBox(height: 16),
                _buildPenghasilanBrutoSection(taxForm.penghasilanBruto),
                const SizedBox(height: 16),
                _buildPengurangSection(taxForm.pengurang),
                const SizedBox(height: 16),
                _buildPerhitunganPphSection(taxForm.perhitunganPph, taxForm.employee.ptkpStatus),
                const SizedBox(height: 24),
                _buildDownloadButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(TaxFormDetailModel taxForm) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Detail Bukti Potong',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'FORMULIR 1721-A1',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tahun Pajak ${taxForm.taxYear}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    taxForm.formNumber,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Masa Perolehan: ${taxForm.workPeriod}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentitasSection(TaxFormDetailModel taxForm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IDENTITAS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSubSection('A. Pemotong Pajak (Perusahaan)', [
            _buildInfoRow('NPWP', taxForm.company.npwp ?? '-'),
            _buildInfoRow('Nama', taxForm.company.name),
            _buildInfoRow('Alamat', taxForm.company.address ?? '-'),
          ]),
          const SizedBox(height: 16),
          _buildSubSection('B. Penerima Penghasilan', [
            _buildInfoRow('NPWP', taxForm.employee.npwp ?? '-'),
            _buildInfoRow('NIK', taxForm.employee.nik ?? '-'),
            _buildInfoRow('Nama', taxForm.employee.name),
            _buildInfoRow('Status PTKP', taxForm.employee.ptkpStatus),
          ]),
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppColors.textTertiary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenghasilanBrutoSection(PenghasilanBruto penghasilan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'C. PENGHASILAN BRUTO',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildAmountRow('1. Gaji/Pensiun atau THT/JHT', penghasilan.gajiPokok),
          _buildAmountRow('2. Tunjangan PPh', penghasilan.tunjanganPph),
          _buildAmountRow('3. Tunjangan lainnya, uang lembur, dsb', penghasilan.tunjanganLainnya),
          _buildAmountRow('4. Honorarium dan imbalan lain', penghasilan.honorarium),
          _buildAmountRow('5. Premi asuransi dibayar pemberi kerja', penghasilan.premiAsuransi),
          _buildAmountRow('6. Natura dan kenikmatan lainnya', penghasilan.natura),
          _buildAmountRow('7. Tantiem, Bonus, Gratifikasi, THR', penghasilan.tantiemBonusThr),
          const Divider(height: 16),
          _buildAmountRow('8. JUMLAH PENGHASILAN BRUTO', penghasilan.grossSalary, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPengurangSection(Pengurang pengurang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PENGURANG',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildAmountRow('9. Biaya Jabatan (5% maks 6 juta)', pengurang.biayaJabatan),
          _buildAmountRow('10. Iuran Pensiun/JHT dibayar sendiri', pengurang.iuranPensiun),
          const Divider(height: 16),
          _buildAmountRow('11. JUMLAH PENGURANG', pengurang.totalPengurang, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPerhitunganPphSection(PerhitunganPph perhitungan, String ptkpStatus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERHITUNGAN PPh PASAL 21',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildAmountRow('12. PENGHASILAN NETO', perhitungan.netoSalary),
          _buildAmountRow('15. PTKP ($ptkpStatus)', perhitungan.ptkp),
          _buildAmountRow('16. PKP (Penghasilan Kena Pajak)', perhitungan.pkp),
          _buildAmountRow('17. PPh Pasal 21 Terutang', perhitungan.pph21Terutang),
          _buildAmountRow('18. PPh 21 Dipotong Sebelumnya', perhitungan.pph21DipotongSebelumnya),
          const Divider(height: 16),
          _buildAmountRow(
            '19. PPh PASAL 21 TERUTANG',
            perhitungan.totalPph21Withheld,
            isTotal: true,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isTotal = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 13 : 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontFamily: 'monospace',
              color: isHighlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return BlocBuilder<TaxFormDetailBloc, TaxFormDetailState>(
      builder: (context, state) {
        final isDownloading = state is TaxFormDownloading;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isDownloading ? null : _downloadPdf,
            icon: isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(isDownloading ? 'Memproses...' : 'Download PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}
