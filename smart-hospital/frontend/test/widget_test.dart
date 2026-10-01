import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hospital/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartHospitalApp());
  });
}
