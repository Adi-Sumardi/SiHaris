import 'dart:io';
import 'package:http/http.dart' as http;

class UploadDocumentRequestModel {
  final String documentType;
  final String documentName;
  final String? documentNumber;
  final String? issueDate;
  final String? expiryDate;
  final String? notes;

  const UploadDocumentRequestModel({
    required this.documentType,
    required this.documentName,
    this.documentNumber,
    this.issueDate,
    this.expiryDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'document_type': documentType,
      'document_name': documentName,
      'document_number': documentNumber,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
      'notes': notes,
    };
  }

  void addToMultipartRequest(http.MultipartRequest request, File file) {
    request.fields['document_type'] = documentType;
    request.fields['document_name'] = documentName;
    if (documentNumber != null && documentNumber!.isNotEmpty) {
      request.fields['document_number'] = documentNumber!;
    }
    if (issueDate != null && issueDate!.isNotEmpty) {
      request.fields['issue_date'] = issueDate!;
    }
    if (expiryDate != null && expiryDate!.isNotEmpty) {
      request.fields['expiry_date'] = expiryDate!;
    }
    if (notes != null && notes!.isNotEmpty) {
      request.fields['notes'] = notes!;
    }

    final bytes = file.readAsBytesSync();
    final filename = file.path.split('/').last;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );
  }
}
