import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/services/receipt_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/expenses/screens/expense_history_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/scan/screens/camera_scan_screen.dart';
import 'features/statistics/screens/statistics_screen.dart';

/// App Root Widget của BillLens
class BillLensApp extends StatelessWidget {
  const BillLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BillLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}

/// Khung điều hướng chính với NavigationBar 3 tab và nút Quét nổi bật
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Khởi tạo và tải dữ liệu từ SQLite ngay khi app khởi động
    ReceiptController.instance.loadReceipts();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openCameraScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScanScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onNavigateToScan: _openCameraScan,
        onNavigateToExpenses: () => _onTabSelected(1),
      ),
      const ExpenseHistoryScreen(),
      const StatisticsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCameraScan,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        tooltip: 'Quét hóa đơn mới',
        child: const Icon(Icons.qr_code_scanner_rounded, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Hóa đơn',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline_rounded),
              selectedIcon: Icon(Icons.pie_chart_rounded),
              label: 'Thống kê',
            ),
          ],
        ),
      ),
    );
  }
}
