import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Kết quả nhận diện văn bản OCR từ hóa đơn
class OcrResult {
  final String rawText;
  final List<String> lines;
  final bool isSuccess;
  final String? errorMessage;

  const OcrResult({
    required this.rawText,
    required this.lines,
    required this.isSuccess,
    this.errorMessage,
  });

  factory OcrResult.failure(String message) {
    return OcrResult(
      rawText: '',
      lines: const [],
      isSuccess: false,
      errorMessage: message,
    );
  }
}

/// Service nhận diện văn bản ngoại tuyến (Offline On-device OCR) sử dụng Google ML Kit
/// Tuân thủ quy định:
/// - Chạy 100% offline trên thiết bị di động
/// - Không gọi Cloud API, không gửi dữ liệu lên server
/// - Giải phóng bộ nhớ giải thuật (close recognizer) sau khi xử lý xong
class OcrService {
  OcrService._();

  /// Quét và trích xuất toàn bộ văn bản (Raw OCR Text) từ file ảnh
  static Future<OcrResult> recognizeText(String imagePath) async {
    // 1. Xử lý dự phòng cho môi trường Web (vì Google ML Kit C++ binaries chỉ chạy trên Android & iOS)
    if (kIsWeb) {
      debugPrint('[OcrService] Đang chạy trên Web, kích hoạt giả lập OCR dữ liệu mẫu');
      await Future.delayed(const Duration(milliseconds: 1500));
      const sampleWebReceipt = '''
WINMART+
CUA HANG TIEN LOI
01/10/2026 08:35:12
HD: 0048291

1. SUA TUOI TH TRUE MILK 1L    45.000
2. BANH MI SANDWICH NGU COC     20.000
3. NUOC SUOI AQUAFINA 500ML     15.000

CONG TIEN HANG: 80.000
THUE VAT (10%): 8.000
TONG TIEN THANH TOAN: 88.000 VND
TIEN MAT: 100.000
TIEN THUA: 12.000

CAM ON QUY KHACH VA HEN GAP LAI!
''';
      final lines = sampleWebReceipt
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      return OcrResult(
        rawText: sampleWebReceipt,
        lines: lines,
        isSuccess: true,
      );
    }

    // 2. Chạy Google ML Kit thực tế trên thiết bị di động (Android / iOS)
    TextRecognizer? recognizer;
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return OcrResult.failure('Tệp ảnh không tồn tại tại đường dẫn: $imagePath');
      }

      // Khởi tạo bộ nhận diện ngôn ngữ Latin (bao gồm Tiếng Anh và Tiếng Việt không dấu / có dấu cơ bản)
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFilePath(imagePath);

      final RecognizedText recognizedText = await recognizer.processImage(inputImage);

      final String fullText = recognizedText.text;
      if (fullText.trim().isEmpty) {
        return OcrResult.failure(
          'Không thể nhận diện văn bản từ ảnh.\nBạn có thể thử chụp lại rõ nét hơn hoặc nhập thông tin thủ công.',
        );
      }

      // Tách văn bản thành từng dòng để phục vụ cho bộ Heuristic Regex ở Phase 5
      final List<String> extractedLines = [];
      for (final textBlock in recognizedText.blocks) {
        for (final line in textBlock.lines) {
          final trimmed = line.text.trim();
          if (trimmed.isNotEmpty) {
            extractedLines.add(trimmed);
          }
        }
      }

      return OcrResult(
        rawText: fullText,
        lines: extractedLines,
        isSuccess: true,
      );
    } catch (e) {
      debugPrint('[OcrService] Lỗi nhận diện OCR: $e');
      return OcrResult.failure('Lỗi xử lý OCR: ${e.toString()}');
    } finally {
      // Luôn đóng TextRecognizer để tránh rò rỉ bộ nhớ native
      await recognizer?.close();
    }
  }
}
