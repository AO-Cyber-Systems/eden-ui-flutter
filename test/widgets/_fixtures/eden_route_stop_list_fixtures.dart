// Do NOT regenerate via LLM — hand-built fixtures for EdenRouteStopList.
import 'package:eden_ui_flutter/eden_ui.dart';

/// Hand-built fixtures for EdenRouteStopList tests.
class EdenRouteStopListFixtures {
  EdenRouteStopListFixtures._();

  static final EdenRouteStopData stop1 = EdenRouteStopData(
    id: 's1',
    label: 'Acme Industrial',
    status: EdenRouteStopStatus.completed,
    estimatedArrival: DateTime(2026, 5, 16, 8, 30),
    address: const EdenAddress(
      streetLine1: '100 Main St',
      city: 'Boston',
      regionCode: 'MA',
      postalCode: '02101',
      countryCode: 'US',
    ),
    payloadGal: 250,
  );

  static final EdenRouteStopData stop2 = EdenRouteStopData(
    id: 's2',
    label: 'Beta Co',
    status: EdenRouteStopStatus.enRoute,
    estimatedArrival: DateTime(2026, 5, 16, 9, 45),
    address: const EdenAddress(
      streetLine1: '42 Oak Ave',
      city: 'Cambridge',
      regionCode: 'MA',
      postalCode: '02139',
      countryCode: 'US',
    ),
    payloadGal: 180,
  );

  static final EdenRouteStopData stop3 = EdenRouteStopData(
    id: 's3',
    label: 'Gamma LLC',
    status: EdenRouteStopStatus.pending,
    estimatedArrival: DateTime(2026, 5, 16, 11, 15),
    address: const EdenAddress(
      streetLine1: '789 Industrial Way',
      streetLine2: 'Suite B',
      city: 'Quincy',
      regionCode: 'MA',
      postalCode: '02169',
      countryCode: 'US',
    ),
    payloadGal: 500,
  );

  static final List<EdenRouteStopData> threeStops = [stop1, stop2, stop3];

  static const List<EdenRouteStopData> emptyList = <EdenRouteStopData>[];

  /// Long-label fixtures for ellipsis / iPhone-narrow tests.
  static final List<EdenRouteStopData> longLabels = [
    EdenRouteStopData(
      id: 'l1',
      label:
          'Massachusetts Industrial Heating Oil Cooperative Limited Partnership of Eastern Boston',
      status: EdenRouteStopStatus.pending,
      estimatedArrival: DateTime(2026, 5, 16, 8, 30),
      address: const EdenAddress(
        streetLine1: '12345 Extended Industrial Park Drive Suite 1500',
        city: 'Mississauga Ontario Canada Long Region Name',
        regionCode: 'ON',
        postalCode: 'L5N 1A1',
        countryCode: 'CA',
      ),
    ),
    EdenRouteStopData(
      id: 'l2',
      label: 'Another Extremely Long Customer Name That Goes On And On Forever',
      status: EdenRouteStopStatus.arrived,
      estimatedArrival: DateTime(2026, 5, 16, 10, 0),
      address: const EdenAddress(
        streetLine1: '99 Truly Lengthy Address Line Number One',
        city: 'Worcester',
        regionCode: 'MA',
        postalCode: '01609',
        countryCode: 'US',
      ),
    ),
  ];

  // Per-status single-stop fixtures.
  static const EdenRouteStopData pendingStop = EdenRouteStopData(
    id: 'pe',
    label: 'Pending Stop',
    status: EdenRouteStopStatus.pending,
  );
  static const EdenRouteStopData enRouteStop = EdenRouteStopData(
    id: 'er',
    label: 'En Route Stop',
    status: EdenRouteStopStatus.enRoute,
  );
  static const EdenRouteStopData arrivedStop = EdenRouteStopData(
    id: 'ar',
    label: 'Arrived Stop',
    status: EdenRouteStopStatus.arrived,
  );
  static const EdenRouteStopData completedStop = EdenRouteStopData(
    id: 'co',
    label: 'Completed Stop',
    status: EdenRouteStopStatus.completed,
  );
  static const EdenRouteStopData skippedStop = EdenRouteStopData(
    id: 'sk',
    label: 'Skipped Stop',
    status: EdenRouteStopStatus.skipped,
  );
  static const EdenRouteStopData noEtaStop = EdenRouteStopData(
    id: 'noeta',
    label: 'No ETA Stop',
  );
  static const EdenRouteStopData noAddressStop = EdenRouteStopData(
    id: 'noaddr',
    label: 'No Address Stop',
  );
  static final EdenRouteStopData noonEtaStop = EdenRouteStopData(
    id: 'noon',
    label: 'Noon Stop',
    estimatedArrival: DateTime(2026, 5, 16, 12, 0),
  );
  static final EdenRouteStopData midnightEtaStop = EdenRouteStopData(
    id: 'mid',
    label: 'Midnight Stop',
    estimatedArrival: DateTime(2026, 5, 16, 0, 0),
  );
  static final EdenRouteStopData afternoonEtaStop = EdenRouteStopData(
    id: 'pm',
    label: 'Afternoon Stop',
    estimatedArrival: DateTime(2026, 5, 16, 14, 5),
  );
  static final EdenRouteStopData stopWithAddress = EdenRouteStopData(
    id: 'sa',
    label: 'Stop With Address',
    address: const EdenAddress(
      streetLine1: '100 Main St',
      city: 'Boston',
      regionCode: 'MA',
      postalCode: '02101',
      countryCode: 'US',
    ),
  );
}
