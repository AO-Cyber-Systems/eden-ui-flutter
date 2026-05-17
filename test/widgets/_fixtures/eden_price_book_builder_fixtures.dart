// Do NOT regenerate via LLM — hand-built fixtures for EdenPriceBookBuilder.
//
// Cross-vertical scenarios (HVAC trades, salon services, fuel pricing).
// Realistic baseFlatRate values reflect real ServiceTitan / Mangomint /
// fuel-jobber price points. Tier markup percentages mirror what real ops
// teams use (Gold = -10% loyalty discount, Commercial = +15% margin).

import 'package:eden_ui_flutter/src/widgets/eden_price_book_builder.dart';

class PriceBookFixtures {
  PriceBookFixtures._();

  /// HVAC flat-rate trades pricebook: 3 categories × 12 items + 2 tiers.
  static EdenPriceBookData hvac() {
    return EdenPriceBookData(
      categories: [
        EdenPriceBookCategory(
          id: 'cat-repair',
          name: 'Repair',
          items: [
            const EdenPriceBookItem(
              id: 'item-cap-replace',
              name: 'Capacitor replacement',
              description: 'Replace failed start/run capacitor on outdoor unit',
              baseFlatRate: 285.00,
              skuCode: 'HVAC-CAP-01',
              laborHoursLabel: '0.75h labor included',
            ),
            const EdenPriceBookItem(
              id: 'item-contactor-replace',
              name: 'Contactor replacement',
              description: '24V or line-voltage contactor swap',
              baseFlatRate: 325.00,
              skuCode: 'HVAC-CON-01',
              laborHoursLabel: '0.75h labor included',
            ),
            const EdenPriceBookItem(
              id: 'item-compressor-repair',
              name: 'Compressor repair',
              description: 'Replace or rebuild outdoor compressor',
              baseFlatRate: 1850.00,
              skuCode: 'HVAC-COMP-01',
              laborHoursLabel: '3h labor included',
              gbb: EdenPriceBookGoodBetterBest(
                goodPrice: 1850.00,
                goodLabel: 'Repair existing compressor',
                betterPrice: 2950.00,
                betterLabel: 'Replace with new compressor (1-yr warranty)',
                bestPrice: 4250.00,
                bestLabel: 'Replace + 5-yr parts & labor warranty',
              ),
              tierOverrides: {'tier-gold': 1665.00},
            ),
            const EdenPriceBookItem(
              id: 'item-coolant-recharge',
              name: 'Refrigerant recharge (R-410A, per lb)',
              description: 'Includes leak check and pressure reading',
              baseFlatRate: 95.00,
              skuCode: 'HVAC-R410A-LB',
            ),
          ],
        ),
        EdenPriceBookCategory(
          id: 'cat-replacement',
          name: 'Replacement',
          items: [
            const EdenPriceBookItem(
              id: 'item-system-3ton',
              name: '3-ton condenser + air handler install',
              description: 'Standard residential 3-ton high-efficiency system',
              baseFlatRate: 9850.00,
              skuCode: 'HVAC-SYS-3T',
              laborHoursLabel: '6h labor included',
              gbb: EdenPriceBookGoodBetterBest(
                goodPrice: 9850.00,
                goodLabel: '14 SEER baseline',
                betterPrice: 11800.00,
                betterLabel: '16 SEER mid-efficiency',
                bestPrice: 14250.00,
                bestLabel: '20 SEER high-efficiency + smart thermostat',
              ),
              tierOverrides: {'tier-gold': 9300.00},
            ),
            const EdenPriceBookItem(
              id: 'item-furnace-80',
              name: '80% AFUE gas furnace install',
              description: 'Standard 80,000 BTU residential furnace',
              baseFlatRate: 3850.00,
              skuCode: 'HVAC-FURN-80',
              laborHoursLabel: '4h labor included',
            ),
            const EdenPriceBookItem(
              id: 'item-thermostat-smart',
              name: 'Smart thermostat install',
              description: 'Nest / ecobee / Honeywell with Wi-Fi setup',
              baseFlatRate: 425.00,
              skuCode: 'HVAC-TS-SMART',
            ),
            const EdenPriceBookItem(
              id: 'item-air-handler',
              name: 'Air handler replacement',
              description: 'Standard residential air handler swap',
              baseFlatRate: 2450.00,
              skuCode: 'HVAC-AH-01',
              laborHoursLabel: '3h labor included',
            ),
          ],
        ),
        EdenPriceBookCategory(
          id: 'cat-maintenance',
          name: 'Maintenance',
          items: [
            const EdenPriceBookItem(
              id: 'item-tune-up',
              name: 'Annual AC tune-up',
              description: '21-point inspection + coil clean + filter replace',
              baseFlatRate: 149.00,
              skuCode: 'HVAC-TUNE-AC',
              tierOverrides: {'tier-gold': 99.00},
            ),
            const EdenPriceBookItem(
              id: 'item-tune-up-heat',
              name: 'Annual heating tune-up',
              description: '18-point furnace inspection + cleaning',
              baseFlatRate: 149.00,
              skuCode: 'HVAC-TUNE-HEAT',
              tierOverrides: {'tier-gold': 99.00},
            ),
            const EdenPriceBookItem(
              id: 'item-duct-clean',
              name: 'Duct cleaning (per system)',
              description: 'Full residential duct cleaning + sanitization',
              baseFlatRate: 595.00,
              skuCode: 'HVAC-DUCT-CLN',
              laborHoursLabel: '2h labor included',
            ),
            const EdenPriceBookItem(
              id: 'item-coil-clean',
              name: 'Evaporator coil deep clean',
              description: 'In-place chemical clean of indoor evaporator coil',
              baseFlatRate: 275.00,
              skuCode: 'HVAC-COIL-CLN',
            ),
          ],
        ),
      ],
      tiers: const [
        EdenPriceBookTier(
          id: 'tier-standard',
          name: 'Standard',
          description: 'Walk-in / one-time customer pricing',
        ),
        EdenPriceBookTier(
          id: 'tier-gold',
          name: 'Gold Member',
          defaultMarkupPct: -0.10,
          description: '10% discount for annual maintenance plan members',
        ),
      ],
      taxMatrix: const EdenPriceBookTaxMatrix(
        jurisdictions: ['CA'],
        itemTypes: ['service', 'parts', 'labor'],
        rates: {
          'CA': {'service': 0.0825, 'parts': 0.0825, 'labor': 0.0},
        },
      ),
    );
  }

