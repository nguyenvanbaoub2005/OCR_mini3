import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/receipt_controller.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/receipt_data.dart';
import '../../../data/models/receipt_model.dart';

/// Màn hình xem xét & chỉnh sửa thông tin hóa đơn (Review Screen - Phase 6)
/// Đảm bảo nguyên tắc:
/// - Sau khi OCR KHÔNG được lưu tự động ngay
/// - Người dùng luôn được phép kiểm tra và chỉnh sửa toàn bộ thông tin
/// - Chọn danh mục chi tiêu trong danh sách chuẩn
/// - Đối chiếu với ảnh hóa đơn và Raw OCR Text
class ReceiptReviewScreen extends StatefulWidget {
  final String imagePath;
  final ReceiptData receiptData;
  final String rawText;
  final Function(ReceiptModel savedReceipt)? onSave;
  final ReceiptModel? existingReceipt;

  const ReceiptReviewScreen({
    super.key,
    required this.imagePath,
    required this.receiptData,
    required this.rawText,
    this.onSave,
    this.existingReceipt,
  });

  /// Constructor tiện ích mở màn hình ở chế độ chỉnh sửa hóa đơn đã có
  ReceiptReviewScreen.edit({
    super.key,
    required ReceiptModel receipt,
  })  : existingReceipt = receipt,
        imagePath = receipt.imagePath,
        rawText = receipt.rawText,
        receiptData = ReceiptData(
          merchant: receipt.merchant,
          total: receipt.total,
          date: receipt.date,
          suggestedCategory: receipt.category,
        ),
        onSave = null;

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _totalController;
  late TextEditingController _noteController;

