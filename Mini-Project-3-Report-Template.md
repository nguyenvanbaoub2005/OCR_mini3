# MINI-PROJECT SHORT TECHNICAL REPORT
**Course:** Cross-Platform Mobile App Development (VKU)
**Mini-Project Title:** Mini-Project 3 - BillLens (Smart Receipt & Expense Tracker)
**Student Name:** Nguyễn Văn Bảo
**Submission Date:** 09/10/2026

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Team Members:**
  1. Nguyễn Văn Bảo — Student ID: [Mã Sinh Viên Của Bạn] — Role: Fullstack Developer — Contribution: 100%
* **Live Demo URL:** [Chạy cục bộ trên điện thoại]
* **GitHub Repository:** https://github.com/nguyenvanbaoub2005/OCR_mini3
* **Video Demo (Optional):** [Link Video nếu có, hoặc để trống]

---

## 2. FEATURE IMPLEMENTATION CHECKLIST
| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| 1 | On-Device Text Recognition (OCR) | Complete | Integrated Google ML Kit for offline text extraction from camera/gallery. |
| 2 | Heuristic Regex Data Extraction | Complete | Custom parser to extract Merchant Name, Date, and Total Amount using regex and blacklists. |
| 3 | Local Database Persistence | Complete | Utilized SQLite (sqflite) for complete offline data storage and privacy. |
| 4 | Native Data Visualization | Complete | Built Donut and Bar charts entirely from scratch using CustomPainter and Canvas APIs. |
| 5 | Clean UI/UX & State Management | Complete | Implemented Material 3 design and managed states cleanly using ChangeNotifier. |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE
* **Architecture Pattern:** Clean / Layered Architecture. The project separates concerns into clearly defined layers:
  - **Core/Services:** Contains business logic such as `ocr_service`, `receipt_parser_service`, and state management (`receipt_controller.dart`).
  - **Data Layer:** Includes SQLite database configuration (`app_database.dart`), DTO models, and `receipt_repository.dart` for CRUD operations.
  - **Features (UI):** Modularized feature folders (`home`, `scan`, `receipt`, `expenses`, `statistics`) containing screens and widgets.
* **State Management:** Utilized Flutter's built-in `ChangeNotifier` pattern for lightweight and reactive state management across screens.
* **Exception Handling:** Try-catch blocks are strategically placed around asynchronous operations (database queries, camera initialization, ML Kit parsing). User-friendly `SnackBar` messages are shown on errors instead of crashing the app.

---

## 4. TECHNICAL CHALLENGES & RESOLUTIONS
* **Challenge 1: Extracting Meaningful Data from Unstructured OCR Text**
  * *Description:* OCR engines return raw blocks of text. Identifying which block is the store name, the transaction date, and the total amount is difficult due to varying receipt formats in Vietnam.
  * *Resolution:* Developed a `ReceiptParserService` using Heuristic Regex rules. Implemented a blacklist to filter out tax/vat lines, used known merchant matching for big chains, and prioritized the largest currency value found for the total amount.
* **Challenge 2: Rendering Charts without Third-Party Libraries**
  * *Description:* Relying on external chart packages can bloat the app size and limit UI customization.
  * *Resolution:* Mastered the `CustomPainter` API to manually draw the `CategoryDonutChart` and `WeeklyExpenseChart`. Combined this with `AnimationController` to create smooth, native, and interactive chart rendering.
