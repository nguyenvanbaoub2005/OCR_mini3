# 📱 BillLens – Smart Receipt & Expense Tracker
> **Ứng dụng di động theo dõi chi tiêu & quản lý hóa đơn thông minh**  
> Xây dựng bằng **Flutter & Dart**, ứng dụng **On-Device OCR (Google ML Kit)** và trực quan hóa dữ liệu thuần **CustomPainter**.

[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.4-blue.svg)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2F%20Layered-emerald.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-orange.svg)]()
[![Offline-First](https://img.shields.io/badge/Database-SQLite%20(Offline--First)-green.svg)]()
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)]()

---

## 🌟 1. Giới thiệu tổng quan (Project Overview)

**BillLens** là đồ án ứng dụng di động hoàn chỉnh giải quyết bài toán quản lý tài chính cá nhân một cách tự động, bảo mật và tiện lợi. 

Thay vì phải nhập thủ công từng khoản chi, người dùng chỉ cần chụp ảnh hoặc chọn ảnh hóa đơn bán lẻ, hệ thống trí tuệ nhân tạo chạy trực tiếp trên thiết bị (**On-Device AI**) sẽ nhận diện ký tự quang học (**OCR**), trích xuất thông tin trọng yếu (Tên cửa hàng, Ngày giao dịch, Tổng tiền) và trực quan hóa báo cáo tài chính bằng các biểu đồ tương tác sinh động.

### 🛡️ Nguyên tắc cốt lõi (Core Principles)
1. **Offline-First & Data Privacy**: 100% dữ liệu hóa đơn, hình ảnh và cơ sở dữ liệu được lưu cục bộ trên máy người dùng qua SQLite. Không gửi ảnh lên máy chủ đám mây, bảo mật quyền riêng tư tài chính tuyệt đối.
2. **On-Device Machine Learning**: Sử dụng **Google ML Kit Text Recognition** chạy trực tiếp bằng phần cứng điện thoại, không cần kết nối mạng Internet.
3. **Pure CustomPainter Visuals**: Toàn bộ biểu đồ hình vành khăn (**Donut Chart**) và biểu đồ cột tuần (**Weekly Bar Chart**) được lập trình vẽ thuần bằng `CustomPainter` và `Canvas` API, **tuyệt đối không phụ thuộc thư viện biểu đồ bên thứ 3**.
4. **Clean Layered Architecture**: Tách biệt rõ ràng các tầng giao diện (UI), điều khiển trạng thái (Controller), tầng truy xuất dữ liệu (Repository), và dịch vụ phần cứng (Services).

---

## 🚀 2. Các tính năng chính (Key Features)

### 📸 A. Chụp ảnh & Căn chỉnh hóa đơn (Camera & Crop)
- **Camera Scan chuyên dụng**: Khung ngắm định vị hóa đơn (`CameraOverlayPainter`), chạm để lấy nét (`Tap-to-focus`), hỗ trợ bật/tắt đèn Flash (`off`, `torch`, `auto`).
- **Cắt xén ảnh thông minh**: Tích hợp `image_cropper` giúp người dùng loại bỏ phần thừa, tăng độ chính xác khi quét OCR.
- **Lưu trữ ảnh nội bộ**: Lưu trữ an toàn trong thư mục tài liệu cục bộ của ứng dụng (`path_provider`).

### 🔍 B. Nhận diện chữ & Bóc tách thông minh (OCR & Regex Heuristic Engine)
- **Google ML Kit Text Recognition**: Nhận dạng ký tự quang học tốc độ cao, hoạt động ngoại tuyến.
- **Heuristic Regex Parser**:
  - **Tên cửa hàng (Merchant)**: Nhận diện các chuỗi siêu thị/bán lẻ lớn (WinMart, Circle K, FPT Shop, GS25, Highland, Phúc Long, v.v.), loại bỏ dòng tiêu đề rác (blacklist: HÓA ĐƠN, VAT, TAX).
  - **Tổng tiền (Total Amount)**: Hỗ trợ linh hoạt các định dạng tiền tệ Việt Nam (`150.000 đ`, `150,000 VND`, `1.500.000`).
  - **Ngày giao dịch (Date)**: Trích xuất chuẩn xác các định dạng ngày tháng (`DD/MM/YYYY`, `DD-MM-YYYY`, `DD.MM.YYYY`).

### ✍️ C. Kiểm tra & Chỉnh sửa trước khi lưu (Review Screen)
- **Nguyên tắc an toàn dữ liệu**: Hóa đơn sau OCR không bao giờ lưu tự động vào database mà luôn hiển thị màn hình Review để người dùng kiểm tra, chỉnh sửa tên cửa hàng, ngày, số tiền, ghi chú và chọn danh mục chi tiêu chuẩn.
- **Xem đối chiếu**: Hiển thị ảnh chụp hóa đơn thu nhỏ kèm bảng xem nội dung thô (**Raw OCR Text**).

