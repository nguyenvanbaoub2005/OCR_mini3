import 'package:flutter/material.dart';

/// Bảng màu chuẩn của ứng dụng BillLens
/// Sử dụng tông màu Xanh Ngọc lục bảo (Emerald / Mint) kết hợp nền trung tính
/// mang lại cảm giác tài chính an toàn, hiện đại và tươi mới.
class AppColors {
  AppColors._();

  // Primary palette (Xanh ngọc / Emerald)
  static const Color primary = Color(0xFF0F766E); // Teal 700
  static const Color primaryLight = Color(0xFF14B8A6); // Teal 500
  static const Color primaryDark = Color(0xFF115E59); // Teal 800
  static const Color primaryContainer = Color(0xFFCCFBF1); // Teal 100

  // Secondary & Accent (Màu bổ trợ)
  static const Color secondary = Color(0xFF0284C7); // Sky 600
  static const Color accent = Color(0xFFF59E0B); // Amber 500

  // Neutral colors (Nền, thẻ, viền)
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color cardBg = Colors.white;
  static const Color border = Color(0xFFE2E8F0); // Slate 200

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Semantic Status colors (Trạng thái)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
}
