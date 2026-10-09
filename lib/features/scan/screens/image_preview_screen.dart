import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/receipt_image_storage_service.dart';
import '../services/image_crop_service.dart';
import 'ocr_processing_screen.dart';

/// Màn hình xem trước & cắt ảnh hóa đơn (Phase 3)
/// Cho phép người dùng:
/// - Xem chi tiết ảnh đã chụp hoặc chọn
/// - Cắt (crop), xoay ảnh hóa đơn cho vuông vắn
/// - Chụp lại (quay về camera)
/// - Xác nhận sử dụng ảnh -> Lưu vào thư mục documents ứng dụng và chuyển sang OCR
class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;

  const ImagePreviewScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late String _currentImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  /// Mở giao diện cắt ảnh (Image Crop)
  Future<void> _handleCropImage() async {
    final croppedPath = await ImageCropService.cropImage(
      context: context,
      sourcePath: _currentImagePath,
    );

    if (croppedPath != null && mounted) {
      setState(() {
        _currentImagePath = croppedPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cắt ảnh hóa đơn thành công!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// Xác nhận sử dụng ảnh: Lưu vào documents directory và chuyển sang OCR
  Future<void> _confirmAndProceed() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Lưu ảnh vào thư mục documents/receipts/ của ứng dụng (theo Mục 14)
      final savedPath = await ReceiptImageStorageService.saveImage(_currentImagePath);

      if (!mounted) return;

      // 2. Chuyển sang màn hình OCR Processing (Phase 4)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OcrProcessingScreen(imagePath: savedPath),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu ảnh hóa đơn: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Xem Trước & Cắt Ảnh',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          // Nút Cắt ảnh trên thanh AppBar
          TextButton.icon(
            onPressed: _isSaving ? null : _handleCropImage,
            icon: const Icon(Icons.crop_rounded, color: AppColors.primaryLight, size: 20),
            label: const Text(
              'Cắt ảnh',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Khung hiển thị ảnh hóa đơn (với key thay đổi khi crop để cập nhật UI ngay lập tức)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF1E293B),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: kIsWeb
                      ? Image.network(
                          _currentImagePath,
                          key: ValueKey(_currentImagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                          ),
                        )
                      : Image.file(
                          File(_currentImagePath),
                          key: ValueKey(_currentImagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                          ),
                        ),
                ),
              ),
            ),

            // Thanh công cụ hành động: [ Chụp lại ] và [ Sử dụng ảnh ]
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  // Nút Chụp lại
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 20),
                      label: const Text(
                        'Chụp lại',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Nút Sử dụng ảnh
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _confirmAndProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        _isSaving ? 'Đang lưu...' : 'Sử dụng ảnh',
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
