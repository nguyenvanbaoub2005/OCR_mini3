import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/receipt_controller.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/receipt_model.dart';
import '../../scan/screens/camera_scan_screen.dart';
import '../widgets/category_breakdown_item.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/weekly_expense_chart.dart';

enum StatPeriod {
  week('Tuần này'),
  month('Tháng này'),
  all('Tất cả');

  final String label;
  const StatPeriod(this.label);
}

/// Màn hình Thống kê chi tiêu (Statistics Screen - Phase 9)
/// Yêu cầu đồ án:
/// - Toàn bộ biểu đồ vẽ thuần bằng Flutter CustomPainter
/// - Biểu đồ tròn Donut hiển thị tỉ trọng danh mục
/// - Biểu đồ cột thể hiện chi tiêu 7 ngày
/// - Bộ lọc theo Tuần này, Tháng này, Toàn bộ
/// - Bảng xếp hạng chi tiêu các nhóm hàng
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatPeriod _selectedPeriod = StatPeriod.month;

  /// Lọc hóa đơn theo chu kỳ thời gian đã chọn
  List<ReceiptModel> _filterReceiptsByPeriod(List<ReceiptModel> allReceipts) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case StatPeriod.week:
        // Thứ 2 đầu tuần hiện tại
        final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        final endOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6, 23, 59, 59);
        return allReceipts.where((r) => r.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && r.date.isBefore(endOfWeek.add(const Duration(seconds: 1)))).toList();

      case StatPeriod.month:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return allReceipts.where((r) => r.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && r.date.isBefore(endOfMonth.add(const Duration(seconds: 1)))).toList();

      case StatPeriod.all:
        return allReceipts;
    }
  }

  /// Tính tổng chi tiêu theo từng danh mục
  Map<String, double> _calculateCategoryTotals(List<ReceiptModel> receipts) {
    final Map<String, double> map = {};
    for (final cat in AppConstants.categories) {
      map[cat] = 0.0;
    }

    for (final r in receipts) {
      map[r.category] = (map[r.category] ?? 0.0) + r.total;
    }
    return map;
  }

  /// Tạo dữ liệu 7 ngày gần nhất phục vụ WeeklyBarChart
  List<DayExpenseData> _buildWeeklyData(List<ReceiptModel> allReceipts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<DayExpenseData> list = [];

    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    // 7 ngày kết thúc vào hôm nay
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));

      final dayReceipts = allReceipts.where((r) =>
          r.date.isAfter(date.subtract(const Duration(seconds: 1))) &&
          r.date.isBefore(nextDate));

      final total = dayReceipts.fold(0.0, (sum, r) => sum + r.total);
      final weekdayIndex = date.weekday - 1; // 1 = Mon -> 0
      final label = dayLabels[weekdayIndex];

      list.add(
        DayExpenseData(
          date: date,
          label: label,
          amount: total,
          isToday: i == 0,
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ReceiptController.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thống Kê Chi Tiêu'),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final allReceipts = controller.receipts;
          final filteredReceipts = _filterReceiptsByPeriod(allReceipts);
          final double totalExpense = filteredReceipts.fold(0.0, (sum, r) => sum + r.total);
          final categoryTotals = _calculateCategoryTotals(filteredReceipts);
          final weeklyData = _buildWeeklyData(allReceipts);

          // Tìm danh mục chi tiêu cao nhất
          String topCategory = 'Chưa có';
          double topCategoryAmount = 0.0;
          categoryTotals.forEach((cat, amt) {
            if (amt > topCategoryAmount) {
              topCategoryAmount = amt;
              topCategory = cat;
            }
          });

          // Tính trung bình mỗi ngày
          int daysInPeriod = 1;
          if (_selectedPeriod == StatPeriod.week) {
            daysInPeriod = 7;
          } else if (_selectedPeriod == StatPeriod.month) {
            daysInPeriod = DateTime.now().day;
          } else {
            daysInPeriod = 30;
          }
          final double dailyAverage = totalExpense / (daysInPeriod > 0 ? daysInPeriod : 1);

          // Bảng xếp hạng danh mục
          final rankedCategories = categoryTotals.entries
              .where((e) => e.value > 0)
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => controller.loadReceipts(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Bộ chọn khoảng thời gian (Period Selector Tabs)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: StatPeriod.values.map((period) {
                        final isSelected = _selectedPeriod == period;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPeriod = period;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                period.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Thẻ Thống kê nhanh (Quick Stat Cards)
                  Row(
                    children: [
                      // Tổng chi tiêu
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Tổng chi tiêu',
                          value: AppFormatter.formatCurrency(totalExpense),
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nhóm chi nhiều nhất
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Chi nhiều nhất',
                          value: topCategoryAmount > 0 ? topCategory : '---',
                          subtitle: topCategoryAmount > 0
                              ? AppFormatter.formatCurrency(topCategoryAmount)
                              : null,
                          icon: Icons.trending_up_rounded,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Trung bình mỗi ngày
                  _buildSummaryCard(
                    title: 'Chi tiêu trung bình ngày',
                    value: AppFormatter.formatCurrency(dailyAverage),
                    subtitle: 'Dựa trên ${filteredReceipts.length} hóa đơn trong ${_selectedPeriod.label.toLowerCase()}',
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.secondary,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 16),

                  // 3. Biểu đồ tròn Donut vẽ thuần bằng CustomPainter
                  CategoryDonutChart(
                    categoryTotals: categoryTotals,
                    totalAmount: totalExpense,
                  ),
                  const SizedBox(height: 16),

                  // 4. Biểu đồ cột Weekly Bar Chart vẽ thuần bằng CustomPainter
                  WeeklyExpenseChart(
                    weeklyData: weeklyData,
                  ),
                  const SizedBox(height: 20),

                  // 5. Bảng xếp hạng danh mục chi tiêu (Category Spending Ranking)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Xếp hạng chi tiêu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${rankedCategories.length} danh mục',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (rankedCategories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Không có dữ liệu trong kỳ này',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ...rankedCategories.asMap().entries.map((entry) {
                            final rank = entry.key + 1;
                            final cat = entry.value.key;
                            final amt = entry.value.value;
                            final pct = totalExpense > 0 ? (amt / totalExpense) * 100 : 0.0;

                            return CategoryBreakdownItem(
                              rank: rank,
                              category: cat,
                              amount: amt,
                              percentage: pct,
                            );
                          }),
                      ],
                    ),
                  ),

                  // Trạng thái nếu chưa có hóa đơn nào
                  if (allReceipts.isEmpty) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CameraScanScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Quét hóa đơn để tạo biểu đồ'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: isFullWidth
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
    );
  }
}
