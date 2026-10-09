import 'package:flutter_test/flutter_test.dart';
import 'package:bill_lens/core/services/merchant_parser.dart';
import 'package:bill_lens/core/services/receipt_parser_service.dart';

void main() {
  group('ReceiptParserService Tests', () {
    test('Phân tích hóa đơn WinMart theo ví dụ Mục 8 trong tài liệu', () {
      const ocrText = '''
WINMART
01/10/2026

Sua tuoi TH True Milk
45.000

Banh mi
20.000

Nuoc
15.000

TOTAL
80.000 VND
''';

      final receiptData = ReceiptParserService.parse(ocrText);

      expect(receiptData.merchant, equals('WINMART'));
      expect(receiptData.date, equals(DateTime(2026, 10, 1)));
      expect(receiptData.total, equals(80000.0));
      expect(receiptData.suggestedCategory, equals('Thực phẩm'));
    });

    test('Hỗ trợ tất cả các định dạng tiền tệ phổ biến theo Mục 9', () {
      // 150,000 VND -> 150000
      expect(ReceiptParserService.parseTotal('TOTAL: 150,000 VND'), equals(150000.0));

      // 150.000 đ -> 150000
      expect(ReceiptParserService.parseTotal('Tong tien: 150.000 đ'), equals(150000.0));

      // 150000 VND -> 150000
      expect(ReceiptParserService.parseTotal('THANH TOAN: 150000 VND'), equals(150000.0));

      // 150000đ -> 150000
      expect(ReceiptParserService.parseTotal('TONG CONG: 150000đ'), equals(150000.0));

      // 1,500,000 -> 1500000
      expect(ReceiptParserService.parseTotal('TOTAL: 1,500,000'), equals(1500000.0));

      // 1.500.000 -> 1500000
      expect(ReceiptParserService.parseTotal('TIEN PHAI TRA: 1.500.000'), equals(1500000.0));

      // Từ khóa TOTAL ở dòng trên, số tiền ở dòng dưới
      const multiLineTotal = '''
Cộng tiền hàng: 75.000
TOTAL
80.000 VND
''';
      expect(ReceiptParserService.parseTotal(multiLineTotal), equals(80000.0));
    });

    test('Hỗ trợ các định dạng ngày phổ biến: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY', () {
      expect(ReceiptParserService.parseDate('Ngay: 01/10/2026'), equals(DateTime(2026, 10, 1)));
      expect(ReceiptParserService.parseDate('Date: 01-10-2026'), equals(DateTime(2026, 10, 1)));
      expect(ReceiptParserService.parseDate('Ngay: 01.10.2026'), equals(DateTime(2026, 10, 1)));
      expect(ReceiptParserService.parseDate('30/09/2026 14:30'), equals(DateTime(2026, 9, 30)));
    });

    test('MerchantParser ưu tiên nhận diện chuỗi siêu thị và lọc blacklist', () {
      // Nhận diện chuỗi quen thuộc
      expect(MerchantParser.extractMerchant(['CIRCLE K', '30/09/2026', 'Total: 85.000']), equals('CIRCLE K'));
      expect(MerchantParser.extractMerchant(['FPT SHOP', '28/09/2026', 'Total: 1.200.000']), equals('FPT SHOP'));

      // Fallback: Lấy dòng đầu tiên và loại trừ các từ khóa rác (TOTAL, DATE, PHONE, ADDRESS, VAT, TAX)
      final fallbackLines = [
        'HOA DON BAN LE',
        'TIEM TAP HOA CO BA',
        'DIA CHI: 123 NGUYEN TRAI',
        'SDT: 0901234567',
        'DATE: 02/10/2026',
        'TOTAL: 50.000 đ',
      ];
      expect(MerchantParser.extractMerchant(fallbackLines), equals('TIEM TAP HOA CO BA'));
    });
  });
}