### 💾 D. Quản lý cơ sở dữ liệu cục bộ (SQLite Local Database)
- Hệ quản trị SQLite nội bộ (`sqflite`), hỗ trợ đầy đủ các thao tác **CRUD**:
  - Thêm mới hóa đơn (`insertReceipt`).
  - Đọc danh sách sắp xếp theo thời gian (`getAllReceipts`).
  - Cập nhật thông tin (`updateReceipt`).
  - Xóa hóa đơn và đồng thời xóa file ảnh tương ứng (`deleteReceipt`).
- Tích hợp 4 bản ghi dữ liệu mẫu ban đầu (WinMart, Circle K, FPT Shop, Bookstore) phục vụ kiểm thử ngay khi cài đặt.

### 📜 E. Lịch sử chi tiêu & Bộ lọc đa năng (History & Search)
- **Tìm kiếm thời gian thực**: Tìm theo tên cửa hàng hoặc nội dung ghi chú.
- **Lọc theo danh mục (Category Chips)**: Thanh cuộn ngang hiển thị các nhóm chi tiêu chuẩn (Thực phẩm, Nghiên cứu, Du lịch, Thiết bị, Giải trí, Khác) kèm số lượng và màu sắc đại diện.
- **Sắp xếp linh hoạt**: Mới nhất, Cũ nhất, Số tiền cao nhất, Số tiền thấp nhất.
- **Vuốt để xóa (Dismissible)**: Thao tác vuốt sang trái tiện lợi kèm hộp thoại xác nhận an toàn.

### 📊 F. Báo cáo & Trực quan hóa dữ liệu thuần `CustomPainter`
- **Biểu đồ hình vành khăn (CategoryDonutChart)**:
  - Phân bổ chi tiêu theo danh mục với hiệu ứng quét góc mượt mà (`AnimationController`).
  - Tâm biểu đồ thông minh: chạm vào danh mục để xem chi tiết số tiền và tỉ trọng `%`.
  - Hàng chú thích (Legend) tương tác.
- **Biểu đồ cột chi tiêu 7 ngày (WeeklyExpenseChart)**:
  - Thể hiện chi tiêu theo từng ngày trong tuần.
  - Cột hoạt họa mọc từ đáy lên, phân biệt ngày hôm nay, chạm vào cột để xem số tiền.
- **Bảng xếp hạng chi tiêu**: Xếp hạng các nhóm hàng từ cao xuống thấp kèm thanh tiến trình tỉ trọng.
- **Bộ lọc chu kỳ**: Xem theo *Tuần này*, *Tháng này*, hoặc *Toàn bộ*.

---

## 🏗️ 3. Cấu trúc thư mục dự án (Architecture & Folder Structure)

