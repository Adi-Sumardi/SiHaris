import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/unread_count_model.dart';

void main() {
  group('UnreadCountModel', () {
    const tJson = {'count': 5};

    const tUnreadCount = UnreadCountModel(count: 5);

    test('should create UnreadCountModel from JSON', () {
      final result = UnreadCountModel.fromJson(tJson);
      expect(result, equals(tUnreadCount));
    });

    test('should convert UnreadCountModel to JSON', () {
      final result = tUnreadCount.toJson();
      expect(result, equals(tJson));
    });

    test('should support zero count', () {
      const zeroJson = {'count': 0};
      final result = UnreadCountModel.fromJson(zeroJson);
      expect(result.count, equals(0));
    });
  });
}
