import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// Dữ liệu chi tiêu theo từng ngày trong tuần
class DayExpenseData {
  final DateTime date;
  final String label; // "T2", "T3", "T4", "T5", "T6", "T7", "CN"
  final double amount;
  final bool isToday;

  const DayExpenseData({
    required this.date,
    required this.label,
    required this.amount,
    required this.isToday,
  });
}

/// Biểu đồ cột chi tiêu 7 ngày trong tuần
/// Yêu cầu đồ án: Vẽ thuần bằng CustomPainter, KHÔNG dùng thư viện ngoài
class WeeklyExpenseChart extends StatefulWidget {
  final List<DayExpenseData> weeklyData;

  const WeeklyExpenseChart({
    super.key,
    required this.weeklyData,
  });

  @override
  State<WeeklyExpenseChart> createState() => _WeeklyExpenseChartState();
}

class _WeeklyExpenseChartState extends State<WeeklyExpenseChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyExpenseChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyData != widget.weeklyData) {
      _animationController.reset();
      _animationController.forward();
      _selectedIndex = null;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxAmount = widget.weeklyData.fold(
      0.0,
      (max, day) => day.amount > max ? day.amount : max,
    );

    // Tính tổng chi tiêu trong tuần
    final totalWeek = widget.weeklyData.fold(0.0, (sum, day) => sum + day.amount);

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
          // Tiêu đề & Tổng chi trong tuần
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiêu trong tuần',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '7 ngày gần nhất',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatter.formatCurrency(totalWeek),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'Tổng tuần',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hiển thị thông tin cột được chạm vào
          if (_selectedIndex != null && _selectedIndex! < widget.weeklyData.length) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.weeklyData[_selectedIndex!].label} (${AppFormatter.formatDate(widget.weeklyData[_selectedIndex!].date)})',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    AppFormatter.formatCurrency(widget.weeklyData[_selectedIndex!].amount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
          ],

          // Vùng vẽ Biểu đồ cột CustomPainter
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return GestureDetector(
                  onTapUp: (details) {
                    final renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox == null) return;
                    final width = renderBox.size.width;
                    final itemWidth = width / widget.weeklyData.length;
                    final index = (details.localPosition.dx / itemWidth).floor();
                    if (index >= 0 && index < widget.weeklyData.length) {
                      setState(() {
                        _selectedIndex = _selectedIndex == index ? null : index;
                      });
                    }
                  },
                  child: CustomPaint(
                    size: const Size(double.infinity, 160),
                    painter: _WeeklyBarChartPainter(
                      data: widget.weeklyData,
                      maxAmount: maxAmount > 0 ? maxAmount : 100000,
                      animationProgress: _animation.value,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter vẽ các cột biểu đồ thuần Canvas
class _WeeklyBarChartPainter extends CustomPainter {
  final List<DayExpenseData> data;
  final double maxAmount;
  final double animationProgress;
  final int? selectedIndex;

  _WeeklyBarChartPainter({
    required this.data,
    required this.maxAmount,
    required this.animationProgress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final bottomPadding = 24.0;
    final topPadding = 16.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final count = data.length;
    final slotWidth = size.width / count;
    final barWidth = 18.0;

    // 1. Vẽ đường lưới ngang (Grid lines mờ)
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight * (i / 3));
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // 2. Vẽ từng cột chi tiêu
    for (int i = 0; i < count; i++) {
      final day = data[i];
      final isSelected = selectedIndex == i;
      final centerX = (i * slotWidth) + (slotWidth / 2);

      // Cột nền phía sau (Background Track)
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - (barWidth / 2),
          topPadding,
          barWidth,
          chartHeight,
        ),
        const Radius.circular(6),
      );
      final trackPaint = Paint()..color = AppColors.surfaceVariant;
      canvas.drawRRect(trackRect, trackPaint);

      // Cột giá trị thực tế (Active Bar)
      final normalizedHeight = (day.amount / maxAmount) * chartHeight * animationProgress;
      final barTop = topPadding + chartHeight - normalizedHeight;

      if (normalizedHeight > 0) {
        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - (barWidth / 2),
            barTop,
            barWidth,
            normalizedHeight,
          ),
          const Radius.circular(6),
        );

        final barPaint = Paint()
          ..color = isSelected
              ? AppColors.accent
              : (day.isToday ? AppColors.primary : AppColors.primaryLight);

        canvas.drawRRect(barRect, barPaint);
      }

      // 3. Vẽ nhãn thứ trong tuần (T2, T3, T4...)
      final textSpan = TextSpan(
        text: day.label,
        style: TextStyle(
          color: day.isToday
              ? AppColors.primary
              : (isSelected ? AppColors.textPrimary : AppColors.textSecondary),
          fontSize: 11,
          fontWeight: (day.isToday || isSelected) ? FontWeight.w700 : FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          centerX - (textPainter.width / 2),
          size.height - bottomPadding + 6,
        ),
      );

      // Chấm đánh dấu hôm nay (Today Dot)
      if (day.isToday) {
        final dotPaint = Paint()..color = AppColors.primary;
        canvas.drawCircle(
          Offset(centerX, size.height - 2),
          2.5,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.data != data;
  }
}
