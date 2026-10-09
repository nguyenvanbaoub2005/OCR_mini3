import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/receipt_controller.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/receipt_model.dart';
import 'receipt_review_screen.dart';

/// Màn hình Chi tiết hóa đơn (Receipt Detail Screen - Phase 8)
/// Cho phép người dùng:
/// - Xem chi tiết hóa đơn (Ảnh zoomable, số tiền, merchant, ngày, ghi chú, mã ID)
/// - Kiểm tra Raw OCR Text trích xuất từ Google ML Kit với nút sao chép
/// - Chỉnh sửa thông tin hóa đơn (mở ReceiptReviewScreen ở chế độ Edit)
/// - Xóa hóa đơn khỏi cơ sở dữ liệu SQLite và bộ nhớ máy
class ReceiptDetailScreen extends StatefulWidget {
  final ReceiptModel receipt;

  const ReceiptDetailScreen({
    super.key,
    required this.receipt,
  });

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  late ReceiptModel _currentReceipt;
  bool _isOcrExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentReceipt = widget.receipt;
  }

  /// Mở màn hình chỉnh sửa hóa đơn
  Future<void> _editReceipt() async {
    final updated = await Navigator.push<ReceiptModel>(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptReviewScreen.edit(
          receipt: _currentReceipt,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentReceipt = updated;
      });
    }
  }

  /// Xác nhận và xóa hóa đơn
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Text('Xóa hóa đơn?'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa hóa đơn "${_currentReceipt.merchant}" (${AppFormatter.formatCurrency(_currentReceipt.total)}) không?\n\nHành động này không thể hoàn tác.',
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (_currentReceipt.id != null) {
        await ReceiptController.instance.deleteReceipt(_currentReceipt.id!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa hóa đơn khỏi lịch sử'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  /// Mở ảnh phóng to toàn màn hình với InteractiveViewer
  void _openFullScreenImage() {
    if (_currentReceipt.imagePath.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              _currentReceipt.merchant,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: kIsWeb
                  ? Image.network(
                      _currentReceipt.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                        size: 64,
                      ),
                    )
                  : Image.file(
                      File(_currentReceipt.imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppConstants.getCategoryColor(_currentReceipt.category);
    final categoryIcon = AppConstants.getCategoryIcon(_currentReceipt.category);
    final hasImage = _currentReceipt.imagePath.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Hóa Đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Chỉnh sửa',
            onPressed: _editReceipt,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Xóa hóa đơn',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Ảnh hóa đơn (có thể chạm để phóng to)
            GestureDetector(
              onTap: hasImage ? _openFullScreenImage : null,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      kIsWeb
                          ? Image.network(
                              _currentReceipt.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildNoImage(categoryIcon, categoryColor),
                            )
                          : Image.file(
                              File(_currentReceipt.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildNoImage(categoryIcon, categoryColor),
                            )
                    else
                      _buildNoImage(categoryIcon, categoryColor),

                    // Badge hướng dẫn zoom ảnh
                    if (hasImage)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Chạm để phóng to',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Card Tổng tiền & Tên cửa hàng
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge Danh mục
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(categoryIcon, color: categoryColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _currentReceipt.category,
                              style: TextStyle(
                                color: categoryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ID hóa đơn
                      if (_currentReceipt.id != null)
                        Text(
                          '#${_currentReceipt.id.toString().padLeft(4, '0')}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Số tiền lớn nổi bật
                  Text(
                    AppFormatter.formatCurrency(_currentReceipt.total),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tên cửa hàng
                  Text(
                    _currentReceipt.merchant,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Card Chi tiết thông tin (Ngày, Ghi chú, Thời gian tạo)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Ngày chi tiêu',
                    value: AppFormatter.formatDate(_currentReceipt.date),
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _buildDetailRow(
                    icon: Icons.notes_rounded,
                    label: 'Ghi chú',
                    value: _currentReceipt.note != null && _currentReceipt.note!.isNotEmpty
                        ? _currentReceipt.note!
                        : 'Không có ghi chú',
                    isMuted: _currentReceipt.note == null || _currentReceipt.note!.isEmpty,
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _buildDetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Ngày lưu',
                    value: AppFormatter.formatDate(_currentReceipt.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Card Raw OCR Text (Google ML Kit)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
                    title: const Text(
                      'Văn bản gốc từ OCR',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Dữ liệu bóc tách thô từ Google ML Kit',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        _isOcrExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      ),
                      onPressed: () {
                        setState(() {
                          _isOcrExpanded = !_isOcrExpanded;
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _isOcrExpanded = !_isOcrExpanded;
                      });
                    },
                  ),
                  if (_isOcrExpanded) ...[
                    const Divider(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SelectableText(
                              _currentReceipt.rawText.isNotEmpty
                                  ? _currentReceipt.rawText
                                  : '(Không có nội dung văn bản thô)',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                fontFamily: 'monospace',
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_currentReceipt.rawText.isNotEmpty)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Sao chép văn bản OCR'),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _currentReceipt.rawText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã sao chép nội dung OCR vào bộ nhớ tạm'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Nút Thao Tác (Chỉnh sửa & Xóa)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    label: const Text('Xóa', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _confirmDelete,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Chỉnh sửa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _editReceipt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImage(IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          const Text(
            'Hóa đơn không có ảnh đính kèm',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMuted = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isMuted ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
