import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/core/constants/colors.dart';
import 'package:gaji_pro/data/models/requests/upload_document_request_model.dart';
import 'package:gaji_pro/presentation/document/bloc/document_upload/document_upload_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedType = 'sk';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _issueDate;
  DateTime? _expiryDate;

  File? _selectedFile;
  String? _selectedFileName;
  int? _selectedFileSize;
  bool _isPdf = false;

  final ImagePicker _imagePicker = ImagePicker();

  final List<Map<String, dynamic>> _documentTypeOptions = [
    {
      'type': 'sk',
      'label': 'SK / Surat Keputusan',
      'desc': 'SK Pengangkatan, Mengajar, Mutasi, dll',
      'icon': Icons.description_outlined,
      'color': const Color(0xFF4F46E5),
    },
    {
      'type': 'sertifikat',
      'label': 'Sertifikat & Pelatihan',
      'desc': 'Sertifikasi Pendidik, Diklat, Seminar, dll',
      'icon': Icons.workspace_premium_outlined,
      'color': const Color(0xFFD97706),
    },
    {
      'type': 'ktp',
      'label': 'KTP',
      'desc': 'Kartu Tanda Penduduk',
      'icon': Icons.badge_outlined,
      'color': const Color(0xFF2563EB),
    },
    {
      'type': 'kk',
      'label': 'Kartu Keluarga (KK)',
      'desc': 'Kartu Keluarga untuk data tanggungan',
      'icon': Icons.groups_outlined,
      'color': const Color(0xFF059669),
    },
    {
      'type': 'ijazah',
      'label': 'Ijazah & Transkrip',
      'desc': 'Ijazah S1/S2/SMA & Transkrip Nilai',
      'icon': Icons.school_outlined,
      'color': const Color(0xFF7C3AED),
    },
    {
      'type': 'npwp',
      'label': 'NPWP',
      'desc': 'Kartu NPWP / Bukti NIK-NPWP',
      'icon': Icons.credit_card_outlined,
      'color': const Color(0xFF0D9488),
    },
    {
      'type': 'bpjs_kesehatan',
      'label': 'BPJS Kesehatan',
      'desc': 'Kartu KIS / BPJS Kesehatan Digital',
      'icon': Icons.health_and_safety_outlined,
      'color': const Color(0xFF0284C7),
    },
    {
      'type': 'bpjs_ketenagakerjaan',
      'label': 'BPJS Ketenagakerjaan',
      'desc': 'Kartu Peserta BPJS Ketenagakerjaan (KPJ)',
      'icon': Icons.security_outlined,
      'color': const Color(0xFF0284C7),
    },
    {
      'type': 'kontrak_kerja',
      'label': 'Kontrak Kerja / PKWT',
      'desc': 'Surat Perjanjian Kerja Waktu Tertentu',
      'icon': Icons.article_outlined,
      'color': const Color(0xFFEA580C),
    },
    {
      'type': 'other',
      'label': 'Dokumen Lainnya',
      'desc': 'Surat Keterangan Sehat, Rekening, dll',
      'icon': Icons.folder_outlined,
      'color': const Color(0xFF64748B),
    },
  ];

  @override
  void initState() {
    super.initState();
    context.read<DocumentUploadBloc>().add(ResetUploadDocument());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (photo != null) {
        final file = File(photo.path);
        final size = await file.length();
        setState(() {
          _selectedFile = file;
          _selectedFileName = photo.name;
          _selectedFileSize = size;
          _isPdf = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil foto dari kamera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image != null) {
        final file = File(image.path);
        final size = await file.length();
        setState(() {
          _selectedFile = file;
          _selectedFileName = image.name;
          _selectedFileSize = size;
          _isPdf = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih foto dari galeri: $e');
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final size = await file.length();
        setState(() {
          _selectedFile = file;
          _selectedFileName = result.files.single.name;
          _selectedFileSize = size;
          _isPdf = true;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih file PDF: $e');
    }
  }

  void _showFileSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber File Dokumen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Format yang didukung: PDF, JPG, JPEG, PNG (Maks 10MB)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF4F46E5)),
                ),
                title: const Text('Ambil Foto Kamera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Foto langsung dokumen fisik (KTP, KK, SK)', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Color(0xFF16A34A)),
                ),
                title: const Text('Pilih dari Galeri Foto', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Unggah gambar atau screenshot', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFDC2626)),
                ),
                title: const Text('Pilih Dokumen PDF', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('File dokumen PDF dari memori perangkat', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPdfFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentTypeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pilih Jenis Dokumen',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _documentTypeOptions.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final opt = _documentTypeOptions[index];
                  final isSelected = _selectedType == opt['type'];
                  final Color optColor = opt['color'];

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedType = opt['type'];
                        // Auto-fill document name if empty
                        if (_nameController.text.isEmpty) {
                          _nameController.text = opt['label'];
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: optColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(opt['icon'] as IconData, color: optColor, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt['label'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? AppColors.primary600 : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt['desc'] as String,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary600, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isIssueDate) async {
    final now = DateTime.now();
    final initialDate = isIssueDate ? (_issueDate ?? now) : (_expiryDate ?? now.add(const Duration(days: 365)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1980),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      _showErrorSnackBar('Harap pilih file dokumen terlebih dahulu');
      return;
    }

    final request = UploadDocumentRequestModel(
      documentType: _selectedType,
      documentName: _nameController.text.trim(),
      documentNumber: _numberController.text.trim().isNotEmpty ? _numberController.text.trim() : null,
      issueDate: _issueDate != null ? DateFormat('yyyy-MM-dd').format(_issueDate!) : null,
      expiryDate: _expiryDate != null ? DateFormat('yyyy-MM-dd').format(_expiryDate!) : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    context.read<DocumentUploadBloc>().add(UploadDocument(
      request: request,
      file: _selectedFile!,
    ));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = _documentTypeOptions.firstWhere(
      (opt) => opt['type'] == _selectedType,
      orElse: () => _documentTypeOptions.first,
    );
    final Color selectedColor = selectedOption['color'];

    return BlocListener<DocumentUploadBloc, DocumentUploadState>(
      listener: (context, state) {
        if (state is DocumentUploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berkas berhasil disimpan ke arsip digital'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is DocumentUploadError) {
          _showErrorSnackBar(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Unggah Berkas Pegawai',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Section 1: Document Type Selector Card
              const Text(
                'Jenis Berkas',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showDocumentTypeSelector,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selectedColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(selectedOption['icon'] as IconData, color: selectedColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedOption['label'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedOption['desc'] as String,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Document Details
              const Text(
                'Informasi Dokumen',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document Name (Required)
                    const Text('Nama / Judul Berkas *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama dokumen wajib diisi';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Contoh: SK Guru Tetap Yayasan 2026',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Document Number (Optional)
                    const Text('Nomor Dokumen (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _numberController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 800/123/YAPI/2026 atau NIK',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Dates (Issue Date & Expiry Date)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tanggal Terbit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _pickDate(true),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textTertiary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _issueDate != null ? DateFormat('d MMM yyyy', 'id_ID').format(_issueDate!) : 'Pilih',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: _issueDate != null ? AppColors.textPrimary : AppColors.textTertiary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Masa Berlaku', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _pickDate(false),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_busy_outlined, size: 16, color: AppColors.textTertiary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _expiryDate != null ? DateFormat('d MMM yyyy', 'id_ID').format(_expiryDate!) : 'Pilih',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: _expiryDate != null ? AppColors.textPrimary : AppColors.textTertiary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Notes (Optional)
                    const Text('Catatan / Keterangan (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Keterangan tambahan...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 3: File Attachment
              const Text(
                'File Dokumen *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),

              if (_selectedFile == null)
                InkWell(
                  onTap: _showFileSourcePicker,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary300,
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 28,
                            color: AppColors.primary600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Pilih atau Foto File Dokumen',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kamera, Galeri Gambar, atau File PDF (Maks. 10 MB)',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      // Thumbnail / File Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _isPdf ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isPdf ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                            color: _isPdf ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // File info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFileName ?? 'file_dokumen',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _selectedFileSize != null ? _formatFileSize(_selectedFileSize!) : '',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),

                      // Change & Remove actions
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary600),
                        onPressed: _showFileSourcePicker,
                        tooltip: 'Ganti File',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.danger),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _selectedFileName = null;
                            _selectedFileSize = null;
                          });
                        },
                        tooltip: 'Hapus File',
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Submit Button
              BlocBuilder<DocumentUploadBloc, DocumentUploadState>(
                builder: (context, state) {
                  final isLoading = state is DocumentUploadLoading;

                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Simpan & Unggah Berkas',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
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
}
