import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/components/widgets.dart';
import '../../../data/models/requests/reimbursement_request_model.dart';
import '../bloc/reimbursement_category/reimbursement_category_bloc.dart';
import '../bloc/reimbursement_request/reimbursement_request_bloc.dart';

class ReimbursementFormScreen extends StatefulWidget {
  const ReimbursementFormScreen({super.key});

  @override
  State<ReimbursementFormScreen> createState() =>
      _ReimbursementFormScreenState();
}

class _ReimbursementFormScreenState extends State<ReimbursementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  int? _selectedCategoryId;
  DateTime? _selectedDate;
  File? _receiptFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<ReimbursementCategoryBloc>().add(
      const LoadReimbursementCategories(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = DateFormat('d MMMM yyyy', 'id_ID').format(date);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _receiptFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal terlebih dahulu')),
      );
      return;
    }

    final amount = int.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jumlah tidak valid')));
      return;
    }

    final request = ReimbursementRequestModel(
      categoryId: _selectedCategoryId!,
      amount: amount,
      description: _descriptionController.text,
      expenseDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
    );

    context.read<ReimbursementRequestBloc>().add(
      SubmitReimbursementRequest(request, _receiptFile),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const JagoAppBar(title: 'Ajukan Reimbursement'),
      body: BlocListener<ReimbursementRequestBloc, ReimbursementRequestState>(
        listener: (context, state) {
          if (state is ReimbursementRequestSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reimbursement berhasil diajukan'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is ReimbursementRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal mengajukan: ${state.message}'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category selection
                Text('Kategori', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                BlocBuilder<
                  ReimbursementCategoryBloc,
                  ReimbursementCategoryState
                >(
                  builder: (context, state) {
                    if (state is ReimbursementCategoryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ReimbursementCategoryLoaded) {
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: state.categories.map((category) {
                          final isSelected = _selectedCategoryId == category.id;
                          return ChoiceChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = selected
                                    ? category.id
                                    : null;
                              });
                            },
                            selectedColor: AppColors.primary600,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.textOnPrimary
                                  : AppColors.textPrimary,
                            ),
                          );
                        }).toList(),
                      );
                    }

                    return const Text('Gagal memuat kategori');
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                // Amount
                Text('Jumlah', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan jumlah',
                    prefixText: 'Rp ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah harus diisi';
                    }
                    final amount = int.tryParse(
                      value.replaceAll(RegExp(r'[^0-9]'), ''),
                    );
                    if (amount == null || amount <= 0) {
                      return 'Jumlah tidak valid';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Format as currency
                    final number = int.tryParse(
                      value.replaceAll(RegExp(r'[^0-9]'), ''),
                    );
                    if (number != null) {
                      final formatter = NumberFormat('#,###', 'id_ID');
                      final formatted = formatter.format(number);
                      _amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                // Date
                Text('Tanggal Pengeluaran', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Pilih tanggal',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: _pickDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tanggal harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                // Description
                Text('Deskripsi', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan keperluan pengeluaran',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deskripsi harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                // Receipt upload
                Text('Bukti Pembayaran', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                if (_receiptFile != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppSpacing.borderRadiusMd,
                        child: Image.file(
                          _receiptFile!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _receiptFile = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  InkWell(
                    onTap: _showImageSourceDialog,
                    borderRadius: AppSpacing.borderRadiusMd,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.border,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tambah Foto Bukti',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                // Submit button
                BlocBuilder<
                  ReimbursementRequestBloc,
                  ReimbursementRequestState
                >(
                  builder: (context, state) {
                    final isSubmitting =
                        state is ReimbursementRequestSubmitting;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submitForm,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textOnPrimary,
                                  ),
                                ),
                              )
                            : const Text('Ajukan Reimbursement'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
