/// Dữ liệu hóa đơn sau khi được phân tích bóc tách qua Regex Heuristic Engine
class ReceiptData {
  final String? merchant;
  final DateTime? date;
  final double? total;
  final String? rawText;
  final String? suggestedCategory;

  const ReceiptData({
    this.merchant,
    this.date,
    this.total,
    this.rawText,
    this.suggestedCategory,
  });

  ReceiptData copyWith({
    String? merchant,
    DateTime? date,
    double? total,
    String? rawText,
    String? suggestedCategory,
  }) {
    return ReceiptData(
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      total: total ?? this.total,
      rawText: rawText ?? this.rawText,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
    );
  }

  @override
  String toString() {
    return 'ReceiptData(merchant: $merchant, date: $date, total: $total, category: $suggestedCategory)';
  }
}
