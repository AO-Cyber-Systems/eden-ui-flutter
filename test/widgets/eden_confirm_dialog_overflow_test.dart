import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression suite for the EdenConfirmDialog action row.
//
// The action row used to be a fixed, non-wrapping `Row`. Long action labels
// therefore overflowed the dialog's 420px ConstrainedBox and pushed the primary
// (confirm) button off the dialog — and, on a narrow surface, off the view
// entirely, at which point it could not be tapped at all.
//
// This suite pins BOTH halves of the contract:
//   * constrained + long labels  -> both actions stay inside the dialog, both
//     are hit-testable, and nothing reports an overflow;
//   * unconstrained + short copy -> the geometry is byte-identical to the old
//     `Row`, because 62 files in eden-biz alone (plus mobile/ and pos/) render
//     this dialog with ordinary copy and must not move by a pixel.

// The real shipped copy from the call site that exposed the defect:
// eden-biz flutter/lib/features/knowledgebase/widgets/kb_visibility_select.dart
// (kbAnonymousConfirmLabel / kbAnonymousCancelLabel). The labels say what they
// DO on purpose — a confirm that reads "OK" is cleared by reflex — so the
// layout has to accommodate the copy rather than the copy shrinking to fit.
const String kLongConfirmLabel = 'Publish to the open internet';
const String kLongCancelLabel = 'Keep it private';

const String kShortConfirmLabel = 'Confirm';
const String kShortCancelLabel = 'Cancel';

// Deliberately short. The subject of this suite is the ACTION ROW; a long body
// would add vertical overflow noise to `takeException()` and confuse the signal.
const String kMessage = 'Anyone can read this without signing in.';

// iPhone-narrow. `mobile/` is one of the three consumers of this package, and
// at this width the dialog is 310pt wide (390 - Dialog's 40pt inset each side),
// so the 420px ConstrainedBox is not even the binding constraint.
const Size kNarrowSurface = Size(390, 844);

/// Pumps a host app and opens the dialog, recording what `show` resolves to.
///
/// Returns a one-element holder rather than a Future because the point of most
/// of these cases is that the future may never complete: an untappable confirm
/// button leaves the dialog open forever.
Future<_Resolved> _openDialog(
  WidgetTester tester, {
  required String confirmLabel,
  required String cancelLabel,
  bool isDestructive = false,
}) async {
  final resolved = _Resolved();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              resolved.value = await EdenConfirmDialog.show(
                context,
                title: 'Publish to the open internet?',
                message: kMessage,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                isDestructive: isDestructive,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return resolved;
}

class _Resolved {
  bool? value;
}

/// The dialog's own content box — the `ConstrainedBox(maxWidth: 420)` named in
/// the defect report. `find.byType(Dialog)` is NOT usable here: its render
/// object is the full-screen AnimatedPadding, so containment against it would
/// pass even for a button hanging off the visible dialog.
Finder get _dialogBox => find.descendant(
      of: find.byType(Dialog),
      matching: find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.maxWidth == 420,
      ),
    );

Finder _confirmButton(String label) =>
    find.widgetWithText(ElevatedButton, label);

Finder _cancelButton(String label) => find.widgetWithText(TextButton, label);

/// Resolved background of the confirm button, for the destructive-styling case.
Color? _confirmBackground(WidgetTester tester, String label) {
  final button = tester.widget<ElevatedButton>(_confirmButton(label));
  return button.style?.backgroundColor?.resolve(<WidgetState>{});
}

