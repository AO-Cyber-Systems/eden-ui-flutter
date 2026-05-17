// Do NOT regenerate via LLM — hand-built fixtures for EdenSalesAnalyticsScaffold.
//
// Hand-built per global TDD Playbook habit 4. Touch by hand when adding
// vertical-specific KPI shapes (medical visit count, fuel gallons, etc).

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenAnalyticsFixtures {
  EdenAnalyticsFixtures._();

  /// 5 KPIs + 7 trend points (Mon-Sun) + 8 top products + 4 top categories.
  static EdenSalesAnalyticsData weekOfMay() => const EdenSalesAnalyticsData(
        dateRangeLabel: 'May 11-17',
        kpis: <EdenAnalyticsKpi>[
          EdenAnalyticsKpi(
            label: 'Gross sales',
            valueText: r'$12,438',
            deltaPctSinceLastPeriod: 0.12,
            icon: Icons.attach_money,
          ),
          EdenAnalyticsKpi(
            label: 'Transactions',
            valueText: '142',
            deltaPctSinceLastPeriod: 0.04,
            icon: Icons.receipt_long,
          ),
          EdenAnalyticsKpi(
            label: 'Avg basket',
            valueText: r'$87.59',
            deltaPctSinceLastPeriod: -0.03,
            icon: Icons.shopping_basket,
          ),
          EdenAnalyticsKpi(
            label: 'Refund rate',
            valueText: '2.3%',
            deltaPctSinceLastPeriod: -0.01,
            icon: Icons.undo,
          ),
          EdenAnalyticsKpi(
            label: 'Top dept',
            valueText: 'Hot drinks',
            icon: Icons.local_cafe,
          ),
        ],
        trendSeries: <EdenAnalyticsTrendPoint>[
          EdenAnalyticsTrendPoint(label: 'Mon', value: 1450),
          EdenAnalyticsTrendPoint(label: 'Tue', value: 1670),
          EdenAnalyticsTrendPoint(label: 'Wed', value: 1840),
          EdenAnalyticsTrendPoint(label: 'Thu', value: 2020),
          EdenAnalyticsTrendPoint(label: 'Fri', value: 2350),
          EdenAnalyticsTrendPoint(label: 'Sat', value: 1900),
          EdenAnalyticsTrendPoint(label: 'Sun', value: 1208),
        ],
        topProducts: <EdenAnalyticsTopProductRow>[
          EdenAnalyticsTopProductRow(
            rank: 1,
            name: 'Espresso Single',
            unitsSold: 142,
            revenueCents: 49700,
            trend: 'up',
          ),
          EdenAnalyticsTopProductRow(
            rank: 2,
            name: 'Americano',
            unitsSold: 98,
            revenueCents: 39200,
            trend: 'flat',
          ),
          EdenAnalyticsTopProductRow(
            rank: 3,
            name: 'Cappuccino',
            unitsSold: 76,
            revenueCents: 36100,
            trend: 'up',
          ),
          EdenAnalyticsTopProductRow(
            rank: 4,
            name: 'Latte',
            unitsSold: 64,
            revenueCents: 33600,
            trend: 'down',
          ),
          EdenAnalyticsTopProductRow(
            rank: 5,
            name: 'Mocha',
            unitsSold: 54,
            revenueCents: 31050,
            trend: 'up',
          ),
          EdenAnalyticsTopProductRow(
            rank: 6,
            name: 'Iced Coffee',
            unitsSold: 51,
            revenueCents: 21675,
            trend: 'flat',
          ),
          EdenAnalyticsTopProductRow(
            rank: 7,
            name: 'Cold Brew',
            unitsSold: 42,
            revenueCents: 22050,
            trend: 'up',
          ),
          EdenAnalyticsTopProductRow(
            rank: 8,
            name: 'Sparkling Water',
            unitsSold: 38,
            revenueCents: 11400,
            trend: 'down',
          ),
        ],
        topCategories: <EdenAnalyticsCategorySlice>[
          EdenAnalyticsCategorySlice(label: 'Hot drinks', value: 6840),
          EdenAnalyticsCategorySlice(label: 'Cold drinks', value: 3210),
          EdenAnalyticsCategorySlice(label: 'Pastries', value: 1830),
          EdenAnalyticsCategorySlice(label: 'Merchandise', value: 558),
        ],
      );

  /// All-empty edge case.
  static EdenSalesAnalyticsData empty() => const EdenSalesAnalyticsData(
        kpis: <EdenAnalyticsKpi>[],
        trendSeries: <EdenAnalyticsTrendPoint>[],
        topProducts: <EdenAnalyticsTopProductRow>[],
        topCategories: <EdenAnalyticsCategorySlice>[],
      );

  /// Single-KPI minimal smoke.
  static EdenSalesAnalyticsData singleKpi() => const EdenSalesAnalyticsData(
        kpis: <EdenAnalyticsKpi>[
          EdenAnalyticsKpi(label: 'Sales', valueText: r'$100'),
        ],
        trendSeries: <EdenAnalyticsTrendPoint>[
          EdenAnalyticsTrendPoint(label: 'A', value: 100),
        ],
        topProducts: <EdenAnalyticsTopProductRow>[],
        topCategories: <EdenAnalyticsCategorySlice>[],
      );
}
