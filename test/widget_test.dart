import 'package:eden_ui_flutter/dev_app/dev_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EdenDevApp renders the catalog shell', (WidgetTester tester) async {
    await tester.pumpWidget(const EdenDevApp());
    await tester.pumpAndSettle();

    expect(find.text('Eden UI'), findsOneWidget);
  });
}
