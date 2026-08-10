import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/components/widgets.dart';
import '../../../data/models/requests/leave_request_model.dart';
import '../../../data/models/responses/leave_type_model.dart';
import '../../../data/models/responses/leave_balance_model.dart';
import '../bloc/leave_types/leave_types_bloc.dart';
import '../bloc/leave_balance/leave_balance_bloc.dart';
import '../bloc/leave_crud/leave_crud_bloc.dart';

/// Leave Request Screen with 8-point grid system
/// Spacing: 4, 8, 12, 16, 24, 32 px
/// Font sizes: 10, 12, 14, 16, 20, 24 px
/// Icon sizes: 16, 20, 24, 40 px
/// Container sizes: 72 px
/// Border radius: 4, 8, 12, 16, 24 px
class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  LeaveTypeModel? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  bool _isHalfDay = false;
  File? _attachment;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<LeaveTypesBloc>().add(GetLeaveTypes());
    context.read<LeaveBalanceBloc>().add(GetLeaveBalance());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;
    if (_isHalfDay) return 1;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double _getRemainingDays(int leaveTypeId, List<LeaveBalanceModel> balances) {
    final balance = balances.firstWhere(
      (b) => b.leaveTypeId == leaveTypeId,
      orElse: () => const LeaveBalanceModel(
        leaveTypeId: 0,
        leaveTypeName: '',
        year: 0,
        entitledDays: 0,
        usedDays: 0,
        pendingDays: 0,
        remainingDays: 0,
      ),
    );
    return balance.remainingDays;
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedLeaveType == null) {
        _showError('Pilih jenis cuti');
        return;
      }
      if (_startDate == null || _endDate == null) {
        _showError('Pilih tanggal cuti');
        return;
      }

      final dateFormat = DateFormat('yyyy-MM-dd');
      final request = LeaveRequestModel(
        leaveTypeId: _selectedLeaveType!.id,
        startDate: dateFormat.format(_startDate!),
        endDate: dateFormat.format(_endDate!),
        isHalfDay: _isHalfDay,
        halfDayType: _isHalfDay ? 'morning' : null,
        reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
        attachment: _attachment,
      );

      context.read<LeaveCrudBloc>().add(CreateLeave(request));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pengajuan Berhasil!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pengajuan cuti Anda telah dikirim dan menunggu persetujuan atasan.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              JagoButton(
                text: 'Kembali',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _attachment = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaveCrudBloc, LeaveCrudState>(
      listener: (context, state) {
        if (state is LeaveCrudSuccess) {
          _showSuccessDialog();
        } else if (state is LeaveCrudFailure) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: const JagoAppBar(
          title: 'Ajukan Cuti',
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Leave type selector
              _buildLeaveTypeSelector(),
              const SizedBox(height: 24),
              // Date selection
              _buildDateSelection(),
              const SizedBox(height: 24),
              // Half day option
              _buildHalfDayOption(),
              const SizedBox(height: 24),
              // Reason
              JagoTextField(
                label: 'Alasan Cuti',
                hint: 'Masukkan alasan pengajuan cuti',
                controller: _reasonController,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alasan cuti tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Attachment
              _buildAttachmentSection(),
              const SizedBox(height: 24),
              // Summary
              if (_selectedLeaveType != null &&
                  _startDate != null &&
                  _endDate != null)
                _buildSummary(),
              const SizedBox(height: 32),
              // Submit button
              BlocBuilder<LeaveCrudBloc, LeaveCrudState>(
                builder: (context, state) {
                  return JagoButton(
                    text: 'Ajukan Cuti',
                    onPressed: _handleSubmit,
                    isLoading: state is LeaveCrudLoading,
                    leadingIcon: Icons.send_rounded,
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Cuti',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<LeaveTypesBloc, LeaveTypesState>(
          builder: (context, typesState) {
            if (typesState is LeaveTypesLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (typesState is LeaveTypesError) {
              return JagoCard(
                child: Column(
                  children: [
                    Text(
                      typesState.message,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            if (typesState is LeaveTypesLoaded) {
              final types = typesState.types;

              return BlocBuilder<LeaveBalanceBloc, LeaveBalanceState>(
                builder: (context, balanceState) {
                  List<LeaveBalanceModel> balances = [];
                  if (balanceState is LeaveBalanceLoaded) {
                    balances = balanceState.balances;
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: types.map((type) {
                      final isSelected = _selectedLeaveType?.id == type.id;
                      final remaining = _getRemainingDays(type.id, balances);

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedLeaveType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary600
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary600
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                type.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.textOnPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.textOnPrimary
                                          .withValues(alpha: 0.2)
                                      : AppColors.secondary100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  remaining.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.textOnPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal Cuti',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                'Mulai',
                _startDate,
                (date) => setState(() {
                  _startDate = date;
                  if (_endDate != null && _endDate!.isBefore(date)) {
                    _endDate = date;
                  }
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDatePicker(
                'Selesai',
                _endDate,
                (date) => setState(() => _endDate = date),
                minDate: _startDate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onChanged, {
    DateTime? minDate,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: minDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary600,
                  onPrimary: AppColors.textOnPrimary,
                  surface: AppColors.surface,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          onChanged(date);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value != null ? _formatDate(value) : 'Pilih tanggal',
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
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

  Widget _buildHalfDayOption() {
    return JagoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.timelapse_rounded,
            color: AppColors.primary600,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuti Setengah Hari',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pilih jika hanya mengambil setengah hari',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isHalfDay,
            onChanged: (value) => setState(() => _isHalfDay = value),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Lampiran',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (_selectedLeaveType?.requiresAttachment == true) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Wajib',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ] else ...[
              const Text(
                ' (Opsional)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (_attachment != null)
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_attachment!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _attachment = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _pickAttachment,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: AppColors.secondary400,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Upload Dokumen',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Surat dokter, undangan, dll (Max 5MB)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummary() {
    return BlocBuilder<LeaveBalanceBloc, LeaveBalanceState>(
      builder: (context, state) {
        double remaining = 0;
        if (state is LeaveBalanceLoaded && _selectedLeaveType != null) {
          remaining =
              _getRemainingDays(_selectedLeaveType!.id, state.balances);
        }

        final daysToDeduct = _isHalfDay ? 0.5 : _totalDays.toDouble();
        final remainingAfter = remaining - daysToDeduct;

        return JagoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ringkasan Pengajuan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Jenis Cuti', _selectedLeaveType!.name),
              _buildSummaryRow('Tanggal',
                  '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'),
              _buildSummaryRow(
                  'Jumlah Hari', _isHalfDay ? '0.5 Hari' : '$_totalDays Hari'),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sisa Cuti Setelah Pengajuan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${remainingAfter.toStringAsFixed(remainingAfter % 1 == 0 ? 0 : 1)} Hari',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: remainingAfter < 0
                          ? AppColors.danger
                          : AppColors.primary600,
                    ),
                  ),
                ],
              ),
              if (remainingAfter < 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.danger,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Saldo cuti tidak mencukupi',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dateFormat = DateFormat('d MMM yyyy', 'id_ID');
    return dateFormat.format(date);
  }
}
