import 'dart:io';
import 'package:http/http.dart' as http;

class ReimbursementRequestModel {
  final int categoryId;
  final int amount;
  final String description;
  final String expenseDate;

  const ReimbursementRequestModel({
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.expenseDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate,
    };
  }

  void addToMultipartRequest(http.MultipartRequest request, File? receiptFile) {
    request.fields['category_id'] = categoryId.toString();
    request.fields['amount'] = amount.toString();
    request.fields['description'] = description;
    request.fields['expense_date'] = expenseDate;

    if (receiptFile != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'receipt',
          receiptFile.readAsBytesSync(),
          filename: receiptFile.path.split('/').last,
        ),
      );
    }
  }
}
