import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_xz_report_fixtures.dart';

Widget wrap(Widget child, {double width = 700}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );

void main() {
  testWidgets('renders X-mid header given report.kind=xMid', (tester) async {
    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.sampleXReport,
    )));
    expect(find.text('X — Mid-shift read'), findsOneWidget);
  });

  testWidgets('renders Z-close header given report.kind=zClose',
      (tester) async {
    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.sampleZReport,
    )));
    expect(find.text('Z — End-of-shift'), findsOneWidget);
  });

  testWidgets('renders Summary section (Gross/Net/Tax/Tips)', (tester) async {
    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.sampleZReport,
    )));
    expect(find.text('Gross'), findsOneWidget);
    expect(find.text('Net'), findsOneWidget);
    expect(find.text('Tax'), findsOneWidget);
    // 'Tips' appears in both Summary KPI and By-employee column header.
    expect(find.text('Tips'), findsNWidgets(2));
  });

  testWidgets('renders By-tender DataTable with N rows', (tester) async {
    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.sampleZReport,
    )));
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text('Gift card'), findsOneWidget);
  });

  testWidgets('renders By-category DataTable with N rows', (tester) async {
    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.sampleZReport,
    )));
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Retail'), findsOneWidget);
  });

  testWidgets('renders By-employee DataTable with 4 columns', (tester) async {
    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.sampleZReport,
    )));
    expect(find.text('Sarah Vega'), findsOneWidget);
    expect(find.text('Marcus Lee'), findsOneWidget);
    // 4 column labels (Tips appears in both Summary and Employee — 2 total)
    expect(find.text('Employee'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Tips'), findsNWidgets(2));
  });

  testWidgets('renders Refunds & voids section', (tester) async {
    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.sampleZReport,
    )));
    expect(find.textContaining('Refunds:'), findsOneWidget);
    expect(find.textContaining('Voids:'), findsOneWidget);
  });

  testWidgets('Z report shows cashVariance; X report omits it',
      (tester) async {
    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.sampleZReport,
    )));
    expect(find.text('Cash variance: '), findsOneWidget);

    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.sampleXReport,
    )));
    expect(find.text('Cash variance: '), findsNothing);
  });

  testWidgets('printFriendly=true uses monospace body style', (tester) async {
    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.sampleZReport,
      printFriendly: true,
    )));
    // Pick a non-trivial body text and assert monospace fontFamily.
    final t = tester.widget<Text>(find.text('Gross'));
    expect(t.style?.fontFamily, 'monospace');
  });

  testWidgets("empty byEmployee shows 'No employee data' placeholder",
      (tester) async {
    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.emptyEmployeeReport,
    )));
    expect(find.text('No employee data'), findsOneWidget);
  });

  testWidgets('iPhone-narrow (390pt): tables horizontal-scroll fallback',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EdenXZReport(
            report: EdenXZReportFixtures.sampleZReport,
          ),
        ),
      ),
    ));
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Semantics: shift label + cash-variance label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenXZReport(
      report: EdenXZReportFixtures.sampleZReport,
    )));
    expect(
      find.bySemanticsLabel(RegExp(r'Shift report: Register 1')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Cash variance: \$.+')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
