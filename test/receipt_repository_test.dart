import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_lens/data/database/app_database.dart';
import 'package:bill_lens/data/models/receipt_model.dart';
import 'package:bill_lens/data/repositories/receipt_repository.dart';

void main() {
  // Khởi tạo FFI cho SQLite trên môi trường test / desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ReceiptRepository repository;

  setUpAll(() async {
    repository = ReceiptRepository();
    // Đảm bảo database đã được tạo và seed dữ liệu ban đầu
    await AppDatabase.instance.database;
  });

  group('ReceiptRepository SQLite CRUD Tests', () {
    test('Thêm hóa đơn mới (Insert) và đọc lại theo ID (GetById)', () async {
      final newReceipt = ReceiptModel(
        merchant: 'HIGHLANDS COFFEE',
        total: 55000,
        date: DateTime(2026, 10, 5),
        category: 'Thực phẩm',
        imagePath: '',
        rawText: 'HIGHLANDS COFFEE\n05/10/2026\nFreeze Tra Xanh 55.000\nTOTAL 55.000 VND',
        note: 'Gặp gỡ bạn bè',
        createdAt: DateTime.now(),
      );

      final insertedId = await repository.insertReceipt(newReceipt);
      expect(insertedId, isPositive);

      final fetched = await repository.getReceiptById(insertedId);
      expect(fetched, isNotNull);
      expect(fetched!.merchant, equals('HIGHLANDS COFFEE'));
      expect(fetched.total, equals(55000.0));
      expect(fetched.category, equals('Thực phẩm'));
      expect(fetched.note, equals('Gặp gỡ bạn bè'));
    });

    test('Lấy toàn bộ danh sách hóa đơn (GetAll)', () async {
      final all = await repository.getAllReceipts();
      expect(all, isNotEmpty);
      // Danh sách được sắp xếp giảm dần theo ngày
      if (all.length >= 2) {
        expect(all.first.date.isAfter(all.last.date) || all.first.date.isAtSameMomentAs(all.last.date), isTrue);
      }
    });

    test('Cập nhật hóa đơn (Update)', () async {
      final all = await repository.getAllReceipts();
      final target = all.first;

      final updated = target.copyWith(
        merchant: 'WINMART PLUS GIA HUNG',
        total: 165000,
      );

      final count = await repository.updateReceipt(updated);
      expect(count, equals(1));

      final check = await repository.getReceiptById(target.id!);
      expect(check!.merchant, equals('WINMART PLUS GIA HUNG'));
      expect(check.total, equals(165000.0));
    });

    test('Xóa hóa đơn (Delete)', () async {
      final testReceipt = ReceiptModel(
        merchant: 'TEST STORE TO DELETE',
        total: 20000,
        date: DateTime(2026, 10, 6),
        category: 'Khác',
        imagePath: '',
        rawText: 'TEST STORE\nTOTAL 20000',
        createdAt: DateTime.now(),
      );

      final id = await repository.insertReceipt(testReceipt);
      expect(id, isPositive);

      final deleteCount = await repository.deleteReceipt(id);
      expect(deleteCount, equals(1));

      final check = await repository.getReceiptById(id);
      expect(check, isNull);
    });

    test('Thống kê chi tiêu theo danh mục (GetTotalsByCategory)', () async {
      final categoryTotals = await repository.getTotalsByCategory();
      expect(categoryTotals, isNotNull);
      expect(categoryTotals.isNotEmpty, isTrue);
    });
  });
}
