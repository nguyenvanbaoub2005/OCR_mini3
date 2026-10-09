import '../../data/models/receipt_data.dart';
import 'merchant_parser.dart';

/// Dịch vụ phân tích bóc tách hóa đơn bằng Heuristic Regex (ReceiptParserService)
/// Nhiệm vụ cốt lõi:
/// - Trích xuất Tổng tiền (Total amount)
/// - Trích xuất Ngày giao dịch (Transaction date)
/// - Trích xuất Tên thương nhân / Cửa hàng (Merchant name)
/// - Tự động gợi ý danh mục chi tiêu (Category suggestion)
class ReceiptParserService {
  ReceiptParserService._();

  /// Phân tích toàn bộ văn bản OCR rawText để trả về đối tượng ReceiptData
  static ReceiptData parse(String rawText, {List<String>? lines}) {
    final effectiveLines = lines ??
        rawText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    final merchant = MerchantParser.extractMerchant(effectiveLines);
    final date = parseDate(rawText, lines: effectiveLines);
    final total = parseTotal(rawText, lines: effectiveLines);
    final category = MerchantParser.suggestCategory(merchant);

    return ReceiptData(
      merchant: merchant,
      date: date,
      total: total,
      rawText: rawText,
      suggestedCategory: category,
    );
  }

  /// Trích xuất Ngày giao dịch từ văn bản hóa đơn
  /// Hỗ trợ các định dạng:
  /// - DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
  /// - DD/MM/YY
  static DateTime? parseDate(String rawText, {List<String>? lines}) {
    // Regex tìm ngày tháng: ngày (1-31), tháng (1-12), năm (2 hoặc 4 chữ số)
    // Phân cách bằng /, -, hoặc .
    final dateRegex = RegExp(
      r'\b([0-3]?[0-9])[\/\-\.]([0-1]?[0-9])[\/\-\.]((?:20)?\d{2})\b',
    );

    // Ưu tiên tìm trong từng dòng văn bản (tránh nhầm lẫn khi regex match qua nhiều dòng)
    final searchLines = lines ?? rawText.split('\n');
    for (final line in searchLines) {
      final matches = dateRegex.allMatches(line);
      for (final match in matches) {
        final dayStr = match.group(1);
        final monthStr = match.group(2);
        final yearStr = match.group(3);

        if (dayStr != null && monthStr != null && yearStr != null) {
          final day = int.tryParse(dayStr);
          final month = int.tryParse(monthStr);
          var year = int.tryParse(yearStr);

          if (day != null && month != null && year != null) {
            // Chuẩn hóa năm nếu chỉ có 2 chữ số (vd: 26 -> 2026)
            if (year < 100) {
              year += 2000;
            }

            // Kiểm tra tính hợp lệ của ngày tháng
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 2000 && year <= 2050) {
              try {
                return DateTime(year, month, day);
              } catch (_) {}
            }
          }
        }
      }
    }

    return null;
  }

  /// Trích xuất Tổng tiền (Total Amount) từ hóa đơn
  /// Hỗ trợ các định dạng:
  /// - 150,000 VND, 150.000 đ, 150000 VND, 150000đ
  /// - 1,500,000, 1.500.000, 80.000, 45.000
  static double? parseTotal(String rawText, {List<String>? lines}) {
    final searchLines = lines ?? rawText.split('\n');

    // Các từ khóa chỉ định dòng tổng tiền (được sắp xếp theo thứ tự ưu tiên giảm dần)
    final totalKeywords = [
      'TONG TIEN THANH TOAN',
      'TONG THANH TOAN',
      'TIEN PHAI TRA',
      'CAN THANH TOAN',
      'TONG CONG',
      'TONG TIEN',
      'TOTAL',
      'THANH TOAN',
      'CONG TIEN HANG',
      'CONG TIEN',
      'SUM',
      'AMOUNT',
      'SOTIEN',
    ];

    // BƯỚC 1: Tìm dòng chứa từ khóa Tổng tiền
    for (int i = 0; i < searchLines.length; i++) {
      final lineUpper = searchLines[i].toUpperCase();

      for (final keyword in totalKeywords) {
        if (lineUpper.contains(keyword)) {
          // Thử trích xuất số tiền ngay trên chính dòng chứa từ khóa
          final amountOnSameLine = _extractAmountFromText(searchLines[i]);
          if (amountOnSameLine != null && amountOnSameLine > 0) {
            return amountOnSameLine;
          }

          // Nếu cùng dòng không có số tiền, kiểm tra dòng tiếp theo ngay sau nó (thường gặp khi từ TOTAL ở trên, số tiền ở dưới)
          if (i + 1 < searchLines.length) {
            final amountOnNextLine = _extractAmountFromText(searchLines[i + 1]);
            if (amountOnNextLine != null && amountOnNextLine > 0) {
              return amountOnNextLine;
            }
          }
        }
      }
    }

    // BƯỚC 2: Fallback Heuristic - Tìm tất cả các số tiền có mặt trên hóa đơn và lấy giá trị lớn nhất hợp lý
    final List<double> foundAmounts = [];
    for (final line in searchLines) {
      final lineUpper = line.toUpperCase();
      // Bỏ qua dòng tiền thừa/tiền thối
      if (lineUpper.contains('TIEN THUA') || lineUpper.contains('TIEN THOI') || lineUpper.contains('CHANGE')) {
        continue;
      }
      final amount = _extractAmountFromText(line);
      if (amount != null && amount >= 1000) {
        foundAmounts.add(amount);
      }
    }

    if (foundAmounts.isNotEmpty) {
      foundAmounts.sort((a, b) => b.compareTo(a));
      // Trả về số tiền lớn nhất tìm được
      return foundAmounts.first;
    }

    return null;
  }

  /// Hàm phụ trợ bóc tách và chuẩn hóa số tiền từ một chuỗi văn bản
  static double? _extractAmountFromText(String text) {
    // Regex nhận diện các mẫu số tiền:
    // Nhóm 1: Có phân cách hàng nghìn bằng dấu chấm hoặc phẩy (vd: 150.000, 150,000, 1.500.000, 1,200,000)
    // Nhóm 2: Không phân cách (vd: 150000, 85000) kèm hoặc không kèm đuôi đ, VND, vnđ
    final regexWithSeparators = RegExp(
      r'(?:^|[^\d])(\d{1,3}(?:[.,]\d{3})+)(?:\s*(?:đ|vnd|vnđ|d))?(?:[^\d]|$)',
      caseSensitive: false,
    );

    final matchSeparators = regexWithSeparators.firstMatch(text);
    if (matchSeparators != null) {
      final rawNumber = matchSeparators.group(1);
      if (rawNumber != null) {
        // Chuẩn hóa: xóa toàn bộ dấu chấm và phẩy để lấy số nguyên tiền tệ VNĐ
        final cleanNumber = rawNumber.replaceAll('.', '').replaceAll(',', '');
        final parsed = double.tryParse(cleanNumber);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }

    // Nếu không khớp có phân cách, tìm số liền mạch kèm đơn vị tiền tệ hoặc số có từ 4 đến 9 chữ số
    final regexPlain = RegExp(
      r'(?:^|[^\d])(\d{4,9})\s*(?:đ|vnd|vnđ|d)?(?:[^\d]|$)',
      caseSensitive: false,
    );

    final matchPlain = regexPlain.firstMatch(text);
    if (matchPlain != null) {
      final rawNumber = matchPlain.group(1);
      if (rawNumber != null) {
        final parsed = double.tryParse(rawNumber);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }

    return null;
  }
}
