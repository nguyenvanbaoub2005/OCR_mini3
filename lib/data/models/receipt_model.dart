/// Model biểu diễn một hóa đơn đã lưu trong cơ sở dữ liệu
class ReceiptModel {
  final int? id;
  final String merchant;
  final double total;
  final DateTime date;
  final String category;
  final String imagePath;
  final String rawText;
  final String? note;
  final DateTime createdAt;

  const ReceiptModel({
    this.id,
    required this.merchant,
    required this.total,
    required this.date,
    required this.category,
    required this.imagePath,
    required this.rawText,
    this.note,
    required this.createdAt,
  });

  /// Chuyển đổi từ Map (khi đọc từ SQLite) sang ReceiptModel
  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['id'] as int?,
      merchant: map['merchant'] as String? ?? 'Không rõ',
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      category: map['category'] as String? ?? 'Khác',
      imagePath: map['imagePath'] as String? ?? '',
      rawText: map['rawText'] as String? ?? '',
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Chuyển đổi sang Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'merchant': merchant,
      'total': total,
      'date': date.toIso8601String(),
      'category': category,
      'imagePath': imagePath,
      'rawText': rawText,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ReceiptModel copyWith({
    int? id,
    String? merchant,
    double? total,
    DateTime? date,
    String? category,
    String? imagePath,
    String? rawText,
    String? note,
    DateTime? createdAt,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      total: total ?? this.total,
      date: date ?? this.date,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      rawText: rawText ?? this.rawText,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