  /// Salon service catalog: 4 categories × 18 items + 3 tiers.
  static EdenPriceBookData salon() {
    return EdenPriceBookData(
      categories: const [
        EdenPriceBookCategory(
          id: 'cat-hair',
          name: 'Hair',
          items: [
            EdenPriceBookItem(
              id: 'salon-cut-women',
              name: "Women's haircut",
              description: 'Cut + style with senior stylist',
              baseFlatRate: 75.00,
              tierOverrides: {'tier-member': 65.00, 'tier-vip': 55.00},
            ),
            EdenPriceBookItem(
              id: 'salon-cut-men',
              name: "Men's haircut",
              description: 'Cut + style',
              baseFlatRate: 45.00,
              tierOverrides: {'tier-member': 40.00, 'tier-vip': 35.00},
            ),
            EdenPriceBookItem(
              id: 'salon-blowout',
              name: 'Blow-dry & style',
              description: '45-min blowout with finishing',
              baseFlatRate: 55.00,
            ),
            EdenPriceBookItem(
              id: 'salon-keratin',
              name: 'Keratin smoothing treatment',
              description: 'Full keratin treatment with 4-month results',
              baseFlatRate: 285.00,
            ),
          ],
        ),
        EdenPriceBookCategory(
          id: 'cat-color',
          name: 'Color',
          items: [
            EdenPriceBookItem(
              id: 'salon-color-root',
              name: 'Root color touch-up',
              description: 'Single-process color for roots only',
              baseFlatRate: 95.00,
            ),
            EdenPriceBookItem(
              id: 'salon-color-full',
              name: 'Full color',
              description: 'Single-process all-over color',
              baseFlatRate: 145.00,
            ),
            EdenPriceBookItem(
              id: 'salon-balayage',
              name: 'Balayage',
              description: 'Hand-painted highlights, partial or full',
              baseFlatRate: 225.00,
              tierOverrides: {'tier-vip': 195.00},
            ),
            EdenPriceBookItem(
              id: 'salon-highlights-full',
              name: 'Full highlights',
              description: 'Foil highlights, full head',
              baseFlatRate: 195.00,
            ),
          ],
        ),
        EdenPriceBookCategory(
          id: 'cat-nails',
          name: 'Nails',
          items: [
            EdenPriceBookItem(
              id: 'salon-mani-classic',
              name: 'Classic manicure',
              description: '30-min manicure with regular polish',
              baseFlatRate: 35.00,
            ),
            EdenPriceBookItem(
              id: 'salon-mani-gel',
              name: 'Gel manicure',
              description: '45-min manicure with gel polish',
              baseFlatRate: 50.00,
            ),
            EdenPriceBookItem(
              id: 'salon-pedi-classic',
              name: 'Classic pedicure',
              description: '45-min pedicure with regular polish',
              baseFlatRate: 50.00,
            ),
            EdenPriceBookItem(
              id: 'salon-pedi-deluxe',
              name: 'Deluxe pedicure',
              description: '60-min pedicure with massage + paraffin',
              baseFlatRate: 75.00,
            ),
            EdenPriceBookItem(
              id: 'salon-acrylic-full',
              name: 'Acrylic full set',
              description: 'Full acrylic nail extensions',
              baseFlatRate: 65.00,
            ),
          ],
        ),
        EdenPriceBookCategory(
          id: 'cat-wax',
          name: 'Wax',
          items: [
            EdenPriceBookItem(
              id: 'salon-brow',
              name: 'Brow wax',
              description: 'Shaping + cleanup',
              baseFlatRate: 25.00,
            ),
            EdenPriceBookItem(
              id: 'salon-lip',
              name: 'Lip wax',
              description: 'Upper lip wax',
              baseFlatRate: 15.00,
            ),
            EdenPriceBookItem(
              id: 'salon-full-leg',
              name: 'Full leg wax',
              description: 'Ankle to thigh',
              baseFlatRate: 85.00,
            ),
            EdenPriceBookItem(
              id: 'salon-bikini',
              name: 'Bikini wax',
              description: 'Standard bikini line',
              baseFlatRate: 45.00,
            ),
            EdenPriceBookItem(
              id: 'salon-brazilian',
              name: 'Brazilian wax',
              description: 'Full brazilian',
              baseFlatRate: 75.00,
            ),
          ],
        ),
      ],
      tiers: const [
        EdenPriceBookTier(id: 'tier-walkin', name: 'Walk-in'),
        EdenPriceBookTier(
          id: 'tier-member',
          name: 'Member',
          defaultMarkupPct: -0.10,
          description: 'Loyalty member 10% off',
        ),
        EdenPriceBookTier(
          id: 'tier-vip',
          name: 'VIP',
          defaultMarkupPct: -0.20,
          description: 'VIP package holder 20% off',
        ),
      ],
      taxMatrix: const EdenPriceBookTaxMatrix(
        jurisdictions: ['CA'],
        itemTypes: ['service', 'product'],
        rates: {
          'CA': {'service': 0.0, 'product': 0.0825},
        },
      ),
    );
  }

