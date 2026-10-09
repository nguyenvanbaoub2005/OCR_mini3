import 'package:flutter/material.dart';

/// Các hằng số dùng chung trong toàn bộ ứng dụng BillLens
class AppConstants {
  AppConstants._();

  static const String appName = 'BillLens';
  static const String appTagline = 'Quản lý chi tiêu & hóa đơn thông minh';

  /// Danh sách danh mục chi tiêu mặc định theo yêu cầu của đồ án
  static const List<String> categories = [
    'Thực phẩm',
    'Nghiên cứu',
    'Du lịch',
    'Thiết bị',
    'Giải trí',
    'Khác',
  ];

  /// Icon tương ứng cho từng danh mục để hiển thị đẹp trên UI
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Thực phẩm':
        return Icons.restaurant_rounded;
      case 'Nghiên cứu':
        return Icons.school_rounded;
      case 'Du lịch':
        return Icons.flight_takeoff_rounded;
      case 'Thiết bị':
        return Icons.devices_rounded;
      case 'Giải trí':
        return Icons.sports_esports_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  /// Màu sắc đại diện cho từng danh mục (phục vụ biểu đồ CustomPainter sau này)
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Thực phẩm':
        return const Color(0xFF10B981); // Xanh lá
      case 'Nghiên cứu':
        return const Color(0xFF0284C7); // Xanh dương
      case 'Du lịch':
        return const Color(0xFFF59E0B); // Vàng cam
      case 'Thiết bị':
        return const Color(0xFF8B5CF6); // Tím
      case 'Giải trí':
        return const Color(0xFFEC4899); // Hồng
      default:
        return const Color(0xFF64748B); // Xám
    }
  }
}
