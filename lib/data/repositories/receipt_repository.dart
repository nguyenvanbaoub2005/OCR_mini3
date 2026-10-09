import 'package:sqflite/sqflite.dart';
import '../../core/services/receipt_image_storage_service.dart';
import '../database/app_database.dart';
import '../models/receipt_model.dart';

/// Repository quản lý truy xuất và thao tác dữ liệu hóa đơn (Data Layer)
/// Tách rời hoàn toàn giao diện UI khỏi các câu lệnh SQL
class ReceiptRepository {
  final AppDatabase _dbProvider;

  ReceiptRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  /// Thêm hóa đơn mới vào cơ sở dữ liệu
  Future<int> insertReceipt(ReceiptModel receipt) async {
    final db = await _dbProvider.database;
    final id = await db.insert(
      AppDatabase.tableReceipts,
      receipt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  /// Lấy danh sách toàn bộ hóa đơn, sắp xếp theo ngày giao dịch giảm dần (mới nhất lên đầu)
  Future<List<ReceiptModel>> getAllReceipts() async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppDatabase.tableReceipts,
      orderBy: 'date DESC, createdAt DESC',
    );

    return List.generate(maps.length, (i) => ReceiptModel.fromMap(maps[i]));
  }

  /// Lấy chi tiết một hóa đơn theo ID
  Future<ReceiptModel?> getReceiptById(int id) async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppDatabase.tableReceipts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ReceiptModel.fromMap(maps.first);
    }
    return null;
  }

  /// Cập nhật thông tin hóa đơn đã có
  Future<int> updateReceipt(ReceiptModel receipt) async {
    final db = await _dbProvider.database;
    return await db.update(
      AppDatabase.tableReceipts,
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  /// Xóa hóa đơn: Xóa bản ghi trong Database và đồng thời xóa file ảnh tương ứng (theo Mục 16)
  Future<int> deleteReceipt(int id) async {
    final db = await _dbProvider.database;

    // Lấy thông tin hóa đơn trước khi xóa để biết đường dẫn ảnh
    final receipt = await getReceiptById(id);
    if (receipt != null && receipt.imagePath.isNotEmpty) {
      await ReceiptImageStorageService.deleteImage(receipt.imagePath);
    }

    return await db.delete(
      AppDatabase.tableReceipts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Tính tổng chi tiêu trong tháng hiện tại
  Future<double> getTotalThisMonth({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final db = await _dbProvider.database;
    final result = await db.rawQuery('''
      SELECT SUM(total) as sumTotal FROM ${AppDatabase.tableReceipts}
      WHERE date >= ? AND date <= ?
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    final sum = result.first['sumTotal'];
    return (sum as num?)?.toDouble() ?? 0.0;
  }

  /// Tính tổng chi tiêu trong tuần hiện tại (7 ngày gần nhất)
  Future<double> getTotalThisWeek({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();
    // Đầu tuần (Thứ 2)
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final endOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6, 23, 59, 59);

    final db = await _dbProvider.database;
    final result = await db.rawQuery('''
      SELECT SUM(total) as sumTotal FROM ${AppDatabase.tableReceipts}
      WHERE date >= ? AND date <= ?
    ''', [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()]);

    final sum = result.first['sumTotal'];
    return (sum as num?)?.toDouble() ?? 0.0;
  }

  /// Thống kê tổng tiền theo từng danh mục chi tiêu
  Future<Map<String, double>> getTotalsByCategory() async {
    final db = await _dbProvider.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT category, SUM(total) as categoryTotal
      FROM ${AppDatabase.tableReceipts}
      GROUP BY category
    ''');

    final Map<String, double> totals = {};
    for (final row in result) {
      final category = row['category'] as String;
      final total = (row['categoryTotal'] as num).toDouble();
      totals[category] = total;
    }
    return totals;
  }

  /// Xóa toàn bộ hóa đơn trong database
  Future<int> clearAllReceipts() async {
    final db = await _dbProvider.database;
    return await db.delete(AppDatabase.tableReceipts);
  }

  /// Khôi phục lại 4 hóa đơn demo mẫu ban đầu
  Future<void> resetDemoData() async {
    final db = await _dbProvider.database;
    await db.delete(AppDatabase.tableReceipts);
    await _dbProvider.seedInitialData(db);
  }
}
