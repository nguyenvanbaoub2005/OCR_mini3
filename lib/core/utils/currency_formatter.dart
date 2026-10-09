import 'package:intl/intl.dart';

/// Tiện ích định dạng tiền tệ và ngày tháng theo chuẩn Việt Nam
class AppFormatter {
  AppFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM');

  /// Định dạng số tiền sang định dạng VNĐ (Ví dụ: 150000 -> "150.000 đ")
  static String formatCurrency(num amount) {
    return _currencyFormat.format(amount).trim();
  }

  /// Định dạng ngày (Ví dụ: DateTime -> "01/10/2026")
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Định dạng ngày ngắn (Ví dụ: DateTime -> "01/10")
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }
}
