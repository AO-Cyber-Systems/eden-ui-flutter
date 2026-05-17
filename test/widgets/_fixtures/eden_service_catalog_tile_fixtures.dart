// Do NOT regenerate via LLM — hand-built fixtures for EdenServiceCatalogTile.
//
// These fixtures power obj 016-01 tests. Salon names are real-world MangoMint
// competitive landscape (Women's Haircut / Full Color / etc.). Trades + medical
// fixtures prove the widget is generic across verticals.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenServiceCatalogTileFixtures {
  EdenServiceCatalogTileFixtures._();

  static const EdenServiceStaff _aisha =
      EdenServiceStaff(id: 'st-aisha', displayName: 'Aisha A.', initials: 'AA');
  static const EdenServiceStaff _brendan = EdenServiceStaff(
      id: 'st-brendan', displayName: 'Brendan B.', initials: 'BB');
  static const EdenServiceStaff _carla =
      EdenServiceStaff(id: 'st-carla', displayName: 'Carla C.', initials: 'CC');
  static const EdenServiceStaff _david =
      EdenServiceStaff(id: 'st-david', displayName: 'David D.', initials: 'DD');
  static const EdenServiceStaff _elena =
      EdenServiceStaff(id: 'st-elena', displayName: 'Elena E.', initials: 'EE');
  static const EdenServiceStaff _faisal = EdenServiceStaff(
      id: 'st-faisal', displayName: 'Faisal F.', initials: 'FF');
  static const EdenServiceStaff _gina =
      EdenServiceStaff(id: 'st-gina', displayName: 'Gina G.', initials: 'GG');
  static const EdenServiceStaff _hassan = EdenServiceStaff(
      id: 'st-hassan', displayName: 'Hassan H.', initials: 'HH');

  static EdenServiceCatalogEntry salonHaircut() {
    return const EdenServiceCatalogEntry(
      id: 'salon-haircut',
      name: "Women's Haircut",
      durationMinutes: 45,
      priceCents: 8500,
      capableStaff: [_aisha, _brendan, _carla],
      customizations: [
        EdenServiceCustomization(
            id: 'c-toner', label: 'Add color toner', priceCentsDelta: 1500),
        EdenServiceCustomization(
            id: 'c-blowout', label: 'Add blowout', priceCentsDelta: 2500),
      ],
      photoUrl: 'https://example.com/haircut.jpg',
      categoryId: 'hair-services',
    );
  }

  static EdenServiceCatalogEntry salonHaircutNoPhoto() {
    return const EdenServiceCatalogEntry(
      id: 'salon-haircut',
      name: "Women's Haircut",
      durationMinutes: 45,
      priceCents: 8500,
      capableStaff: [_aisha, _brendan, _carla],
      customizations: [
        EdenServiceCustomization(
            id: 'c-toner', label: 'Add color toner', priceCentsDelta: 1500),
        EdenServiceCustomization(
            id: 'c-blowout', label: 'Add blowout', priceCentsDelta: 2500),
      ],
      categoryId: 'hair-services',
    );
  }

  static EdenServiceCatalogEntry salonHaircutNoStaff() {
    return const EdenServiceCatalogEntry(
      id: 'salon-haircut',
      name: "Women's Haircut",
      durationMinutes: 45,
      priceCents: 8500,
      customizations: [
        EdenServiceCustomization(
            id: 'c-toner', label: 'Add color toner', priceCentsDelta: 1500),
      ],
      categoryId: 'hair-services',
    );
  }

  static EdenServiceCatalogEntry salonHaircutNoCustomizations() {
    return const EdenServiceCatalogEntry(
      id: 'salon-haircut',
      name: "Women's Haircut",
      durationMinutes: 45,
      priceCents: 8500,
      capableStaff: [_aisha, _brendan, _carla],
      categoryId: 'hair-services',
    );
  }

  static EdenServiceCatalogEntry salon5Staff() {
    return const EdenServiceCatalogEntry(
      id: 'salon-haircut',
      name: "Women's Haircut",
      durationMinutes: 45,
      priceCents: 8500,
      capableStaff: [_aisha, _brendan, _carla, _david, _elena],
    );
  }

  static EdenServiceCatalogEntry salon6Staff() {
    return const EdenServiceCatalogEntry(
      id: 'salon-haircut',
      name: "Women's Haircut",
      durationMinutes: 45,
      priceCents: 8500,
      capableStaff: [_aisha, _brendan, _carla, _david, _elena, _faisal],
    );
  }

  static EdenServiceCatalogEntry salon8Staff() {
    return const EdenServiceCatalogEntry(
      id: 'salon-haircut',
      name: "Women's Haircut",
      durationMinutes: 45,
      priceCents: 8500,
      capableStaff: [
        _aisha,
        _brendan,
        _carla,
        _david,
        _elena,
        _faisal,
        _gina,
        _hassan
      ],
    );
  }

  static EdenServiceCatalogEntry salonLongName() {
    return const EdenServiceCatalogEntry(
      id: 'salon-balayage',
      name: 'Premium Signature Vanilla Hazelnut Color Highlights Service',
      durationMinutes: 195,
      priceCents: 28500,
      capableStaff: [
        _aisha,
        _brendan,
        _carla,
        _david,
        _elena,
        _faisal,
        _gina,
        _hassan
      ],
      customizations: [
        EdenServiceCustomization(id: 'c-toner', label: 'Toner refresh'),
        EdenServiceCustomization(id: 'c-extend', label: 'Extended root work'),
        EdenServiceCustomization(id: 'c-bond', label: 'Bond builder'),
        EdenServiceCustomization(id: 'c-glaze', label: 'Glaze finish'),
      ],
    );
  }

  /// Trades-vertical demo — proves widget is generic across verticals.
  static EdenServiceCatalogEntry tradesInstall() {
    return const EdenServiceCatalogEntry(
      id: 'install-water-heater',
      name: 'Install water heater',
      durationMinutes: 120,
      priceCents: 45000,
      capableStaff: [
        EdenServiceStaff(
            id: 'tr-plumber-1', displayName: 'Plumber A', initials: 'PA'),
        EdenServiceStaff(
            id: 'tr-plumber-2', displayName: 'Plumber B', initials: 'PB'),
      ],
    );
  }
}