void _useNarrowSurface(WidgetTester tester) {
  tester.view.physicalSize = kNarrowSurface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('EdenConfirmDialog — constrained width, long action labels', () {
    testWidgets(
        'case 1: both action rects are contained by the dialog content box',
        (tester) async {
      _useNarrowSurface(tester);
      await _openDialog(
        tester,
        confirmLabel: kLongConfirmLabel,
        cancelLabel: kLongCancelLabel,
      );
      // Case 4 owns the overflow assertion; drop any report here so this case
      // fails on containment and nothing else.
      tester.takeException();

      final dialog = tester.getRect(_dialogBox);
      final cancel = tester.getRect(_cancelButton(kLongCancelLabel));
      final confirm = tester.getRect(_confirmButton(kLongConfirmLabel));

      // `findsOneWidget` is what missed this defect originally: a button pushed
      // clean off the dialog is still perfectly findable. Containment is the
      // property that actually holds.
      expect(dialog.contains(cancel.topLeft), isTrue,
          reason: 'cancel topLeft $cancel escapes dialog $dialog');
      expect(dialog.contains(cancel.bottomRight - const Offset(0.01, 0.01)),
          isTrue,
          reason: 'cancel bottomRight $cancel escapes dialog $dialog');
      expect(dialog.contains(confirm.topLeft), isTrue,
          reason: 'confirm topLeft $confirm escapes dialog $dialog');
      expect(dialog.contains(confirm.bottomRight - const Offset(0.01, 0.01)),
          isTrue,
          reason: 'confirm bottomRight $confirm escapes dialog $dialog');
    });

    testWidgets('case 2: the confirm button is tappable and resolves true',
        (tester) async {
      _useNarrowSurface(tester);
      final resolved = await _openDialog(
        tester,
        confirmLabel: kLongConfirmLabel,
        cancelLabel: kLongCancelLabel,
      );
      tester.takeException(); // case 4 owns the overflow assertion

      await tester.tap(_confirmButton(kLongConfirmLabel));
      await tester.pumpAndSettle();

      expect(resolved.value, isTrue);
    });

    testWidgets('case 3: the cancel button is tappable and resolves false',
        (tester) async {
      _useNarrowSurface(tester);
      final resolved = await _openDialog(
        tester,
        confirmLabel: kLongConfirmLabel,
        cancelLabel: kLongCancelLabel,
      );
      tester.takeException(); // case 4 owns the overflow assertion

      await tester.tap(_cancelButton(kLongCancelLabel));
      await tester.pumpAndSettle();

      expect(resolved.value, isFalse);
    });

    testWidgets('case 4: no overflow is reported at a narrow width',
        (tester) async {
      _useNarrowSurface(tester);
      await _openDialog(
        tester,
        confirmLabel: kLongConfirmLabel,
        cancelLabel: kLongCancelLabel,
      );

      // Flutter surfaces `A RenderFlex overflowed by N pixels` as a thrown
      // FlutterError in tests. This is the most direct statement of the defect.
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'case 4b: no overflow at the default width either — the 322px report',
        (tester) async {
      // No surface override: the default 800x600 test view, where the dialog
      // sits at its full 420px and the reported overflow was ~322px. This is
      // the literal reproduction of the figure in the defect report.
      await _openDialog(
        tester,
        confirmLabel: kLongConfirmLabel,
        cancelLabel: kLongCancelLabel,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('case 6: when the actions stack, cancel sits ABOVE confirm',
        (tester) async {
      _useNarrowSurface(tester);
      await _openDialog(
        tester,
        confirmLabel: kLongConfirmLabel,
        cancelLabel: kLongCancelLabel,
      );
      tester.takeException(); // case 4 owns the overflow assertion

      final cancel = tester.getRect(_cancelButton(kLongCancelLabel));
      final confirm = tester.getRect(_confirmButton(kLongConfirmLabel));

      // The safe action stays reachable without thought; the destructive one is
      // the one you have to travel to. Child order must not be reversed.
      expect(cancel.center.dy, lessThan(confirm.center.dy),
          reason: 'cancel $cancel should sit above confirm $confirm');
    });

    testWidgets('case 7a: destructive styling survives the stacked arrangement',
        (tester) async {
      _useNarrowSurface(tester);
      await _openDialog(
        tester,
        confirmLabel: kLongConfirmLabel,
        cancelLabel: kLongCancelLabel,
        isDestructive: true,
      );
      tester.takeException(); // case 4 owns the overflow assertion

      expect(_confirmBackground(tester, kLongConfirmLabel), EdenColors.error);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('EdenConfirmDialog — ordinary width, short copy (parity)', () {
    testWidgets('case 5: the short-copy geometry is unchanged', (tester) async {
      // Default 800x600 test view; dialog pinned at its 420px maximum.
      await _openDialog(
        tester,
        confirmLabel: kShortConfirmLabel,
        cancelLabel: kShortCancelLabel,
      );
      expect(tester.takeException(), isNull);

      final dialog = tester.getRect(_dialogBox);
      final cancel = tester.getRect(_cancelButton(kShortCancelLabel));
      final confirm = tester.getRect(_confirmButton(kShortConfirmLabel));

      // Exact rects, measured against the ORIGINAL non-wrapping Row before the
      // fix was written (full double precision, not rounded). These literals
      // are the parity evidence for the other 62+ call sites: if the fix moved
      // anything for ordinary copy, they fail. Do not "update" them to match
      // new behaviour — that would erase the very evidence they exist to carry.
      expect(dialog, const Rect.fromLTRB(190.0, 184.0, 610.0, 416.0));
      expect(
        cancel,
        const Rect.fromLTRB(
            314.7000045776367, 344.0, 439.3000030517578, 392.0),
      );
      expect(
        confirm,
        const Rect.fromLTRB(447.3000030517578, 344.0, 586.0, 392.0),
      );

      // ...and the same facts stated structurally, so a future reader can see
      // what the literals mean: still one row, still end-aligned.
      expect(cancel.center.dy, confirm.center.dy);
      expect(confirm.left, greaterThan(cancel.right));
      expect(confirm.left - cancel.right, 8.0); // EdenSpacing.space2
      expect(confirm.right, dialog.right - 24.0); // EdenSpacing.space6 padding
    });

    testWidgets('case 7b: destructive styling survives the row arrangement',
        (tester) async {
      await _openDialog(
        tester,
        confirmLabel: kShortConfirmLabel,
        cancelLabel: kShortCancelLabel,
        isDestructive: true,
      );
      expect(tester.takeException(), isNull);

      expect(_confirmBackground(tester, kShortConfirmLabel), EdenColors.error);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
