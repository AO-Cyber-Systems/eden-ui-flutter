import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the accessible name of [EdenInput].
///
/// These exist because the FIRST attempt at naming the field regressed it. Using
/// `Semantics(label:, textField: true, child: TextField(...))` produced a SECOND
/// text-field node above the TextField's own, and Flutter web emitted two
/// `<input>` elements per field — measured live on the AODex sign-in page as 4
/// inputs for 2 fields, which doubles the tab stops and gives a screen reader two
/// "Email" boxes.
///
/// So counting text-field nodes is the whole point. A test that only asserted
/// "a node labelled Email exists" would have passed on the broken build.
void main() {
  /// Every semantics node in the tree carrying [SemanticsFlag.isTextField].
  List<SemanticsNode> textFields(SemanticsNode root) {
    final found = <SemanticsNode>[];
    void walk(SemanticsNode n) {
      if (n.getSemanticsData().flagsCollection.isTextField) found.add(n);
      n.visitChildren((child) {
        walk(child);
        return true;
      });
    }

    walk(root);
    return found;
  }

  Future<SemanticsHandle> pump(WidgetTester tester, Widget child) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: child)),
    );
    return handle;
  }

  /// The root of the rendered semantics tree.
  ///
  /// `pipelineOwner` is deprecated in favour of `rootPipelineOwner`, but the
  /// replacement exposes no `semanticsOwner` on the root — the tree hangs off a
  /// child owner — and there is no public API for walking it. Isolated here so
  /// the suppression is one line rather than one per test.
  SemanticsNode rootSemantics(WidgetTester tester) =>
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;

  testWidgets('a labelled input is ONE text field, named by its label',
      (tester) async {
    final handle = await pump(tester, const EdenInput(label: 'Email'));

    final fields = textFields(rootSemantics(tester));

    // The regression this file exists for: 2 here instead of 1.
    expect(fields, hasLength(1),
        reason: 'exactly one text-field node per EdenInput; more than one means '
            'a Semantics wrapper is declaring a duplicate field');
    expect(fields.single.label, contains('Email'),
        reason: 'the visible label must be the field\'s accessible name');

    handle.dispose();
  });

  testWidgets('an UNLABELLED input is still one field, and gains no empty name',
      (tester) async {
    final handle = await pump(tester, const EdenInput());

    final fields = textFields(rootSemantics(tester));

    expect(fields, hasLength(1));
    expect(fields.single.label, isEmpty,
        reason: 'wrapping unconditionally would give unlabelled inputs an empty '
            'name, which is worse than none');

    handle.dispose();
  });

  testWidgets('the label is announced ONCE, not once as text and once as name',
      (tester) async {
    final handle = await pump(tester, const EdenInput(label: 'Password'));

    final root = rootSemantics(tester);
    var mentions = 0;
    void count(SemanticsNode n) {
      if (n.getSemanticsData().label.contains('Password')) mentions++;
      n.visitChildren((c) {
        count(c);
        return true;
      });
    }

    count(root);

    expect(mentions, 1,
        reason: 'a separate label node PLUS a named field double-announces');

    handle.dispose();
  });

  testWidgets('the label still renders visibly — this is an a11y fix, not a restyle',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EdenInput(label: 'Email'))),
    );

    expect(find.text('Email'), findsOneWidget);
  });
}
