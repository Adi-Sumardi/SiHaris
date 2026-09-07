import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:gaji_pro/data/models/requests/leave_request_model.dart';
import 'package:gaji_pro/data/models/responses/leave_type_model.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_crud/leave_crud_bloc.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_types/leave_types_bloc.dart';
import '../../../../core/constants/colors.dart';

/// Backend's `attachment` validation rule (LeaveController::store):
/// `mimes:jpg,jpeg,png,pdf|max:10240` (10240 KB = 10 MB).
const int _kMaxAttachmentBytes = 10 * 1024 * 1024;

class LeaveFormScreen extends StatefulWidget {
  const LeaveFormScreen({super.key});

  @override
  State<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  final _formKey = GlobalKey<FormState>();

  LeaveTypeModel? _selectedLeaveType;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  File? _attachment;
  String? _attachmentName;

  bool _isHalfDay = false;
  String? _halfDayType;

  @override
  void initState() {
    super.initState();
    context.read<LeaveTypesBloc>().add(GetLeaveTypes());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _emergencyContactController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? today)
          : (_endDate ?? _startDate ?? today),
      firstDate: isStartDate ? today : (_startDate ?? today),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
            _endDateController.clear();
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> _setAttachment(File file, String name) async {
    final size = await file.length();
    if (size > _kMaxAttachmentBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ukuran file maksimal 10MB'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _attachment = file;
      _attachmentName = name;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _setAttachment(File(image.path), image.name);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      await _setAttachment(File(path), result.files.single.name);
    }
  }

  void _pickFile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Pilih File PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPdf();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedLeaveType == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pilih jenis cuti')));
        return;
      }
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih tanggal mulai dan selesai')),
        );
        return;
      }
      final today = DateUtils.dateOnly(DateTime.now());
      if (_startDate!.isBefore(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal mulai tidak boleh sebelum hari ini'),
          ),
        );
        return;
      }
      if (_isHalfDay && _halfDayType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih waktu setengah hari')),
        );
        return;
      }

      final request = LeaveRequestModel(
        leaveTypeId: _selectedLeaveType!.id,
        startDate: _startDateController.text,
        endDate: _isHalfDay
            ? _startDateController.text
            : _endDateController.text,
        isHalfDay: _isHalfDay,
        halfDayType: _isHalfDay ? _halfDayType : null,
        reason: _reasonController.text,
        emergencyContact: _emergencyContactController.text.isEmpty
            ? null
            : _emergencyContactController.text,
        attachment: _attachment,
      );

      context.read<LeaveCrudBloc>().add(CreateLeave(request));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Ajukan Cuti'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<LeaveCrudBloc, LeaveCrudState>(
        listener: (context, state) {
          if (state is LeaveCrudLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );
          }
          if (state is LeaveCrudSuccess) {
            Navigator.pop(context); // Close loading dialog
            Navigator.pop(context); // Close screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
          if (state is LeaveCrudFailure) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Jenis Cuti'),
                BlocBuilder<LeaveTypesBloc, LeaveTypesState>(
                  builder: (context, state) {
                    if (state is LeaveTypesLoading) {
                      return const LinearProgressIndicator();
                    }
                    if (state is LeaveTypesLoaded) {
                      return DropdownButtonFormField<LeaveTypeModel>(
                        decoration: const InputDecoration(
                          hintText: 'Pilih Jenis Cuti',
                          border: OutlineInputBorder(),
                        ),
                        items: state.types.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLeaveType = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Wajib diisi' : null,
                      );
                    }
                    return const Text('Gagal memuat jenis cuti');
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Tanggal Mulai'),
                          TextFormField(
                            controller: _startDateController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'YYYY-MM-DD',
                              suffixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            onTap: () => _selectDate(context, true),
                            validator: (value) =>
                                value!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Tanggal Selesai'),
                          TextFormField(
                            controller: _isHalfDay
                                ? _startDateController
                                : _endDateController,
                            readOnly: true,
                            enabled: !_isHalfDay,
                            decoration: const InputDecoration(
                              hintText: 'YYYY-MM-DD',
                              suffixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            onTap: _isHalfDay
                                ? null
                                : () => _selectDate(context, false),
                            validator: (value) =>
                                value!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                CheckboxListTile(
                  value: _isHalfDay,
                  onChanged: (value) {
                    setState(() {
                      _isHalfDay = value ?? false;
                      if (!_isHalfDay) {
                        _halfDayType = null;
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Setengah Hari',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Centang jika hanya mengambil cuti setengah hari.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                if (_isHalfDay) ...[
                  const SizedBox(height: 4),
                  _buildLabel('Tipe Setengah Hari'),
                  DropdownButtonFormField<String>(
                    initialValue: _halfDayType,
                    decoration: const InputDecoration(
                      hintText: 'Pilih Waktu',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'morning',
                        child: Text('Pagi (08:00 - 12:00)'),
                      ),
                      DropdownMenuItem(
                        value: 'afternoon',
                        child: Text('Siang (13:00 - 17:00)'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _halfDayType = value;
                      });
                    },
                    validator: (value) =>
                        _isHalfDay && value == null ? 'Wajib diisi' : null,
                  ),
                ],
                const SizedBox(height: 16),

                _buildLabel('Alasan Cuti'),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan alasan pengajuan cuti',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                _buildLabel('Kontak Darurat (Opsional)'),
                TextFormField(
                  controller: _emergencyContactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Nomor yang bisa dihubungi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                _buildLabel('Lampiran (Opsional)'),
                InkWell(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_file,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _attachmentName ??
                                'Upload Dokumen Pendukung (JPG, PNG, PDF)',
                            style: TextStyle(
                              color: _attachment != null
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ajukan Cuti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
