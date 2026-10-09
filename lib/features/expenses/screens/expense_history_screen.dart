import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/receipt_controller.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/receipt_model.dart';
import '../../receipt/screens/receipt_detail_screen.dart';
import '../../scan/screens/camera_scan_screen.dart';

enum SortOption {
  dateDesc('Mới nhất'),
  dateAsc('Cũ nhất'),
  totalDesc('Số tiền: Cao → Thấp'),
  totalAsc('Số tiền: Thấp → Cao');

  final String label;
  const SortOption(this.label);
}

/// Màn hình Lịch sử hóa đơn & Tìm kiếm, Lọc, Sắp xếp (Phase 8)
/// Tính năng chính:
/// - Tìm kiếm theo tên cửa hàng hoặc ghi chú
/// - Lọc theo từng danh mục chi tiêu (kèm số lượng & màu sắc chuẩn)
/// - Sắp xếp theo ngày (mới/cũ) hoặc số tiền (cao/thấp)
/// - Tổng kết số tiền & số lượng hóa đơn theo kết quả lọc
/// - Xem chi tiết hóa đơn (ReceiptDetailScreen)
/// - Vuốt để xóa (Dismissible) kèm dialog xác nhận
class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  SortOption _selectedSort = SortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'Tất cả';
      _selectedSort = SortOption.dateDesc;
    });
  }

  List<ReceiptModel> _filterAndSortReceipts(List<ReceiptModel> allReceipts) {
    List<ReceiptModel> filtered = allReceipts.where((receipt) {
      // 1. Lọc theo danh mục
      if (_selectedCategory != 'Tất cả' && receipt.category != _selectedCategory) {
        return false;
      }

      // 2. Lọc theo từ khóa tìm kiếm (merchant hoặc note)
      if (_searchQuery.isNotEmpty) {
        final merchantMatch = receipt.merchant.toLowerCase().contains(_searchQuery);
        final noteMatch = receipt.note != null && receipt.note!.toLowerCase().contains(_searchQuery);
        if (!merchantMatch && !noteMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // 3. Sắp xếp danh sách
    switch (_selectedSort) {
      case SortOption.dateDesc:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.dateAsc:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.totalDesc:
        filtered.sort((a, b) => b.total.compareTo(a.total));
        break;
      case SortOption.totalAsc:
        filtered.sort((a, b) => a.total.compareTo(b.total));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ReceiptController.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch Sử Hóa Đơn'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sắp xếp danh sách',
            initialValue: _selectedSort,
            onSelected: (option) {
              setState(() {
                _selectedSort = option;
              });
            },
            itemBuilder: (context) => SortOption.values.map((option) {
              return PopupMenuItem<SortOption>(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      _selectedSort == option ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      size: 18,
                      color: _selectedSort == option ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedSort == option ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedSort == option ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
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
          final filteredReceipts = _filterAndSortReceipts(allReceipts);
          final double filteredTotal = filteredReceipts.fold(0.0, (sum, item) => sum + item.total);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => controller.loadReceipts(),
            child: Column(
              children: [
                // 1. Ô tìm kiếm (Search Bar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo cửa hàng hoặc ghi chú...',
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),

                // 2. Thanh cuộn danh mục chi tiêu (Category Filter Chips)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    children: [
                      // Chip Tất cả
                      _buildCategoryChip(
                        category: 'Tất cả',
                        isSelected: _selectedCategory == 'Tất cả',
                        count: allReceipts.length,
                        icon: Icons.all_inclusive_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),

                      // Các danh mục chuẩn trong AppConstants
                      ...AppConstants.categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        final count = allReceipts.where((r) => r.category == category).length;
                        final color = AppConstants.getCategoryColor(category);
                        final icon = AppConstants.getCategoryIcon(category);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryChip(
                            category: category,
                            isSelected: isSelected,
                            count: count,
                            icon: icon,
                            color: color,
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // 3. Thanh tóm tắt kết quả lọc (Summary Header)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${filteredReceipts.length} hóa đơn',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_selectedCategory != 'Tất cả' || _searchQuery.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _resetFilters,
                              child: const Text(
                                '• Đặt lại',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Tổng: ${AppFormatter.formatCurrency(filteredTotal)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Danh sách hóa đơn hoặc Trạng thái trống (Empty State)
                Expanded(
                  child: filteredReceipts.isEmpty
                      ? _buildEmptyState(context, isAllEmpty: allReceipts.isEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredReceipts.length,
                          itemBuilder: (context, index) {
                            final receipt = filteredReceipts[index];
                            return _buildReceiptItemCard(context, receipt);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String category,
    required bool isSelected,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              category,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptItemCard(BuildContext context, ReceiptModel receipt) {
    final categoryColor = AppConstants.getCategoryColor(receipt.category);
    final categoryIcon = AppConstants.getCategoryIcon(receipt.category);

    return Dismissible(
      key: Key('receipt_${receipt.id}_${receipt.createdAt.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Xóa',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Xác nhận xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa hóa đơn "${receipt.merchant}" (${AppFormatter.formatCurrency(receipt.total)})?',
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
      },
      onDismissed: (direction) async {
        if (receipt.id != null) {
          await ReceiptController.instance.deleteReceipt(receipt.id!);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã xóa hóa đơn "${receipt.merchant}"'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReceiptDetailScreen(receipt: receipt),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon danh mục
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, color: categoryColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Thông tin hóa đơn
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.merchant,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            receipt.category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: AppColors.textMuted)),
                          const SizedBox(width: 6),
                          Text(
                            AppFormatter.formatDate(receipt.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (receipt.note != null && receipt.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          receipt.note!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Số tiền & mũi tên chuyển trang
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatter.formatCurrency(receipt.total),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isAllEmpty}) {
    if (isAllEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chưa có hóa đơn nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bắt đầu bằng việc quét hóa đơn đầu tiên từ camera hoặc thư viện ảnh.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Quét hóa đơn ngay'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy hóa đơn',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Không có hóa đơn nào khớp với bộ lọc hoặc từ khóa tìm kiếm của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Đặt lại bộ lọc'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
