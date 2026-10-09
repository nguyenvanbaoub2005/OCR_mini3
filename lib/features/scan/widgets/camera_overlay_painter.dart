import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Painter vẽ khung ngắm (viewfinder overlay) hỗ trợ người dùng căn chỉnh hóa đơn
class CameraOverlayPainter extends CustomPainter {
  final Rect cutoutRect;

  CameraOverlayPainter({required this.cutoutRect});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    // Vẽ nền mờ xung quanh, chừa lại khung hóa đơn ở giữa
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(overlayPath, backgroundPaint);

    // Vẽ viền nét đứt hoặc viền mỏng quanh khung
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)),
      borderPaint,
    );

    // Vẽ 4 góc định vị (Corner brackets) màu xanh ngọc nổi bật
    final cornerPaint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const radius = 16.0;

    // Góc trên bên trái
    canvas.drawLine(
      Offset(cutoutRect.left + radius, cutoutRect.top),
      Offset(cutoutRect.left + radius + cornerLength, cutoutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.top + radius),
      Offset(cutoutRect.left, cutoutRect.top + radius + cornerLength),
      cornerPaint,
    );

    // Góc trên bên phải
    canvas.drawLine(
      Offset(cutoutRect.right - radius, cutoutRect.top),
      Offset(cutoutRect.right - radius - cornerLength, cutoutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.top + radius),
      Offset(cutoutRect.right, cutoutRect.top + radius + cornerLength),
      cornerPaint,
    );

    // Góc dưới bên trái
    canvas.drawLine(
      Offset(cutoutRect.left + radius, cutoutRect.bottom),
      Offset(cutoutRect.left + radius + cornerLength, cutoutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.bottom - radius),
      Offset(cutoutRect.left, cutoutRect.bottom - radius - cornerLength),
      cornerPaint,
    );

    // Góc dưới bên phải
    canvas.drawLine(
      Offset(cutoutRect.right - radius, cutoutRect.bottom),
      Offset(cutoutRect.right - radius - cornerLength, cutoutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.bottom - radius),
      Offset(cutoutRect.right, cutoutRect.bottom - radius - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CameraOverlayPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect;
  }
}
