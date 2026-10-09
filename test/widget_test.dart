import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_lens/app.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('BillLens app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BillLensApp());

    // Verify that BillLens dashboard loads properly
    expect(find.text('BillLens'), findsOneWidget);
    expect(find.text('Chi tiêu tháng này'), findsOneWidget);
    expect(find.text('Quét hóa đơn ngay'), findsOneWidget);
  });
}
