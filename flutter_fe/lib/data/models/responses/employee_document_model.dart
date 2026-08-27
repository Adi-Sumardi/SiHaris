import 'package:flutter/material.dart';

/// Model untuk Berkas/Dokumen Pegawai
class EmployeeDocumentModel {
  final int id;
  final String documentType;
  final String documentTypeLabel;
  final String documentName;
  final String? documentNumber;
  final String fileName;
  final int fileSize;
  final String humanFileSize;
  final String mimeType;
  final bool isImage;
  final bool isPdf;
  final String? fileUrl;
  final String? previewUrl;
  final String? downloadUrl;
  final String? issueDate;
  final String? expiryDate;
  final bool isExpired;
  final bool isExpiringSoon;
  final String? notes;
  final String? createdAt;

  const EmployeeDocumentModel({
    required this.id,
    required this.documentType,
    required this.documentTypeLabel,
    required this.documentName,
    this.documentNumber,
    required this.fileName,
    required this.fileSize,
    required this.humanFileSize,
    required this.mimeType,
    required this.isImage,
    required this.isPdf,
    this.fileUrl,
    this.previewUrl,
    this.downloadUrl,
    this.issueDate,
    this.expiryDate,
    this.isExpired = false,
    this.isExpiringSoon = false,
    this.notes,
    this.createdAt,
  });

  factory EmployeeDocumentModel.fromJson(Map<String, dynamic> json) {
    return EmployeeDocumentModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      documentType: json['document_type'] ?? 'other',
      documentTypeLabel: json['document_type_label'] ?? 'Dokumen',
      documentName: json['document_name'] ?? json['file_name'] ?? 'Dokumen',
      documentNumber: json['document_number'],
      fileName: json['file_name'] ?? 'dokumen',
      fileSize: json['file_size'] is int ? json['file_size'] : (json['file_size'] != null ? int.tryParse(json['file_size'].toString()) ?? 0 : 0),
      humanFileSize: json['human_file_size'] ?? '0 KB',
      mimeType: json['mime_type'] ?? 'application/octet-stream',
      isImage: json['is_image'] ?? false,
      isPdf: json['is_pdf'] ?? false,
      fileUrl: json['file_url'],
      previewUrl: json['preview_url'],
      downloadUrl: json['download_url'],
      issueDate: json['issue_date'],
      expiryDate: json['expiry_date'],
      isExpired: json['is_expired'] ?? false,
      isExpiringSoon: json['is_expiring_soon'] ?? false,
      notes: json['notes'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_type': documentType,
      'document_type_label': documentTypeLabel,
      'document_name': documentName,
      'document_number': documentNumber,
      'file_name': fileName,
      'file_size': fileSize,
      'human_file_size': humanFileSize,
      'mime_type': mimeType,
      'is_image': isImage,
      'is_pdf': isPdf,
      'file_url': fileUrl,
      'preview_url': previewUrl,
      'download_url': downloadUrl,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
      'is_expired': isExpired,
      'is_expiring_soon': isExpiringSoon,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  Color get categoryColor {
    switch (documentType) {
      case 'sk':
        return const Color(0xFF4F46E5); // Indigo
      case 'sertifikat':
        return const Color(0xFFD97706); // Amber
      case 'ktp':
        return const Color(0xFF2563EB); // Blue
      case 'kk':
        return const Color(0xFF059669); // Emerald
      case 'ijazah':
        return const Color(0xFF7C3AED); // Purple
      case 'npwp':
        return const Color(0xFF0D9488); // Teal
      case 'bpjs_kesehatan':
      case 'bpjs_ketenagakerjaan':
        return const Color(0xFF0284C7); // Cyan
      case 'kontrak_kerja':
        return const Color(0xFFEA580C); // Orange
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData get categoryIcon {
    switch (documentType) {
      case 'sk':
        return Icons.description_outlined;
      case 'sertifikat':
        return Icons.workspace_premium_outlined;
      case 'ktp':
        return Icons.badge_outlined;
      case 'kk':
        return Icons.groups_outlined;
      case 'ijazah':
        return Icons.school_outlined;
      case 'npwp':
        return Icons.credit_card_outlined;
      case 'bpjs_kesehatan':
        return Icons.health_and_safety_outlined;
      case 'bpjs_ketenagakerjaan':
        return Icons.security_outlined;
      case 'kontrak_kerja':
        return Icons.article_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}

/// Model untuk Referensi Jenis Dokumen
class DocumentTypeModel {
  final String type;
  final String label;
  final String icon;

  const DocumentTypeModel({
    required this.type,
    required this.label,
    required this.icon,
  });

  factory DocumentTypeModel.fromJson(Map<String, dynamic> json) {
    return DocumentTypeModel(
      type: json['type'],
      label: json['label'],
      icon: json['icon'] ?? 'folder',
    );
  }

  IconData get iconData {
    switch (type) {
      case 'sk':
        return Icons.description_outlined;
      case 'sertifikat':
        return Icons.workspace_premium_outlined;
      case 'ktp':
        return Icons.badge_outlined;
      case 'kk':
        return Icons.groups_outlined;
      case 'ijazah':
        return Icons.school_outlined;
      case 'npwp':
        return Icons.credit_card_outlined;
      case 'bpjs_kesehatan':
        return Icons.health_and_safety_outlined;
      case 'bpjs_ketenagakerjaan':
        return Icons.security_outlined;
      case 'kontrak_kerja':
        return Icons.article_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}
