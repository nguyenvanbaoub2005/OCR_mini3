import 'package:flutter/material.dart';

/// Bảng màu chuẩn của ứng dụng BillLens
/// Đã được đổi sang tông màu Tím sẫm (Indigo / Deep Purple)
/// mang lại cảm giác sang trọng, cao cấp và huyền bí.
class AppColors {
  AppColors._();

  // Primary palette (Tím / Indigo)
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color primaryContainer = Color(0xFFE0E7FF); // Indigo 100

  // Secondary & Accent (Màu bổ trợ)
  static const Color secondary = Color(0xFFE11D48); // Rose 600
  static const Color accent = Color(0xFFF59E0B); // Amber 500

  // Neutral colors (Nền, thẻ, viền)
  static const Color background = Color(0xFFF1F5F9); // Slate 100
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF8FAFC); // Slate 50
  static const Color cardBg = Colors.white;
  static const Color border = Color(0xFFCBD5E1); // Slate 300

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Semantic Status colors (Trạng thái)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
}
