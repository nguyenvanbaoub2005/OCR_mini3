/// Service chuyên biệt nhận diện tên cửa hàng/thương nhân (Merchant Parser)
/// Áp dụng thuật toán Heuristic:
/// 1. Ưu tiên khớp với danh sách các chuỗi bán lẻ, siêu thị phổ biến
/// 2. Nếu không có trong danh sách: Lấy dòng đầu tiên khả thi sau khi đã loại trừ các từ khóa rác
class MerchantParser {
  MerchantParser._();

  /// Danh sách các chuỗi cửa hàng / thương nhân phổ biến tại Việt Nam
  static const List<String> _knownMerchants = [
    'WINMART',
    'VINCOM',
    'BIG C',
    'LOTTE MART',
    'CIRCLE K',
    'CO.OPMART',
    'COOPMART',
    'GS25',
    '7-ELEVEN',
    'SEVEN ELEVEN',
    'FAMILYMART',
    'BACH HOA XANH',
    'HIGHLANDS',
    'PHUC LONG',
    'THE COFFEE HOUSE',
    'STARBUCKS',
    'KFC',
    'LOTTERIA',
    'JOLLIBEE',
    'FPT SHOP',
    'THE GIOI DI DONG',
    'DI DONG VIET',
    'LONG CHAU',
    'AN KHANG',
    'PHARMACITY',
    'FAHASA',
    'BOOKSTORE',
    'NHA SACH',
    'TIKI',
    'SHOPEE',
  ];

  /// Các từ khóa bị loại trừ (Blacklist) khi tìm tên cửa hàng ở các dòng đầu
  static const List<String> _blacklistKeywords = [
    'TOTAL',
    'TONG',
    'CONG',
    'VAT',
    'DATE',
    'NGAY',
    'PHONE',
    'SDT',
    'TEL',
    'ADDRESS',
    'DIA CHI',
    'TAX',
    'MST',
    'HOA DON',
    'RECEIPT',
    'BILL',
    'KHACH HANG',
    'THANH TOAN',
    'TIEN MAT',
    'TIEN THUA',
    'QUAY',
    'CASHIER',
    'STT',
    'GIO',
    'TIME',
    'VND',
    'VNĐ',
  ];

  /// Trích xuất tên Merchant từ danh sách các dòng văn bản OCR
  static String? extractMerchant(List<String> lines) {
    if (lines.isEmpty) return null;

    // BƯỚC 1: Ưu tiên tìm trong danh sách thương nhân đã biết (_knownMerchants)
    for (final line in lines) {
      final normalizedLine = _normalize(line);
      for (final known in _knownMerchants) {
        if (normalizedLine.contains(_normalize(known))) {
          // Trả về tên chuẩn mực gọn gàng
          return known;
        }
      }
    }

    // BƯỚC 2: Fallback - Tìm dòng đầu tiên có khả năng cao là tên cửa hàng
    // Thông thường tên cửa hàng luôn nằm trong 5-7 dòng đầu tiên của hóa đơn
    final searchLines = lines.take(7);

    for (final line in searchLines) {
      final trimmed = line.trim();
      if (_isValidMerchantCandidate(trimmed)) {
        // Làm sạch tên: xóa các ký tự đặc biệt ở đầu/cuối dòng
        return _cleanMerchantName(trimmed);
      }
    }

    return null;
  }

  /// Gợi ý danh mục chi tiêu tự động dựa trên tên cửa hàng
  static String suggestCategory(String? merchant) {
    if (merchant == null) return 'Khác';
    final upper = merchant.toUpperCase();

    if (upper.contains('WINMART') ||
        upper.contains('CIRCLE K') ||
        upper.contains('BIG C') ||
        upper.contains('LOTTE') ||
        upper.contains('CO.OP') ||
        upper.contains('COOP') ||
        upper.contains('GS25') ||
        upper.contains('7-ELEVEN') ||
        upper.contains('FAMILYMART') ||
        upper.contains('BACH HOA XANH') ||
        upper.contains('HIGHLANDS') ||
        upper.contains('PHUC LONG') ||
        upper.contains('COFFEE') ||
        upper.contains('STARBUCKS') ||
        upper.contains('KFC') ||
        upper.contains('LOTTERIA') ||
        upper.contains('JOLLIBEE') ||
        upper.contains('RESTAURANT') ||
        upper.contains('QUAN AN')) {
      return 'Thực phẩm';
    }

    if (upper.contains('FPT') ||
        upper.contains('THE GIOI DI DONG') ||
        upper.contains('DI DONG') ||
        upper.contains('APPLE') ||
        upper.contains('SAMSUNG') ||
        upper.contains('XIAOMI') ||
        upper.contains('PHU KIEN')) {
      return 'Thiết bị';
    }

    if (upper.contains('BOOK') ||
        upper.contains('FAHASA') ||
        upper.contains('NHA SACH') ||
        upper.contains('GIAO TRINH') ||
        upper.contains('LIBRARY') ||
        upper.contains('PHOTOCOPY') ||
        upper.contains('IN AN')) {
      return 'Nghiên cứu';
    }

    if (upper.contains('AIRLINE') ||
        upper.contains('VIETJET') ||
        upper.contains('VIETNAM AIRLINES') ||
        upper.contains('HOTEL') ||
        upper.contains('KHACH SAN') ||
        upper.contains('RESORT') ||
        upper.contains('TOUR') ||
        upper.contains('XE KHACH') ||
        upper.contains('TAXI') ||
        upper.contains('GRAB')) {
      return 'Du lịch';
    }

    if (upper.contains('CINEMA') ||
        upper.contains('CGV') ||
        upper.contains('BHD') ||
        upper.contains('GALAXY') ||
        upper.contains('GAME') ||
        upper.contains('KARAOKE')) {
      return 'Giải trí';
    }

    return 'Khác';
  }

  /// Kiểm tra xem một dòng có phải là ứng viên hợp lệ cho tên cửa hàng không
  static bool _isValidMerchantCandidate(String line) {
    if (line.length < 3 || line.length > 50) return false;

    // Loại trừ nếu chứa bất kỳ từ khóa blacklist nào
    final upper = _normalize(line);
    for (final keyword in _blacklistKeywords) {
      if (upper.contains(_normalize(keyword))) {
        return false;
      }
    }

    // Loại trừ nếu dòng chỉ toàn số hoặc ký tự đặc biệt hoặc ngày tháng
    final letterCount = RegExp(r'[a-zA-ZÀ-ỹ]').allMatches(line).length;
    if (letterCount < 3) return false;

    // Loại trừ nếu trông giống định dạng ngày tháng (vd: 01/10/2026)
    if (RegExp(r'\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}').hasMatch(line)) {
      return false;
    }

    // Loại trừ nếu trông giống số điện thoại hoặc mã số thuế (nhiều số liên tiếp)
    if (RegExp(r'\d{7,}').hasMatch(line)) {
      return false;
    }

    return true;
  }

  static String _cleanMerchantName(String name) {
    return name
        .replaceAll(RegExp(r'^[^a-zA-Z0-9À-ỹ]+'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9À-ỹ]+$'), '')
        .trim();
  }

  static String _normalize(String input) {
    return input.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
