import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/requests/reimbursement_request_model.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ReimbursementRequestModel', () {
    const tRequestModel = ReimbursementRequestModel(
      categoryId: 1,
      amount: 150000,
      description: 'Taxi to client meeting',
      expenseDate: '2026-02-15',
    );

    test('should convert to JSON for API request', () {
      final result = tRequestModel.toJson();

      expect(result, {
        'category_id': 1,
        'amount': 150000,
        'description': 'Taxi to client meeting',
        'expense_date': '2026-02-15',
      });
    });

    test('should create multipart request without file', () async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://test.com'),
      );
      tRequestModel.addToMultipartRequest(request, null);

      expect(request.fields['category_id'], '1');
      expect(request.fields['amount'], '150000');
      expect(request.fields['description'], 'Taxi to client meeting');
      expect(request.fields['expense_date'], '2026-02-15');
      expect(request.files, isEmpty);
    });
  });
}
