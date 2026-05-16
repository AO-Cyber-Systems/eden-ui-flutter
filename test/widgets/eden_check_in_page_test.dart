import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_check_in_page_fixtures.dart';

Widget wrap(Widget child) => MaterialApp(home: child);

EdenCheckInPage _page({
  EdenCheckInAppointment? appointment,
  EdenGpsStatus gpsStatus = EdenGpsStatus.high,
  double? gpsAccuracyMeters = 5.2,
  EdenLatLng? gpsPosition,
  List<EdenCheckInEvent> events = const [],
  Future<void> Function(EdenCheckInSubmission)? onSubmit,
  String? appBarTitle,
}) {
  return EdenCheckInPage(
    appointment: appointment ?? EdenCheckInPageFixtures.apptHvac(),
    gpsStatus: gpsStatus,
    gpsAccuracyMeters: gpsAccuracyMeters,
    gpsPosition: gpsPosition ?? EdenCheckInPageFixtures.sfPos(),
    events: events,
    onSubmit: onSubmit,
    appBarTitle: appBarTitle,
  );
}

void main() {
  group('EdenCheckInPage — composition smoke', () {
    testWidgets('renders Scaffold + AppBar with default title',
        (tester) async {
      await tester.pumpWidget(wrap(_page()));
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      expect(find.text('Check In / Out'), findsOneWidget);
    });

    testWidgets('AppBar title overridable via appBarTitle', (tester) async {
      await tester.pumpWidget(wrap(_page(appBarTitle: 'Custom Title')));
      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Check In / Out'), findsNothing);
    });

    testWidgets('renders appointment title and address', (tester) async {
      await tester.pumpWidget(wrap(_page()));
      expect(find.text('HVAC Repair — Johnson'), findsOneWidget);
      expect(find.text('742 Evergreen Terrace'), findsOneWidget);
    });
  });

  group('EdenCheckInPage — appointment card', () {
    testWidgets('custom appointment icon visible', (tester) async {
      await tester
          .pumpWidget(wrap(_page(appointment: EdenCheckInPageFixtures.apptMedical())));
      expect(find.byIcon(Icons.medical_services_outlined),
          findsAtLeastNWidgets(1));
    });

    testWidgets('default appointment icon (Icons.event_available)',
        (tester) async {
      await tester.pumpWidget(wrap(_page()));
      expect(find.byIcon(Icons.event_available), findsAtLeastNWidgets(1));
    });
  });

  group('EdenCheckInPage — GPS status card Signal row', () {
    testWidgets('high status → "High" label visible', (tester) async {
      await tester.pumpWidget(wrap(_page(gpsStatus: EdenGpsStatus.high)));
      expect(find.text('High'), findsAtLeastNWidgets(1));
    });

    testWidgets('moderate status → "Moderate" label visible',
        (tester) async {
      await tester.pumpWidget(wrap(_page(gpsStatus: EdenGpsStatus.moderate)));
      expect(find.text('Moderate'), findsAtLeastNWidgets(1));
    });

    testWidgets('poor status → "Poor" label visible', (tester) async {
      await tester.pumpWidget(wrap(_page(gpsStatus: EdenGpsStatus.poor)));
      expect(find.text('Poor'), findsAtLeastNWidgets(1));
    });

    testWidgets('unavailable status → "Unavailable" label visible',
        (tester) async {
      await tester.pumpWidget(wrap(_page(
        gpsStatus: EdenGpsStatus.unavailable,
        gpsPosition: null,
        gpsAccuracyMeters: null,
      )));
      expect(find.text('Unavailable'), findsAtLeastNWidgets(1));
    });
  });

  group('EdenCheckInPage — GPS status card Accuracy/Coordinates/Geofence',
      () {
    testWidgets('accuracy 5.2 → "5.2m" visible', (tester) async {
      await tester.pumpWidget(wrap(_page(gpsAccuracyMeters: 5.2)));
      expect(find.text('5.2m'), findsOneWidget);
    });

    testWidgets('coords render with 5 decimals', (tester) async {
      await tester.pumpWidget(wrap(_page()));
      expect(find.text('37.77490, -122.41940'), findsOneWidget);
    });

    testWidgets('null position → "Unknown" coords row', (tester) async {
      await tester.pumpWidget(wrap(_page(
        gpsStatus: EdenGpsStatus.unavailable,
        gpsPosition: null,
        gpsAccuracyMeters: null,
      )));
      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('high status → "Within geofence" badge', (tester) async {
      await tester.pumpWidget(wrap(_page(gpsStatus: EdenGpsStatus.high)));
      expect(find.text('Within geofence'), findsOneWidget);
    });

    testWidgets('poor status → "Outside geofence" badge', (tester) async {
      await tester.pumpWidget(wrap(_page(gpsStatus: EdenGpsStatus.poor)));
      expect(find.text('Outside geofence'), findsOneWidget);
    });
  });

  group('EdenCheckInPage — check-in history', () {
    testWidgets('empty events → history section NOT rendered',
        (tester) async {
      await tester.pumpWidget(wrap(_page(events: const [])));
      expect(find.text("Today's Activity"), findsNothing);
    });

    testWidgets('1 check_in → 1 history row with "Checked in"',
        (tester) async {
      await tester.pumpWidget(wrap(_page(events: [
        EdenCheckInPageFixtures.checkInEvent(),
      ])));
      expect(find.text("Today's Activity"), findsOneWidget);
      expect(find.text('Checked in'), findsOneWidget);
    });

    testWidgets('check_in + check_out → 2 rows', (tester) async {
      await tester.pumpWidget(wrap(_page(events: [
        EdenCheckInPageFixtures.checkInEvent(),
        EdenCheckInPageFixtures.checkOutEvent(),
      ])));
      expect(find.text('Checked in'), findsOneWidget);
      expect(find.text('Checked out'), findsOneWidget);
    });

    testWidgets('verified event → trailing "Verified" badge visible',
        (tester) async {
      await tester.pumpWidget(wrap(_page(events: [
        EdenCheckInPageFixtures.checkInEvent(),
      ])));
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('unverified event → no "Verified" badge', (tester) async {
      await tester.pumpWidget(wrap(_page(events: [
        EdenCheckInPageFixtures.unverifiedCheckIn(),
      ])));
      expect(find.text('Verified'), findsNothing);
    });
  });

  group('EdenCheckInPage — notes input', () {
    testWidgets('notes TextField with label visible', (tester) async {
      await tester.pumpWidget(wrap(_page()));
      expect(find.text('Notes (optional)'), findsOneWidget);
    });
  });

  group('EdenCheckInPage — action button state machine', () {
    testWidgets('no events → "Check In" button visible', (tester) async {
      await tester.pumpWidget(wrap(_page(
        events: const [],
        onSubmit: (_) async {},
      )));
      expect(find.text('Check In'), findsOneWidget);
      expect(find.text('Check Out'), findsNothing);
    });

    testWidgets('check_in only → "Check Out" button visible',
        (tester) async {
      await tester.pumpWidget(wrap(_page(
        events: [EdenCheckInPageFixtures.checkInEvent()],
        onSubmit: (_) async {},
      )));
      expect(find.text('Check Out'), findsOneWidget);
      // Banner present.
      expect(find.textContaining('Checked in at'), findsOneWidget);
    });

    testWidgets('check_in + check_out → "Appointment complete" container',
        (tester) async {
      await tester.pumpWidget(wrap(_page(
        events: [
          EdenCheckInPageFixtures.checkInEvent(),
          EdenCheckInPageFixtures.checkOutEvent(),
        ],
        onSubmit: (_) async {},
      )));
      expect(find.text('Appointment complete'), findsOneWidget);
      expect(find.text('Check In'), findsNothing);
      expect(find.text('Check Out'), findsNothing);
    });
  });

  group('EdenCheckInPage — submit behavior', () {
    testWidgets('tap Check In fires onSubmit with checkIn submission',
        (tester) async {
      final (captured, submit) = EdenCheckInPageFixtures.recorder();
      await tester.pumpWidget(wrap(_page(onSubmit: submit)));
      await tester.tap(find.text('Check In'));
      await tester.pumpAndSettle();
      expect(captured, hasLength(1));
      expect(captured.first.type, EdenCheckInEventType.checkIn);
      expect(captured.first.latitude, closeTo(37.7749, 0.001));
      expect(captured.first.longitude, closeTo(-122.4194, 0.001));
      expect(captured.first.accuracy, closeTo(5.2, 0.001));
      expect(captured.first.isGeofenceVerified, isTrue);
      expect(captured.first.notes, isNull);
    });

    testWidgets('tap Check In with notes — submission.notes set',
        (tester) async {
      final (captured, submit) = EdenCheckInPageFixtures.recorder();
      await tester.pumpWidget(wrap(_page(onSubmit: submit)));
      await tester.enterText(find.byType(TextField).first, 'Late arrival');
      await tester.tap(find.text('Check In'));
      await tester.pumpAndSettle();
      expect(captured.first.notes, 'Late arrival');
    });

    testWidgets(
        'tap Check In when GPS unavailable → onSubmit NOT called + snack bar',
        (tester) async {
      final (captured, submit) = EdenCheckInPageFixtures.recorder();
      await tester.pumpWidget(wrap(_page(
        gpsStatus: EdenGpsStatus.unavailable,
        gpsPosition: null,
        gpsAccuracyMeters: null,
        onSubmit: submit,
      )));
      await tester.tap(find.text('Check In'));
      await tester.pump(); // start snack bar
      await tester.pump(const Duration(milliseconds: 100));
      expect(captured, isEmpty);
      expect(find.textContaining('GPS is not available'), findsOneWidget);
    });

    testWidgets('onSubmit throws → "Failed to check in" snack bar',
        (tester) async {
      await tester.pumpWidget(wrap(_page(
        onSubmit: EdenCheckInPageFixtures.failingSubmit('boom'),
      )));
      await tester.tap(find.text('Check In'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to check in'), findsOneWidget);
    });

    testWidgets('onSubmit: null → Check In button disabled', (tester) async {
      await tester.pumpWidget(wrap(_page(onSubmit: null)));
      final btn = tester.widget<FilledButton>(find.ancestor(
          of: find.text('Check In'), matching: find.byType(FilledButton)));
      expect(btn.onPressed, isNull);
    });
  });

  group('EdenCheckInPage — iPhone-narrow ≥390pt', () {
    testWidgets('renders without overflow at 390x800 with full data',
        (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(_page(events: [
        EdenCheckInPageFixtures.checkInEvent(),
        EdenCheckInPageFixtures.checkOutEvent(),
      ])));
      expect(find.text('HVAC Repair — Johnson'), findsOneWidget);
      // Verify GPS card and history card both rendered.
      expect(find.text("Today's Activity"), findsOneWidget);
    });
  });
}
