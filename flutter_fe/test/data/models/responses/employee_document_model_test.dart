import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/employee_document_model.dart';

void main() {
  group('EmployeeDocumentModel', () {
    const tDocumentJson = {
      'id': 1,
      'document_type': 'sk',
      'document_type_label': 'SK / Surat Keputusan',
      'document_name': 'SK Guru Tetap Yayasan 2026',
      'document_number': '800/10/YAPI/2026',
      'file_name': 'SK_Guru_2026.pdf',
      'file_size': 204800,
      'human_file_size': '200 KB',
      'mime_type': 'application/pdf',
      'is_image': false,
      'is_pdf': true,
      'file_url': 'https://siharis.yapinet.id/storage/documents/1/1/sk.pdf',
      'preview_url': 'https://siharis.yapinet.id/api/v1/documents/1/preview',
      'download_url': 'https://siharis.yapinet.id/api/v1/documents/1/download',
      'issue_date': '2026-01-10',
      'expiry_date': '2027-01-10',
      'is_expired': false,
      'is_expiring_soon': false,
      'notes': 'SK Mengajar Semester Genap',
      'created_at': '2026-08-27T08:00:00Z',
    };

    test('should parse from JSON correctly', () {
      final doc = EmployeeDocumentModel.fromJson(tDocumentJson);

      expect(doc.id, 1);
      expect(doc.documentType, 'sk');
      expect(doc.documentTypeLabel, 'SK / Surat Keputusan');
      expect(doc.documentName, 'SK Guru Tetap Yayasan 2026');
      expect(doc.documentNumber, '800/10/YAPI/2026');
      expect(doc.fileName, 'SK_Guru_2026.pdf');
      expect(doc.fileSize, 204800);
      expect(doc.humanFileSize, '200 KB');
      expect(doc.mimeType, 'application/pdf');
      expect(doc.isImage, false);
      expect(doc.isPdf, true);
      expect(doc.isExpired, false);
      expect(doc.notes, 'SK Mengajar Semester Genap');
    });

    test('should return correct category colors and icons', () {
      final skDoc = EmployeeDocumentModel.fromJson(tDocumentJson);
      expect(skDoc.categoryColor, const Color(0xFF4F46E5));
      expect(skDoc.categoryIcon, Icons.description_outlined);

      final ktpDoc = EmployeeDocumentModel.fromJson({
        ...tDocumentJson,
        'document_type': 'ktp',
        'document_type_label': 'KTP',
      });
      expect(ktpDoc.categoryColor, const Color(0xFF2563EB));
      expect(ktpDoc.categoryIcon, Icons.badge_outlined);

      final sertifikatDoc = EmployeeDocumentModel.fromJson({
        ...tDocumentJson,
        'document_type': 'sertifikat',
        'document_type_label': 'Sertifikat & Pelatihan',
      });
      expect(sertifikatDoc.categoryColor, const Color(0xFFD97706));
      expect(sertifikatDoc.categoryIcon, Icons.workspace_premium_outlined);
    });

    test('should serialize to JSON correctly', () {
      final doc = EmployeeDocumentModel.fromJson(tDocumentJson);
      final json = doc.toJson();

      expect(json['id'], 1);
      expect(json['document_type'], 'sk');
      expect(json['document_name'], 'SK Guru Tetap Yayasan 2026');
      expect(json['file_size'], 204800);
      expect(json['is_pdf'], true);
    });
  });

  group('DocumentTypeModel', () {
    const tTypeJson = {
      'type': 'sk',
      'label': 'SK / Surat Keputusan',
      'icon': 'description',
    };

    test('should parse from JSON and return iconData', () {
      final model = DocumentTypeModel.fromJson(tTypeJson);

      expect(model.type, 'sk');
      expect(model.label, 'SK / Surat Keputusan');
      expect(model.iconData, Icons.description_outlined);
    });
  });
}
