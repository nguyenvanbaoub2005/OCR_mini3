import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';

/// Dữ liệu biểu diễn một lát cắt trong biểu đồ Donut
class DonutSliceData {
  final String category;
  final double amount;
  final double percentage;
  final Color color;
  final IconData icon;

  const DonutSliceData({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

/// Biểu đồ hình vành khăn (Donut Chart) phân bổ chi tiêu theo danh mục
/// Yêu cầu đồ án: Vẽ thuần bằng CustomPainter, KHÔNG sử dụng thư viện biểu đồ bên ngoài
class CategoryDonutChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final double totalAmount;

  const CategoryDonutChart({
    super.key,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount ||
        oldWidget.categoryTotals != widget.categoryTotals) {
      _animationController.reset();
      _animationController.forward();
      _selectedCategory = null;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<DonutSliceData> _prepareSlices() {
    if (widget.totalAmount <= 0) return [];

    final list = <DonutSliceData>[];
    widget.categoryTotals.forEach((category, amount) {
      if (amount > 0) {
        final percentage = (amount / widget.totalAmount) * 100;
        list.add(
          DonutSliceData(
            category: category,
            amount: amount,
            percentage: percentage,
            color: AppConstants.getCategoryColor(category),
            icon: AppConstants.getCategoryIcon(category),
          ),
        );
      }
    });

    // Sắp xếp danh mục có số tiền cao nhất lên trước
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final slices = _prepareSlices();

    if (slices.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 18,
                ),
              ),
              child: const Center(
                child: Text(
                  '0 đ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có dữ liệu chi tiêu trong khoảng thời gian này',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Lấy thông tin hiển thị tại tâm hình tròn
    DonutSliceData? activeSlice;
    if (_selectedCategory != null) {
      try {
        activeSlice = slices.firstWhere((s) => s.category == _selectedCategory);
      } catch (_) {
        activeSlice = null;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề biểu đồ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phân bổ danh mục',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_selectedCategory != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Vùng vẽ Biểu đồ tròn Donut
          Center(
            child: SizedBox(
              width: 210,
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(210, 210),
                        painter: _DonutChartPainter(
                          slices: slices,
                          animationProgress: _animation.value,
                          selectedCategory: _selectedCategory,
                        ),
                      );
                    },
                  ),

                  // Nội dung hiển thị ở tâm hình vành khăn
                  Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          activeSlice != null ? activeSlice.category : 'Tổng chi tiêu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: activeSlice != null ? activeSlice.color : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeSlice != null
                              ? AppFormatter.formatCurrency(activeSlice.amount)
                              : AppFormatter.formatCurrency(widget.totalAmount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (activeSlice != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${activeSlice.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: activeSlice.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Chú thích (Legend) tương tác dưới biểu đồ
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: slices.map((slice) {
              final isSelected = _selectedCategory == slice.category;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedCategory == slice.category) {
                      _selectedCategory = null;
                    } else {
                      _selectedCategory = slice.category;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? slice.color.withValues(alpha: 0.15)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? slice.color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: slice.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        slice.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${slice.percentage.toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter vẽ biểu đồ vành khăn thuần Canvas
class _DonutChartPainter extends CustomPainter {
  final List<DonutSliceData> slices;
  final double animationProgress;
  final String? selectedCategory;

  _DonutChartPainter({
    required this.slices,
    required this.animationProgress,
    this.selectedCategory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty || animationProgress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final normalRadius = (size.width - 40) / 2;
    const normalStrokeWidth = 24.0;
    const selectedStrokeWidth = 32.0;

    // Khoảng cách góc giữa các lát cắt (gap in radians)
    final double gap = slices.length > 1 ? 0.04 : 0.0;
    final double totalAvailableSweep = 2 * pi - (slices.length * gap);

    double currentStartAngle = -pi / 2; // Bắt đầu ở đỉnh 12 giờ

    for (final slice in slices) {
      final isSelected = selectedCategory == slice.category;
      final sweepAngle = (slice.percentage / 100) * totalAvailableSweep * animationProgress;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? selectedStrokeWidth : normalStrokeWidth
        ..color = slice.color
        ..strokeCap = StrokeCap.round;

      final radius = isSelected ? normalRadius + 2 : normalRadius;
      final rect = Rect.fromCircle(center: center, radius: radius);

      if (sweepAngle > 0.01) {
        canvas.drawArc(
          rect,
          currentStartAngle,
          sweepAngle,
          false,
          paint,
        );
      }

      currentStartAngle += sweepAngle + (gap * animationProgress);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.slices != slices;
  }
}
