import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/receipt_parser_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/receipt_data.dart';
import '../../receipt/screens/receipt_review_screen.dart';

/// Màn hình xử lý OCR và phân tích Heuristic Regex (Phase 4 & Phase 5)
/// Quy trình:
/// 1. Google ML Kit Text Recognition trích xuất Raw Text (Phase 4)
/// 2. ReceiptParserService phân tích bóc tách Tổng tiền, Ngày tháng, Merchant (Phase 5)
/// 3. Hiển thị tóm tắt kết quả phân tích và cho phép xem Raw OCR Text
/// 4. Sẵn sàng chuyển tiếp sang Màn hình Review để người dùng chỉnh sửa & lưu (Phase 6)
class OcrProcessingScreen extends StatefulWidget {
  final String imagePath;

  const OcrProcessingScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<OcrProcessingScreen> createState() => _OcrProcessingScreenState();
}

class _OcrProcessingScreenState extends State<OcrProcessingScreen> {
  bool _isLoading = true;
  OcrResult? _ocrResult;
  ReceiptData? _parsedData;
  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    _startOcrAndParsing();
  }

  Future<void> _startOcrAndParsing() async {
    setState(() {
      _isLoading = true;
      _showRawText = false;
    });

    // BƯỚC 1: Quét OCR ngoại tuyến
    final ocrResult = await OcrService.recognizeText(widget.imagePath);

    // BƯỚC 2: Bóc tách bằng Regex Heuristic Engine nếu OCR thành công
    ReceiptData? parsed;
    if (ocrResult.isSuccess) {
      parsed = ReceiptParserService.parse(
        ocrResult.rawText,
        lines: ocrResult.lines,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _ocrResult = ocrResult;
        _parsedData = parsed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phân Tích Hóa Đơn'),
        actions: [
          if (!_isLoading && _ocrResult != null && _ocrResult!.isSuccess)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Quét lại',
              onPressed: _startOcrAndParsing,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading ? _buildLoadingView() : _buildResultView(),
      ),
    );
  }

  /// Giao diện Loading khi đang chạy OCR và Regex Parser
  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: kIsWeb
                  ? Image.network(widget.imagePath, fit: BoxFit.cover)
                  : Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'Đang phân tích hóa đơn...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đang nhận diện chữ và tự động tìm Tổng tiền, Ngày & Cửa hàng...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Giao diện hiển thị kết quả phân tích Heuristic Regex
  Widget _buildResultView() {
    final result = _ocrResult;
    if (result == null || !result.isSuccess) {
      return _buildErrorView(result?.errorMessage);
    }

    final data = _parsedData;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thẻ thông báo phân tích thành công
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã phân tích hóa đơn bằng Regex Heuristic!',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Đã tự động trích xuất thông tin giao dịch cốt lõi.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Thẻ dữ liệu bóc tách được (Parsed Receipt Summary)
                const Text(
                  'Thông tin trích xuất tự động',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.storefront_rounded,
                        label: 'Cửa hàng',
                        value: data?.merchant ?? 'Chưa rõ (Nhập ở bước sau)',
                        color: AppColors.primary,
                        isBold: true,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Ngày giao dịch',
                        value: data?.date != null
                            ? AppFormatter.formatDate(data!.date!)
                            : 'Chưa rõ ngày',
                        color: AppColors.secondary,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.payments_rounded,
                        label: 'Tổng tiền',
                        value: data?.total != null
                            ? AppFormatter.formatCurrency(data!.total!)
                            : 'Chưa nhận diện được tiền',
                        color: AppColors.success,
                        isBold: true,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: AppConstants.getCategoryIcon(data?.suggestedCategory ?? 'Khác'),
                        label: 'Danh mục gợi ý',
                        value: data?.suggestedCategory ?? 'Khác',
                        color: AppConstants.getCategoryColor(data?.suggestedCategory ?? 'Khác'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Nút thu gọn/mở rộng xem Raw OCR Text
                InkWell(
                  onTap: () {
                    setState(() {
                      _showRawText = !_showRawText;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description_outlined, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'Nội dung OCR gốc (${result.lines.length} dòng)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          _showRawText ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                // Nội dung Raw OCR Text khi mở rộng
                if (_showRawText) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result.rawText.trim(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Thanh công cụ hành động tiếp theo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Quay lại'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptReviewScreen(
                          imagePath: widget.imagePath,
                          receiptData: data ?? const ReceiptData(),
                          rawText: result.rawText,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: const Text(
                    'Kiểm tra & Chỉnh sửa',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.text_snippet_outlined,
                size: 54,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không thể nhận diện hóa đơn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Ảnh quá mờ hoặc không có ký tự chữ. Bạn có thể chụp lại hoặc nhập thông tin thủ công.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Chụp lại'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptReviewScreen(
                          imagePath: widget.imagePath,
                          receiptData: const ReceiptData(),
                          rawText: '',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Nhập thủ công'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
