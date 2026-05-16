// Do NOT regenerate via LLM — hand-built fixtures for EdenPackoutPage.
// Edit by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenPackoutPageFixtures {
  EdenPackoutPageFixtures._();

  static EdenPackoutItem copper() => const EdenPackoutItem(
        id: 'pi-1',
        itemName: '3/4" copper pipe',
        sku: 'CU-075',
        quantityLoaded: 50,
        quantityUsed: 12,
        quantityReturned: 0,
        unit: 'ft',
      );

  static EdenPackoutItem refrigerant() => const EdenPackoutItem(
        id: 'pi-2',
        itemName: 'R410A refrigerant',
        sku: 'R410A-1lb',
        quantityLoaded: 4,
        quantityUsed: 2,
        quantityReturned: 2,
        unit: 'lb',
      );

  static EdenPackoutItem widgetNoSku() => const EdenPackoutItem(
        id: 'pi-3',
        itemName: 'Sheet metal screws',
        quantityLoaded: 100,
        quantityUsed: 30,
        quantityReturned: 70,
        unit: 'pcs',
      );

  static List<EdenPackoutItem> twoItems() => [copper(), refrigerant()];
  static List<EdenPackoutItem> threeItems() =>
      [copper(), refrigerant(), widgetNoSku()];

  /// Recorder that returns the edit applied to the item.
  static (
    List<(EdenPackoutItem, EdenPackoutEdit)>,
    Future<EdenPackoutItem> Function(EdenPackoutItem, EdenPackoutEdit)
  ) saveRecorder() {
    final captured = <(EdenPackoutItem, EdenPackoutEdit)>[];
    Future<EdenPackoutItem> fn(
        EdenPackoutItem item, EdenPackoutEdit edit) async {
      captured.add((item, edit));
      return item.copyWith(
        quantityUsed: edit.used,
        quantityReturned: edit.returned,
        notes: edit.notes,
      );
    }
    return (captured, fn);
  }

  /// Failing save.
  static Future<EdenPackoutItem> Function(EdenPackoutItem, EdenPackoutEdit)
      failingSave(String msg) =>
          (_, __) async => throw Exception(msg);

  /// Refresh recorder.
  static (int Function(), Future<void> Function()) refreshRecorder() {
    var calls = 0;
    Future<void> fn() async {
      calls++;
    }
    return (() => calls, fn);
  }
}