  late DateTime _selectedDate;
  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReceipt;
    if (existing != null) {
      _merchantController = TextEditingController(text: existing.merchant);
      _totalController = TextEditingController(
        text: existing.total.toInt().toString(),
      );
      _noteController = TextEditingController(text: existing.note ?? '');
      _selectedDate = existing.date;
      _selectedCategory = AppConstants.categories.contains(existing.category)
          ? existing.category
          : AppConstants.categories.first;
    } else {
      final data = widget.receiptData;

      _merchantController = TextEditingController(text: data.merchant ?? '');
      _totalController = TextEditingController(
        text: data.total != null ? data.total!.toInt().toString() : '',
      );
      _noteController = TextEditingController();

      _selectedDate = data.date ?? DateTime.now();

      // Chọn danh mục gợi ý nếu có, ngược lại lấy danh mục đầu tiên
      _selectedCategory = (data.suggestedCategory != null &&
              AppConstants.categories.contains(data.suggestedCategory))
          ? data.suggestedCategory!
          : AppConstants.categories.first;
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _totalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Chọn ngày giao dịch qua DatePicker
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Xem ảnh phóng to dạng Dialog để dễ đối chiếu số liệu
  void _showEnlargedImage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb
                    ? Image.network(widget.imagePath, fit: BoxFit.contain)
                    : Image.file(File(widget.imagePath), fit: BoxFit.contain),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mở BottomSheet xem chi tiết Raw OCR Text
  void _showRawTextSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Nội dung nhận diện gốc (Raw OCR Text)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Text(
                          widget.rawText.trim(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Xử lý xác nhận lưu hóa đơn (Chuẩn bị dữ liệu cho Phase 7 Local Database)
  Future<void> _handleSaveReceipt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawTotalText = _totalController.text.trim().replaceAll('.', '').replaceAll(',', '');
    final double? totalAmount = double.tryParse(rawTotalText);

    if (totalAmount == null || totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền tổng hợp lệ!')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    if (widget.existingReceipt != null) {
      final updated = widget.existingReceipt!.copyWith(
        merchant: _merchantController.text.trim().isEmpty
            ? 'Cửa hàng không rõ'
            : _merchantController.text.trim(),
        total: totalAmount,
        date: _selectedDate,
        category: _selectedCategory,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      try {
        await ReceiptController.instance.updateReceipt(updated);
      } catch (e) {
        debugPrint('Lỗi khi cập nhật SQLite: $e');
      }

      if (widget.onSave != null) {
        widget.onSave!(updated);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật hóa đơn thành công!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, updated);
      return;
    }

    final receipt = ReceiptModel(
      merchant: _merchantController.text.trim().isEmpty
          ? 'Cửa hàng không rõ'
          : _merchantController.text.trim(),
      total: totalAmount,
      date: _selectedDate,
      category: _selectedCategory,
      imagePath: widget.imagePath,
      rawText: widget.rawText,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      createdAt: DateTime.now(),
    );

    // Lưu trực tiếp vào cơ sở dữ liệu SQLite thông qua ReceiptController
    try {
      await ReceiptController.instance.addReceipt(receipt);
    } catch (e) {
      debugPrint('Lỗi khi lưu SQLite: $e');
    }

    if (widget.onSave != null) {
      widget.onSave!(receipt);
    }

    if (!mounted) return;

    // Hiển thị dialog xác nhận thành công
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('Đã kiểm tra xong!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin hóa đơn đã sẵn sàng để lưu vào Database:'),
              const SizedBox(height: 12),
              _buildDialogRow('Cửa hàng:', receipt.merchant),
              _buildDialogRow('Tổng tiền:', AppFormatter.formatCurrency(receipt.total)),
              _buildDialogRow('Ngày:', AppFormatter.formatDate(receipt.date)),
              _buildDialogRow('Danh mục:', receipt.category),
              if (receipt.note != null) _buildDialogRow('Ghi chú:', receipt.note!),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Đóng Dialog
                // Quay trở lại màn hình chính Dashboard
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Hoàn tất'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existingReceipt != null ? 'Chỉnh Sửa Hóa Đơn' : 'Xác Nhận Hóa Đơn'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Thẻ ảnh hóa đơn thu nhỏ kèm nút phóng to và xem OCR
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail ảnh
                            GestureDetector(
                              onTap: _showEnlargedImage,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFF1E293B),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: kIsWeb
                                        ? Image.network(widget.imagePath, fit: BoxFit.cover)
                                        : Image.file(File(widget.imagePath), fit: BoxFit.cover),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.zoom_in_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Mô tả & Nút xem OCR
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ảnh hóa đơn đã chụp',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Bấm vào ảnh để phóng to đối chiếu, hoặc xem lại nội dung nhận diện gốc.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: _showRawTextSheet,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    icon: const Icon(Icons.document_scanner_rounded, size: 16),
                                    label: const Text('Xem nội dung OCR'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Thông tin chi tiết (Cho phép chỉnh sửa)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Ô nhập Cửa hàng / Thương nhân
                      TextFormField(
                        controller: _merchantController,
                        decoration: const InputDecoration(
                          labelText: 'Cửa hàng / Người bán',
                          prefixIcon: Icon(Icons.storefront_rounded, color: AppColors.primary),
                          hintText: 'Ví dụ: WinMart, Circle K, ...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên cửa hàng';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 3. Ô chọn Ngày giao dịch
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ngày giao dịch',
                            prefixIcon: Icon(Icons.calendar_today_rounded, color: AppColors.secondary),
                            suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                          ),
                          child: Text(
                            AppFormatter.formatDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Ô nhập Tổng tiền
                      TextFormField(
                        controller: _totalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tổng tiền thanh toán',
                          prefixIcon: Icon(Icons.payments_rounded, color: AppColors.success),
                          suffixText: 'VNĐ',
                          suffixStyle: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                          hintText: 'Ví dụ: 150000',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tổng tiền hóa đơn';
                          }
                          final parsed = double.tryParse(value.replaceAll('.', '').replaceAll(',', ''));
                          if (parsed == null || parsed <= 0) {
                            return 'Số tiền phải là số lớn hơn 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 5. Ô chọn Danh mục chi tiêu (Dropdown)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục chi tiêu',
                          prefixIcon: Icon(Icons.category_rounded, color: AppColors.accent),
                        ),
                        items: AppConstants.categories.map((cat) {
                          final color = AppConstants.getCategoryColor(cat);
                          final icon = AppConstants.getCategoryIcon(cat);
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(icon, color: color, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // 6. Ô nhập Ghi chú (Note)
                      TextFormField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú thêm (Tùy chọn)',
                          prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary),
                          hintText: 'Ví dụ: Chi tiêu cho sinh hoạt nhóm, cà phê sáng...',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Thanh công cụ nút bấm: [ Hủy ] và [ Lưu hóa đơn ]
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  // Nút Hủy
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Nút Lưu hóa đơn
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSaveReceipt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        widget.existingReceipt != null ? 'Lưu thay đổi' : 'Lưu hóa đơn',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
