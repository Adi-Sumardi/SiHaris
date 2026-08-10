import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/responses/payslip_detail_model.dart';
import '../../home/pages/main_screen.dart';
import '../bloc/payslip_detail/payslip_detail_bloc.dart';
import '../bloc/payslip_download/payslip_download_bloc.dart';

/// Payslip Detail Screen with BLoC integration
class PayslipDetailScreen extends StatefulWidget {
  final int payslipId;

  const PayslipDetailScreen({super.key, required this.payslipId});

  @override
  State<PayslipDetailScreen> createState() => _PayslipDetailScreenState();
}

class _PayslipDetailScreenState extends State<PayslipDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PayslipDetailBloc>().add(GetPayslipDetail(widget.payslipId));
  }

  void _downloadPayslip() {
    context.read<PayslipDownloadBloc>().add(DownloadPayslip(widget.payslipId));
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM y', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: BlocListener<PayslipDownloadBloc, PayslipDownloadState>(
        listener: (context, state) {
          if (state is PayslipDownloadSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mengunduh ${state.download.filename}...'),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Buka',
                  onPressed: () async {
                    final url = Uri.parse(state.download.downloadUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
            );
          } else if (state is PayslipDownloadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: BlocBuilder<PayslipDetailBloc, PayslipDetailState>(
          builder: (context, state) {
            if (state is PayslipDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PayslipDetailError) {
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
                      'Gagal memuat detail',
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
                        context.read<PayslipDetailBloc>().add(
                          GetPayslipDetail(widget.payslipId),
                        );
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }
            if (state is PayslipDetailLoaded) {
              return _buildContent(state.detail);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildContent(PayslipDetailModel detail) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(detail),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildEmployeeInfo(detail.employee),
                const SizedBox(height: 16),
                _buildSection(
                  'Pendapatan',
                  Icons.add_circle_outline,
                  AppColors.success,
                  detail.earnings,
                  detail.totalEarnings,
                  true,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Potongan',
                  Icons.remove_circle_outline,
                  AppColors.danger,
                  detail.deductions,
                  detail.totalDeductions,
                  false,
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(detail),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(PayslipDetailModel detail) {
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
                      'Detail Slip Gaji',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  BlocBuilder<PayslipDownloadBloc, PayslipDownloadState>(
                    builder: (context, state) {
                      if (state is PayslipDownloadLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                      return IconButton(
                        icon: const Icon(
                          Icons.download_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                        onPressed: _downloadPayslip,
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                children: [
                  Text(
                    detail.period,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Take Home Pay',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail.formattedNetSalary,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: detail.status == 'paid'
                                ? AppColors.success
                                : AppColors.warning,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                detail.status == 'paid'
                                    ? Icons.check_circle
                                    : Icons.schedule,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                detail.status == 'paid'
                                    ? 'Dibayar: ${_formatDate(detail.paymentDate)}'
                                    : 'Pending',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeInfo(EmployeeInfo employee) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                  Icons.person_rounded,
                  color: AppColors.primary600,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${employee.position} • ${employee.employeeId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Departemen', employee.department),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<dynamic> items,
    int total,
    bool isEarning,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              // const Spacer(),
              // Text(
              //   _formatCurrency(total),
              //   style: TextStyle(
              //     fontSize: 14,
              //     fontWeight: FontWeight.w700,
              //     color: color,
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            if (item is EarningItem) {
              return _buildAmountRow(
                item.name,
                item.formattedAmount,
                isEarning,
              );
            } else if (item is DeductionItem) {
              return _buildAmountRow(
                item.name,
                item.formattedAmount,
                isEarning,
              );
            }
            return const SizedBox();
          }),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount, bool isEarning) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isEarning ? '+' : '-'} $amount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isEarning ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(PayslipDetailModel detail) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Gaji Pokok',
            detail.formattedBaseSalary,
            AppColors.textPrimary,
          ),
          _buildSummaryRow(
            'Total Pendapatan',
            detail.formattedTotalEarnings,
            AppColors.success,
          ),
          _buildSummaryRow(
            'Total Potongan',
            detail.formattedTotalDeductions,
            AppColors.danger,
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Take Home Pay',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                detail.formattedNetSalary,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.info,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Metode Pembayaran: ${detail.paymentMethod}',
                    style: const TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
