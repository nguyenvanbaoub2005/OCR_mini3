import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service quản lý lưu trữ và xử lý file ảnh hóa đơn cục bộ (Local Image Storage)
/// Theo đúng yêu cầu kiến trúc Mục 14:
/// - Ảnh hóa đơn được lưu vào thư mục documents của ứng dụng (documents/receipts/...)
/// - Database chỉ lưu đường dẫn `imagePath`, không lưu binary lớn
class ReceiptImageStorageService {
  ReceiptImageStorageService._();

  static const String _receiptsFolder = 'receipts';

  /// Lấy thư mục lưu ảnh hóa đơn: [app_documents]/receipts/
  static Future<Directory> _getReceiptsDirectory() async {
    if (kIsWeb) {
      // Trên môi trường Web, không có filesystem native
      return Directory('/web_storage/receipts');
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${appDocDir.path}/$_receiptsFolder');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    return receiptsDir;
  }

  /// Lưu file ảnh hóa đơn vào thư mục ứng dụng
  /// Trả về đường dẫn tuyệt đối của file đã lưu
  static Future<String> saveImage(String sourceFilePath) async {
    if (kIsWeb) {
      // Trên web, giữ nguyên blob/object url
      return sourceFilePath;
    }

    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        throw Exception('File ảnh nguồn không tồn tại: $sourceFilePath');
      }

      final receiptsDir = await _getReceiptsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = sourceFilePath.contains('.')
          ? sourceFilePath.substring(sourceFilePath.lastIndexOf('.'))
          : '.jpg';

      final destinationPath = '${receiptsDir.path}/receipt_$timestamp$fileExtension';
      final savedFile = await sourceFile.copy(destinationPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Lỗi khi lưu ảnh hóa đơn: $e');
      // Nếu copy lỗi, trả về đường dẫn gốc để không làm gián đoạn luồng
      return sourceFilePath;
    }
  }

  /// Lấy file ảnh từ đường dẫn đã lưu
  static File? getImage(String imagePath) {
    if (kIsWeb || imagePath.isEmpty) return null;
    final file = File(imagePath);
    return file.existsSync() ? file : null;
  }

  /// Xóa file ảnh hóa đơn khi người dùng xóa bản ghi trong database
  static Future<bool> deleteImage(String imagePath) async {
    if (kIsWeb || imagePath.isEmpty) return false;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi khi xóa file ảnh hóa đơn ($imagePath): $e');
    }
    return false;
  }
}
