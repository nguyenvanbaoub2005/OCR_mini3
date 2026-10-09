import 'package:flutter/material.dart';
import '../../data/models/receipt_model.dart';
import '../../data/repositories/receipt_repository.dart';

/// Controller quản lý trạng thái dữ liệu hóa đơn trong ứng dụng
/// Tuân thủ kiến trúc phân tầng:
/// UI ↓ Controller ↓ Repository ↓ Local Database (SQLite)
class ReceiptController extends ChangeNotifier {
  ReceiptController._internal();
  static final ReceiptController instance = ReceiptController._internal();

  final ReceiptRepository _repository = ReceiptRepository();

  List<ReceiptModel> _receipts = [];
  bool _isLoading = false;
  double _monthTotal = 0.0;
  double _weekTotal = 0.0;
  Map<String, double> _categoryTotals = {};

  List<ReceiptModel> get receipts => _receipts;
  bool get isLoading => _isLoading;
  double get monthTotal => _monthTotal;
  double get weekTotal => _weekTotal;
  Map<String, double> get categoryTotals => _categoryTotals;

  /// Tải toàn bộ hóa đơn và số liệu thống kê từ SQLite
  Future<void> loadReceipts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _receipts = await _repository.getAllReceipts();
      _monthTotal = await _repository.getTotalThisMonth();
      _weekTotal = await _repository.getTotalThisWeek();
      _categoryTotals = await _repository.getTotalsByCategory();
    } catch (e) {
      debugPrint('[ReceiptController] Lỗi khi tải hóa đơn: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm mới hóa đơn vào SQLite và cập nhật UI ngay lập tức
  Future<int> addReceipt(ReceiptModel receipt) async {
    try {
      final id = await _repository.insertReceipt(receipt);
      await loadReceipts();
      return id;
    } catch (e) {
      debugPrint('[ReceiptController] Lỗi khi thêm hóa đơn: $e');
      rethrow;
    }
  }

  /// Cập nhật hóa đơn
  Future<void> updateReceipt(ReceiptModel receipt) async {
    try {
      await _repository.updateReceipt(receipt);
      await loadReceipts();
    } catch (e) {
      debugPrint('[ReceiptController] Lỗi khi cập nhật hóa đơn: $e');
      rethrow;
    }
  }

  /// Xóa hóa đơn và file ảnh
  Future<void> deleteReceipt(int id) async {
    try {
      await _repository.deleteReceipt(id);
      await loadReceipts();
    } catch (e) {
      debugPrint('[ReceiptController] Lỗi khi xóa hóa đơn: $e');
      rethrow;
    }
  }

  /// Khôi phục dữ liệu mẫu ban đầu (phục vụ thuyết trình/chấm đồ án)
  Future<void> resetDemoData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.resetDemoData();
      await loadReceipts();
    } catch (e) {
      debugPrint('[ReceiptController] Lỗi khi reset dữ liệu mẫu: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa toàn bộ dữ liệu hóa đơn
  Future<void> clearAllReceipts() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.clearAllReceipts();
      await loadReceipts();
    } catch (e) {
      debugPrint('[ReceiptController] Lỗi khi xóa toàn bộ: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
