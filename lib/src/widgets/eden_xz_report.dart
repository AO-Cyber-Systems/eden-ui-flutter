import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import 'eden_currency_display.dart';

/// X = mid-shift read (no clear); Z = end-of-shift read (clears totals).
enum EdenShiftReportKind { xMid, zClose }

/// Sales aggregate by tender method.
@immutable
class EdenSalesByTender {
  const EdenSalesByTender({
    required this.tenderLabel,
    required this.amount,
    required this.transactionCount,
  });
  final String tenderLabel;
  final double amount;
  final int transactionCount;
}

/// Sales aggregate by category.
@immutable
class EdenSalesByCategory {
  const EdenSalesByCategory({
    required this.categoryLabel,
    required this.amount,
    required this.unitCount,
  });
  final String categoryLabel;
  final double amount;
  final int unitCount;
}

/// Sales aggregate by employee (cashier/stylist).
@immutable
class EdenSalesByEmployee {
  const EdenSalesByEmployee({
    required this.employeeId,
    required this.employeeName,
    required this.salesAmount,
    required this.tipAmount,
    required this.transactionCount,
  });
  final String employeeId;
  final String employeeName;
  final double salesAmount;
  final double tipAmount;
  final int transactionCount;
}

/// Refunds + voids aggregate.
@immutable
class EdenRefundsVoids {
  const EdenRefundsVoids({
    required this.refundsAmount,
    required this.refundsCount,
    required this.voidsAmount,
    required this.voidsCount,
  });
  final double refundsAmount;
  final int refundsCount;
  final double voidsAmount;
  final int voidsCount;
}

/// A consumer-computed shift report. Library renders only.
@immutable
class EdenShiftReport {
  const EdenShiftReport({
    required this.reportId,
    required this.kind,
    required this.shiftLabel,
    required this.shiftStart,
    required this.shiftEnd,
    required this.grossSales,
    required this.netSales,
    required this.taxCollected,
    required this.tipsCollected,
    required this.byTender,
    required this.byCategory,
    required this.byEmployee,
    required this.refundsVoids,
    this.cashVariance,
  });

  final String reportId;
  final EdenShiftReportKind kind;
  final String shiftLabel;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final double grossSales;
  final double netSales;
  final double taxCollected;
  final double tipsCollected;
  final List<EdenSalesByTender> byTender;
  final List<EdenSalesByCategory> byCategory;
  final List<EdenSalesByEmployee> byEmployee;
  final EdenRefundsVoids refundsVoids;
  final double? cashVariance;

  EdenShiftReport copyWith({
    String? reportId,
    EdenShiftReportKind? kind,
    String? shiftLabel,
    DateTime? shiftStart,
    DateTime? shiftEnd,
    double? grossSales,
    double? netSales,
    double? taxCollected,
    double? tipsCollected,
    List<EdenSalesByTender>? byTender,
    List<EdenSalesByCategory>? byCategory,
    List<EdenSalesByEmployee>? byEmployee,
    EdenRefundsVoids? refundsVoids,
    double? cashVariance,
    bool clearCashVariance = false,
  }) {
    return EdenShiftReport(
      reportId: reportId ?? this.reportId,
      kind: kind ?? this.kind,
      shiftLabel: shiftLabel ?? this.shiftLabel,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
      grossSales: grossSales ?? this.grossSales,
      netSales: netSales ?? this.netSales,
      taxCollected: taxCollected ?? this.taxCollected,
      tipsCollected: tipsCollected ?? this.tipsCollected,
      byTender: byTender ?? this.byTender,
      byCategory: byCategory ?? this.byCategory,
      byEmployee: byEmployee ?? this.byEmployee,
      refundsVoids: refundsVoids ?? this.refundsVoids,
      cashVariance: clearCashVariance
          ? null
          : (cashVariance ?? this.cashVariance),
    );
  }
}

/// Printable X/Z shift report (obj 015-07).
class EdenXZReport extends StatelessWidget {
  const EdenXZReport({
    super.key,
    required this.report,
    this.currencyCode = 'USD',
    this.printFriendly = false,
  });

  final EdenShiftReport report;
  final String currencyCode;
  final bool printFriendly;