  /// Fuel pricing: 2 categories × 4 items + 3 tiers + 3-jurisdiction tax matrix.
  static EdenPriceBookData fuel() {
    return EdenPriceBookData(
      categories: const [
        EdenPriceBookCategory(
          id: 'cat-residential',
          name: 'Residential',
          items: [
            EdenPriceBookItem(
              id: 'fuel-propane',
              name: 'Propane',
              description: 'Per gallon, residential delivery',
              baseFlatRate: 3.85,
              tierOverrides: {'tier-autofill': 3.65, 'tier-contract': 3.45},
            ),
            EdenPriceBookItem(
              id: 'fuel-heating-oil',
              name: 'Heating oil #2',
              description: 'Per gallon, residential delivery',
              baseFlatRate: 4.25,
              tierOverrides: {'tier-autofill': 4.05, 'tier-contract': 3.85},
            ),
          ],
        ),
        EdenPriceBookCategory(
          id: 'cat-commercial',
          name: 'Commercial',
          items: [
            EdenPriceBookItem(
              id: 'fuel-diesel',
              name: 'Off-road diesel',
              description: 'Per gallon, fleet/equipment delivery',
              baseFlatRate: 3.95,
              tierOverrides: {'tier-autofill': 3.75, 'tier-contract': 3.55},
            ),
            EdenPriceBookItem(
              id: 'fuel-gasoline',
              name: 'Unleaded gasoline',
              description: 'Per gallon, fleet delivery',
              baseFlatRate: 3.45,
              tierOverrides: {'tier-autofill': 3.30, 'tier-contract': 3.15},
            ),
          ],
        ),
      ],
      tiers: const [
        EdenPriceBookTier(
          id: 'tier-willcall',
          name: 'Will-call',
          description: 'Standard on-demand pricing',
        ),
        EdenPriceBookTier(
          id: 'tier-autofill',
          name: 'Auto-fill',
          defaultMarkupPct: -0.05,
          description: 'Scheduled delivery 5% off',
        ),
        EdenPriceBookTier(
          id: 'tier-contract',
          name: 'Contract-locked',
          defaultMarkupPct: -0.10,
          description: 'Annual contract 10% off',
        ),
      ],
      taxMatrix: const EdenPriceBookTaxMatrix(
        jurisdictions: ['CA', 'NY', 'TX'],
        itemTypes: ['residential', 'commercial', 'agricultural'],
        rates: {
          'CA': {
            'residential': 0.0,
            'commercial': 0.062,
            'agricultural': 0.0,
          },
          'NY': {
            'residential': 0.0,
            'commercial': 0.04,
            'agricultural': 0.0,
          },
          'TX': {
            'residential': 0.0,
            'commercial': 0.0,
            'agricultural': 0.0,
          },
        },
      ),
    );
  }

  static EdenPriceBookData empty() {
    return const EdenPriceBookData(
      categories: [],
      tiers: [],
      taxMatrix: EdenPriceBookTaxMatrix(
        jurisdictions: [],
        itemTypes: [],
        rates: {},
      ),
    );
  }

  /// Single item with full good-better-best populated.
  static EdenPriceBookItem hvacCompressor() {
    return const EdenPriceBookItem(
      id: 'item-compressor-repair',
      name: 'Compressor repair',
      description: 'Replace or rebuild outdoor compressor',
      baseFlatRate: 1850.00,
      skuCode: 'HVAC-COMP-01',
      laborHoursLabel: '3h labor included',
      gbb: EdenPriceBookGoodBetterBest(
        goodPrice: 1850.00,
        goodLabel: 'Repair existing compressor',
        betterPrice: 2950.00,
        betterLabel: 'Replace with new compressor (1-yr warranty)',
        bestPrice: 4250.00,
        bestLabel: 'Replace + 5-yr parts & labor warranty',
      ),
    );
  }
}
