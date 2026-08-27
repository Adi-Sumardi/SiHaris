import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/core/constants/colors.dart';
import 'package:gaji_pro/data/datasources/auth_local_datasource.dart';
import 'package:gaji_pro/data/models/responses/employee_document_model.dart';
import 'package:gaji_pro/presentation/document/bloc/document_action/document_action_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentDetailScreen extends StatefulWidget {
  final EmployeeDocumentModel document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await AuthLocalDatasource().getToken();
    if (mounted) {
      setState(() {
        _authToken = token;
      });
    }
  }

  Future<void> _openOrDownloadFile() async {
    final urlStr = widget.document.downloadUrl ?? widget.document.fileUrl;
    if (urlStr == null || urlStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL file tidak tersedia')),
      );
      return;
    }

    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka file: $e')),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Berkas?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus berkas "${widget.document.documentName}"? File yang dihapus tidak dapat dikembalikan.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<DocumentActionBloc>().add(DeleteDocumentEvent(widget.document.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final categoryColor = doc.categoryColor;

    String formattedCreatedDate = '-';
    if (doc.createdAt != null) {
      try {
        final dt = DateTime.parse(doc.createdAt!).toLocal();
        formattedCreatedDate = '${DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(dt)} WIB';
      } catch (_) {
        formattedCreatedDate = doc.createdAt!;
      }
    }

    String formattedIssueDate = doc.issueDate ?? '-';
    if (doc.issueDate != null) {
      try {
        final dt = DateTime.parse(doc.issueDate!);
        formattedIssueDate = DateFormat('d MMMM yyyy', 'id_ID').format(dt);
      } catch (_) {}
    }

    String formattedExpiryDate = doc.expiryDate ?? '-';
    if (doc.expiryDate != null) {
      try {
        final dt = DateTime.parse(doc.expiryDate!);
        formattedExpiryDate = DateFormat('d MMMM yyyy', 'id_ID').format(dt);
      } catch (_) {}
    }

    return BlocListener<DocumentActionBloc, DocumentActionState>(
      listener: (context, state) {
        if (state is DocumentActionDeleteSuccess) {
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Detail Berkas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              tooltip: 'Hapus Berkas',
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: categoryColor.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(doc.categoryIcon, size: 14, color: categoryColor),
                            const SizedBox(width: 6),
                            Text(
                              doc.documentTypeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: categoryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: doc.isPdf ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          doc.isPdf ? 'DOKUMEN PDF' : 'GAMBAR FOTO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: doc.isPdf ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    doc.documentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (doc.documentNumber != null && doc.documentNumber!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'No. Dokumen: ${doc.documentNumber}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // In-App Preview Section
            const Text(
              'Pratinjau Berkas',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),

            if (doc.isImage && doc.previewUrl != null)
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  maxScale: 4.0,
                  minScale: 0.8,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: doc.previewUrl!,
                      httpHeaders: _authToken != null ? {'Authorization': 'Bearer $_authToken'} : null,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image_rounded, size: 40, color: Colors.white54),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal memuat gambar ($error)',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: doc.isPdf ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        doc.isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                        size: 34,
                        color: doc.isPdf ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      doc.fileName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doc.humanFileSize} • ${doc.mimeType}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openOrDownloadFile,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(doc.isPdf ? 'Buka Dokumen PDF' : 'Buka / Unduh File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Metadata Detail Table Card
            const Text(
              'Informasi Metadata',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildMetaRow('Nama File Asli', doc.fileName),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildMetaRow('Ukuran File', doc.humanFileSize),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildMetaRow('Format File', doc.mimeType),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildMetaRow('Tanggal Terbit', formattedIssueDate),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildMetaRow(
                    'Masa Berlaku',
                    formattedExpiryDate,
                    trailingWidget: doc.isExpired
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Kadaluarsa',
                              style: TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        : null,
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildMetaRow('Waktu Diunggah', formattedCreatedDate),
                  if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                    const Divider(height: 16, color: Color(0xFFF1F5F9)),
                    _buildMetaRow('Catatan', doc.notes!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openOrDownloadFile,
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text(
                  'Unduh / Buka Dokumen Asli',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {Widget? trailingWidget}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
        if (trailingWidget != null) ...[
          const SizedBox(width: 8),
          trailingWidget,
        ],
      ],
    );
  }
}