```text
lib/
├── app.dart                                # Root MaterialApp & MainNavigationShell (3 Tab Navigation)
├── main.dart                               # Entry point, khởi tạo WidgetsFlutterBinding & SQLite
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                 # Bảng màu chuẩn Emerald/Teal Material 3
│   │   └── app_constants.dart              # Hằng số danh mục chi tiêu, icon, màu sắc
│   ├── services/
│   │   ├── ocr_service.dart                # Giao tiếp Google ML Kit Text Recognition
│   │   ├── receipt_controller.dart         # State management kế thừa ChangeNotifier
│   │   ├── receipt_image_storage_service.dart # Quản lý lưu trữ/xóa file ảnh cục bộ
│   │   └── receipt_parser_service.dart     # Heuristic Regex Engine bóc tách thông tin
│   ├── theme/
│   │   └── app_theme.dart                  # Cấu hình giao diện Material 3
│   └── utils/
│       └── currency_formatter.dart         # Định dạng tiền tệ VND & ngày tháng
├── data/
│   ├── database/
│   │   └── app_database.dart               # Cấu hình SQLite, tạo bảng receipts & seed data
│   ├── models/
│   │   ├── receipt_data.dart               # DTO chứa kết quả trích xuất sau Regex Parser
│   │   └── receipt_model.dart              # Model thực thể hóa đơn lưu trong SQLite
│   └── repositories/
│       └── receipt_repository.dart         # Repository xử lý truy vấn SQL CRUD
└── features/
    ├── home/
    │   ├── screens/
    │   │   └── home_screen.dart            # Dashboard tổng quan, thống kê nhanh, hóa đơn gần đây
    │   └── widgets/
    │       ├── quick_stat_card.dart        # Thẻ thống kê chi tiêu tháng/tuần
    │       ├── recent_receipt_item.dart    # Thẻ hiển thị hóa đơn gần đây
    │       └── scan_action_banner.dart     # Banner kêu gọi quét hóa đơn
    ├── scan/
    │   ├── screens/
    │   │   ├── camera_scan_screen.dart     # Màn hình camera chụp ảnh hóa đơn
    │   │   ├── image_preview_screen.dart   # Xem lại & cắt xén ảnh
    │   │   └── ocr_processing_screen.dart  # Chạy OCR & hiển thị kết quả phân tích
    │   └── widgets/
    │       └── camera_overlay_painter.dart # Khung ngắm vẽ bằng CustomPainter
    ├── receipt/
    │   └── screens/
    │       ├── receipt_review_screen.dart  # Kiểm tra, chỉnh sửa & lưu hóa đơn
    │       └── receipt_detail_screen.dart  # Chi tiết hóa đơn, zoom ảnh, raw text, sửa & xóa
    ├── expenses/
    │   └── screens/
    │       └── expense_history_screen.dart # Lịch sử chi tiêu, tìm kiếm, lọc chip, sắp xếp
    └── statistics/
        ├── screens/
        │   └── statistics_screen.dart      # Màn hình thống kê chi tiêu tổng hợp
        └── widgets/
            ├── category_donut_chart.dart   # Biểu đồ Donut vẽ bằng CustomPainter
            ├── weekly_expense_chart.dart   # Biểu đồ cột 7 ngày vẽ bằng CustomPainter
            └── category_breakdown_item.dart# Bảng xếp hạng chi tiêu danh mục
```

---

## 🛠️ 4. Hướng dẫn cài đặt & Chạy ứng dụng (Getting Started)

### Yêu cầu môi trường
- **Flutter SDK**: `>= 3.20.0`
- **Dart SDK**: `>= 3.4.0`
- **Android Studio / VS Code / Antigravity IDE**
- **Android Device / Emulator**: Android 5.0 (API Level 21) trở lên.

### Các bước cài đặt

1. **Clone repository**:
   ```bash
   git clone https://github.com/nguyenvanbaoub2005/OCR_mini3.git
   cd OCR_mini3
   ```

2. **Cài đặt các thư viện phụ thuộc**:
   ```bash
   flutter pub get
   ```

3. **Chạy kiểm thử tự động (Unit & Widget Tests)**:
   ```bash
   flutter test
   ```

4. **Kiểm tra phân tích mã nguồn (Flutter Analyze)**:
   ```bash
   flutter analyze
   ```

5. **Chạy ứng dụng trên thiết bị Android (hoặc iOS)**:
   - Cắm điện thoại qua cáp USB và bật **Gỡ lỗi USB (USB Debugging)**.
   - Chạy lệnh:
     ```bash
     flutter run
     ```

---

## 🧪 5. Kết quả kiểm thử tự động (Automated Tests)

Dự án bao gồm bộ Unit Test hoàn chỉnh bao phủ toàn bộ các tầng nghiệp vụ:
- `test/receipt_parser_test.dart`:
  - ✅ Phân tích hóa đơn WinMart theo ví dụ mẫu.
  - ✅ Hỗ trợ tất cả các định dạng tiền tệ (`.`, `,`, `đ`, `VND`).
  - ✅ Nhận diện chính xác định dạng ngày tháng `DD/MM/YYYY`, `DD-MM-YYYY`, `DD.MM.YYYY`.
  - ✅ Cơ chế lọc Blacklist và nhận diện chuỗi siêu thị của `MerchantParser`.
- `test/receipt_repository_test.dart`:
  - ✅ Chèn hóa đơn mới (`Insert`) và đọc lại theo ID (`GetById`).
  - ✅ Đọc toàn bộ danh sách hóa đơn (`GetAll`).
  - ✅ Cập nhật thông tin (`Update`).
  - ✅ Xóa hóa đơn (`Delete`).
  - ✅ Thống kê tổng tiền theo từng danh mục (`GetTotalsByCategory`).
- `test/widget_test.dart`:
  - ✅ Smoke test khởi chạy giao diện `BillLensApp`.

---

## 👨‍💻 Tác giả & Đồ án
- **Ứng dụng**: BillLens – Smart Receipt & Expense Tracker
- **Ngôn ngữ & Nền tảng**: Dart & Flutter
- **Repository**: [https://github.com/nguyenvanbaoub2005/OCR_mini3](https://github.com/nguyenvanbaoub2005/OCR_mini3)