  Color? _varianceColor(BuildContext context) {
    if (printFriendly) return null;
    final palette = Theme.of(context).extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();
    final v = report.cashVariance ?? 0;
    if (v.abs() <= 0.01) return palette.successFg;
    return palette.dangerFg;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  TextStyle? _bodyStyle(BuildContext context) {
    if (printFriendly) {
      return const TextStyle(fontFamily: 'monospace', fontSize: 12);
    }
    return Theme.of(context).textTheme.bodyMedium;
  }

  @override
  Widget build(BuildContext context) {
    final kindLabel = report.kind == EdenShiftReportKind.xMid
        ? 'X — Mid-shift read'
        : 'Z — End-of-shift';
    return Semantics(
      label: 'Shift report: ${report.shiftLabel}',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(report.shiftLabel,
              style: (printFriendly
                      ? const TextStyle(
                          fontFamily: 'monospace', fontWeight: FontWeight.w700)
                      : Theme.of(context).textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(kindLabel, style: _bodyStyle(context)),
          Text(
            '${_formatDateTime(report.shiftStart)}  →  ${_formatDateTime(report.shiftEnd)}',
            style: _bodyStyle(context),
          ),
          const Divider(),
          _buildSummary(context),
          const Divider(),
          _section(context, 'By tender'),
          _buildTenderTable(context),
          const Divider(),
          _section(context, 'By category'),
          _buildCategoryTable(context),
          const Divider(),
          _section(context, 'By employee'),
          _buildEmployeeTable(context),
          const Divider(),
          _section(context, 'Refunds & voids'),
          _buildRefundsVoids(context),
          if (report.kind == EdenShiftReportKind.zClose &&
              report.cashVariance != null) ...[
            const Divider(),
            Semantics(
              label:
                  'Cash variance: \$${report.cashVariance!.toStringAsFixed(2)}',
              container: true,
              excludeSemantics: true,
              child: Row(
                children: [
                  Text('Cash variance: ', style: _bodyStyle(context)),
                  Text(
                    '\$${report.cashVariance!.toStringAsFixed(2)}',
                    style: (_bodyStyle(context) ?? const TextStyle()).copyWith(
                      color: _varianceColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(title,
          style: (_bodyStyle(context) ?? const TextStyle())
              .copyWith(fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _kpiTile(context, 'Gross', report.grossSales),
        _kpiTile(context, 'Net', report.netSales),
        _kpiTile(context, 'Tax', report.taxCollected),
        _kpiTile(context, 'Tips', report.tipsCollected),
      ],
    );
  }

  Widget _kpiTile(BuildContext context, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: _bodyStyle(context)),
        EdenCurrencyDisplay(
          cents: (value * 100).round(),
          currencyCode: currencyCode,
          style: (_bodyStyle(context) ?? const TextStyle())
              .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTenderTable(BuildContext context) {
    if (report.byTender.isEmpty) return const Text('No tender data');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Tender')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('#')),
        ],
        rows: [
          for (final t in report.byTender)
            DataRow(cells: [
              DataCell(Text(t.tenderLabel)),
              DataCell(Text('\$${t.amount.toStringAsFixed(2)}')),
              DataCell(Text(t.transactionCount.toString())),
            ]),
        ],
      ),
    );
  }

  Widget _buildCategoryTable(BuildContext context) {
    if (report.byCategory.isEmpty) return const Text('No category data');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Units')),
        ],
        rows: [
          for (final c in report.byCategory)
            DataRow(cells: [
              DataCell(Text(c.categoryLabel)),
              DataCell(Text('\$${c.amount.toStringAsFixed(2)}')),
              DataCell(Text(c.unitCount.toString())),
            ]),
        ],
      ),
    );
  }

  Widget _buildEmployeeTable(BuildContext context) {
    if (report.byEmployee.isEmpty) return const Text('No employee data');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Employee')),
          DataColumn(label: Text('Sales')),
          DataColumn(label: Text('Tips')),
          DataColumn(label: Text('#')),
        ],
        rows: [
          for (final e in report.byEmployee)
            DataRow(cells: [
              DataCell(Text(e.employeeName)),
              DataCell(Text('\$${e.salesAmount.toStringAsFixed(2)}')),
              DataCell(Text('\$${e.tipAmount.toStringAsFixed(2)}')),
              DataCell(Text(e.transactionCount.toString())),
            ]),
        ],
      ),
    );
  }

  Widget _buildRefundsVoids(BuildContext context) {
    final rv = report.refundsVoids;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Refunds: \$${rv.refundsAmount.toStringAsFixed(2)} '
            '(${rv.refundsCount} txns)',
            style: _bodyStyle(context)),
        Text(
            'Voids: \$${rv.voidsAmount.toStringAsFixed(2)} '
            '(${rv.voidsCount} txns)',
            style: _bodyStyle(context)),
      ],
    );
  }
}
