import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/receipt_controller.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../receipt/screens/receipt_detail_screen.dart';
import '../../scan/screens/camera_scan_screen.dart';
import '../widgets/quick_stat_card.dart';
import '../widgets/recent_receipt_item.dart';
import '../widgets/scan_action_banner.dart';

/// Màn hình Trang chủ (Dashboard) chính của BillLens
/// Kết nối động với SQLite qua ReceiptController
class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToScan;
  final VoidCallback? onNavigateToExpenses;

  const HomeScreen({
    super.key,
    this.onNavigateToScan,
    this.onNavigateToExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final controller = ReceiptController.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final receipts = controller.receipts;
            final double monthTotal = controller.monthTotal;
            final double weekTotal = controller.weekTotal;
            final int receiptCount = receipts.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header chào mừng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.document_scanner_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                AppConstants.appName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            AppConstants.appTagline,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: () => _showProjectInfoModal(context),
                          tooltip: 'Thông tin đồ án & Quản lý dữ liệu',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Thẻ số liệu thống kê nhanh (Quick Stats từ SQLite)
                  Row(
                    children: [
                      Expanded(
                        child: QuickStatCard(
                          title: 'Chi tiêu tháng này',
                          amount: AppFormatter.formatCurrency(monthTotal),
                          icon: Icons.calendar_month_rounded,
                          iconColor: AppColors.primary,
                          subtitle: 'Tháng ${DateTime.now().month}/${DateTime.now().year}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickStatCard(
                          title: 'Chi tiêu tuần này',
                          amount: AppFormatter.formatCurrency(weekTotal),
                          icon: Icons.trending_up_rounded,
                          iconColor: AppColors.secondary,
                          subtitle: '$receiptCount hóa đơn',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Banner hành động Quét hóa đơn (Scan Action Banner)
                  ScanActionBanner(
                    onScanPressed: () {
                      if (onNavigateToScan != null) {
                        onNavigateToScan!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CameraScanScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Tiêu đề phần Hóa đơn gần đây
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hóa đơn gần đây',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (onNavigateToExpenses != null) {
                            onNavigateToExpenses!();
                          }
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Xem tất cả',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Danh sách hóa đơn thực tế từ SQLite (lấy tối đa 5 hóa đơn mới nhất)
                  if (controller.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (receipts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text(
                            'Chưa có hóa đơn nào',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: receipts.length > 5 ? 5 : receipts.length,
                      itemBuilder: (context, index) {
                        final receipt = receipts[index];
                        return RecentReceiptItem(
                          receipt: receipt,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReceiptDetailScreen(receipt: receipt),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showProjectInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BillLens – Smart Expense',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Phiên bản 1.0.0 • Đồ án tốt nghiệp',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  _InfoFeatureRow(
                    icon: Icons.offline_bolt_rounded,
                    title: 'Offline-First 100%',
                    desc: 'Cơ sở dữ liệu SQLite cục bộ, bảo mật và riêng tư tuyệt đối',
                  ),
                  SizedBox(height: 10),
                  _InfoFeatureRow(
                    icon: Icons.text_snippet_outlined,
                    title: 'On-Device OCR',
                    desc: 'Google ML Kit Text Recognition bóc tách văn bản offline',
                  ),
                  SizedBox(height: 10),
                  _InfoFeatureRow(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'CustomPainter Visuals',
                    desc: 'Biểu đồ Donut & Bar chart vẽ thuần Canvas API không dùng thư viện ngoài',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await ReceiptController.instance.resetDemoData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã khôi phục 4 hóa đơn mẫu demo thành công!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.restore_page_rounded, size: 20),
              label: const Text('Nạp lại dữ liệu mẫu (Reset Demo Data)'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Xác nhận xóa tất cả'),
                    content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử hóa đơn trong máy?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        child: const Text('Xóa hết', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (context.mounted) Navigator.pop(context);
                  await ReceiptController.instance.clearAllReceipts();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa toàn bộ dữ liệu hóa đơn!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 20),
              label: const Text('Xóa toàn bộ dữ liệu', style: TextStyle(color: AppColors.error)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _InfoFeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _InfoFeatureRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
