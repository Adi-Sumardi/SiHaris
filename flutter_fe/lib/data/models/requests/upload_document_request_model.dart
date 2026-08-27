import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
        contentType: _contentTypeFor(filename),
      ),
    );
  }

  /// Server-side MIME sniffing (finfo) is the source of truth for validation,
  /// but a correct Content-Type header keeps this in sync with what the file
  /// actually is instead of always defaulting to application/octet-stream.
  MediaType _contentTypeFor(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    return switch (ext) {
      'pdf' => MediaType('application', 'pdf'),
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      _ => MediaType('application', 'octet-stream'),
    };
  }
}
