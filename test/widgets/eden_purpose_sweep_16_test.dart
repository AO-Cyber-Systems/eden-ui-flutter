// test/widgets/eden_purpose_sweep_16_test.dart
//
// TRD 40-16 — migration sweep 8 of 8: viewers, chat, admin, support & the dev
// catalog. Proves that every field in the 16 files this TRD owns resolves its
// input semantics through EdenFieldPurpose rather than by hand.
//
// WHY THESE ASSERTIONS AND NOT OTHERS
//
// 1. Hints alone fix NOTHING. `material/text_field.dart:355` resolves
//    `keyboardType` in the CONSTRUCTOR'S INITIALIZER LIST
//    (`keyboardType ?? (maxLines == 1 ? text : multiline)`), so
//    `editable_text.dart`'s `_inferKeyboardType` is unreachable for every
//    TextField-based widget (40-RESEARCH Appendix B1). A field carrying
//    `autofillHints` without a matching `keyboardType` is still broken, so
//    every purposed case below asserts BOTH halves.
//
// 2. `TextField.autofillHints` defaults to `const <String>[]`, NOT null
//    (Appendix B6). Asserting `== null` fails on correctly-unpurposed raw
//    fields; asserting `!= null` passes on fields carrying no hints at all.
//    So "no autofill identity" is asserted as EMPTINESS via [expectNoIdentity],
//    which accepts both legitimate shapes:
//      - an `EdenFieldPurpose.none` SPREAD resolves hints to `null`
//        (EdenInput forwards the caller's null verbatim on the none branch);
//      - a marker-comment-only `none` leaves TextField's empty-list default.
//
// 3. Clipboard gating is `!obscureText && !selection.isCollapsed`
//    (`editable_text.dart:2641-2646`). Any copy/cut assertion therefore sets a
//    NON-COLLAPSED selection first, or it passes vacuously for every field
//    (40-RESEARCH Appendix A, "methodological trap"). `pasteEnabled` is never
//    asserted — it is false in the test environment regardless of config.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/dev_app/explorer/sidebar.dart';
import 'package:eden_ui_flutter/dev_app/screens/inputs_screen.dart';
import 'package:eden_ui_flutter/dev_app/screens/overlays_screen.dart';
import 'package:eden_ui_flutter/dev_app/screens/settings_screen.dart';
import 'package:eden_ui_flutter/dev_app/screens/trades_screen.dart';
import 'package:eden_ui_flutter/dev_app/stories/inputs_story.dart';
import 'package:eden_ui_flutter/dev_app/registry/knob_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'eden_ai/_fixtures/eden_agent_chat_fixtures.dart';

// ── Shared helpers ───────────────────────────────────────────────────────────

/// Asserts a field carries NO autofill identity.
///
/// Appendix B6: `TextField.autofillHints` defaults to `const <String>[]`, not
/// null, so emptiness — never nullness — is the correct predicate. Both
/// legitimate `none` shapes (a resolved null from a purpose spread, and the
/// untouched empty-list default from a marker-comment-only field) pass here.
void expectNoIdentity(TextField field, String what) {
  final Iterable<String>? hints = field.autofillHints;
  expect(
    hints == null || hints.isEmpty,
    isTrue,
    reason: '$what must carry no autofill identity. Appendix B6: '
        'autofillHints defaults to const <String>[], so assert EMPTINESS, '
        'never nullness. Got: $hints',
  );
}

/// Asserts a field resolved [purpose] — BOTH halves, per Appendix B1.
void expectResolves(
  TextField field,
  EdenFieldPurpose purpose,
  String what,
) {
  final EdenFieldSemantics s = purpose.semantics;
  expect(
    field.keyboardType,
    s.keyboardType,
    reason: '$what must resolve keyboardType from $purpose. '
        'text_field.dart:355 resolves keyboardType in the initializer list, '
        'so a hint alone would leave this at TextInputType.text and iOS '
        'autofill would stay broken (Appendix B1).',
  );
  expect(
    field.textInputAction,
    s.textInputAction,
    reason: '$what must resolve textInputAction from $purpose.',
  );
  expect(
    field.textCapitalization,
    s.textCapitalization,
    reason: '$what must resolve textCapitalization from $purpose.',
  );
  expect(
    field.obscureText,
    s.obscureText,
    reason: '$what must resolve obscureText from $purpose.',
  );
  if (s.autofillHints == null) {
    expectNoIdentity(field, what);
  } else {
    expect(
      field.autofillHints?.first,
      s.autofillHints!.first,
      reason: '$what must emit $purpose\'s hint FIRST. iOS and web read only '
          'hints.first (autofill.dart:688-694), so hint ORDER is '
          'load-bearing. Got: ${field.autofillHints}',
    );
  }
}

/// The single [TextField] whose decoration hint is exactly [hintText].
///
/// Used instead of `.at(index)` so the finders survive layout changes (TRD
/// 40-16 Task 3 gotcha).
Finder byHint(String hintText) => find.byWidgetPredicate(
      (Widget w) => w is TextField && w.decoration?.hintText == hintText,
      description: 'TextField(hintText: "$hintText")',
    );

/// Widens the test surface so a lazily-built `ListView` mounts every child.
///
/// The dev-catalog screens are taller than the default 800x600 surface, and a
/// `ListView` only instantiates the children near the viewport — an unmounted
/// field is invisible to a finder and would make these assertions vacuous.
///
/// NOTE: `EdenInput` renders its label as a SIBLING `Text`, never as
/// `InputDecoration.labelText` (eden_input.dart, the MergeSemantics block), so
/// every EdenInput site is located by its hint, not its label.
void useTallSurface(
  WidgetTester tester, {
  double width = 1200,
  double height = 6000,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget wrap(Widget child, {Size size = const Size(1200, 900)}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: child),
      ),
    );

void main() {
  // ── eden_command_palette.dart ──────────────────────────────────────────────
  group('40-16 / eden_command_palette.dart', () {
    testWidgets('the query box resolves searchQuery — both halves',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenCommandPalette(
          items: <EdenCommandItem>[
            EdenCommandItem(id: 'a', label: 'Alpha'),
            EdenCommandItem(id: 'b', label: 'Beta'),
          ],
          placeholder: 'Type a command…',
        ),
      ));
      await tester.pump();

      final TextField field = tester.widget<TextField>(byHint('Type a command…'));
      expectResolves(field, EdenFieldPurpose.searchQuery, 'The command palette query box');
      expect(field.keyboardType, TextInputType.text);
      expect(field.textInputAction, TextInputAction.search);
      expectNoIdentity(field, 'The command palette query box');
    });

    testWidgets('Enter still selects — the search action did not steal it',
        (tester) async {
      String? picked;
      await tester.pumpWidget(wrap(
        EdenCommandPalette(
          items: <EdenCommandItem>[
            EdenCommandItem(id: 'a', label: 'Alpha', onSelect: () => picked = 'a'),
          ],
          placeholder: 'Type a command…',
        ),
      ));
      await tester.pump();

      // Enter-to-select is handled by the ancestor Focus(onKeyEvent:), not by
      // onSubmitted, so TextInputAction.search must not affect it.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(picked, 'a',
          reason: 'Assigning searchQuery (TextInputAction.search) must not '
              'break the palette\'s Enter-to-select, which runs through '
              'Focus(onKeyEvent: _handleKeyEvent).');
    });
  });

  // ── eden_audit_log_viewer.dart ─────────────────────────────────────────────
  group('40-16 / eden_audit_log_viewer.dart', () {
    testWidgets('the actor filter resolves searchQuery — both halves',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenAuditLogViewer(
          entries: <EdenAuditLogEntry>[
            EdenAuditLogEntry(
              id: 'e1',
              timestamp: DateTime(2026, 1, 1),
              actor: 'alice',
              action: 'login',
              target: 'console',
            ),
          ],
        ),
      ));
      await tester.pump();

      final TextField field = tester.widget<TextField>(byHint('Filter by actor…'));
      expectResolves(field, EdenFieldPurpose.searchQuery, 'The audit actor filter');
      expect(field.textInputAction, TextInputAction.search);
      expectNoIdentity(field, 'The audit actor filter');
    });
  });

  // ── eden_log_viewer.dart ───────────────────────────────────────────────────
  group('40-16 / eden_log_viewer.dart', () {
    testWidgets('the log search resolves searchQuery — both halves',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenLogViewer(
          entries: <EdenLogEntry>[
            EdenLogEntry(
              message: 'boot complete',
              timestamp: DateTime(2026, 1, 1),
              level: EdenLogLevel.info,
            ),
          ],
        ),
      ));
      await tester.pump();

      final TextField field = tester.widget<TextField>(byHint('Search logs...'));
      expectResolves(field, EdenFieldPurpose.searchQuery, 'The log viewer search');
      expect(field.textInputAction, TextInputAction.search);
      expectNoIdentity(field, 'The log viewer search');
    });
  });

  // ── eden_job_log.dart ──────────────────────────────────────────────────────
  group('40-16 / eden_job_log.dart', () {
    testWidgets('the job-log search resolves searchQuery — both halves',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenJobLog(
          steps: <EdenJobLogStep>[
            EdenJobLogStep(
              name: 'build',
              status: EdenJobLogStepStatus.passed,
              lines: <String>['compiling'],
            ),
          ],
        ),
      ));
      await tester.pump();

      final TextField field = tester.widget<TextField>(byHint('Search logs...'));
      expectResolves(field, EdenFieldPurpose.searchQuery, 'The job log search');
      expect(field.textInputAction, TextInputAction.search);
      expectNoIdentity(field, 'The job log search');
    });
  });

  // ── eden_approval_queue.dart ───────────────────────────────────────────────
  group('40-16 / eden_approval_queue.dart', () {
    Future<void> openRejectDialog(WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        EdenApprovalQueue(
          items: <EdenApprovalItem>[
            EdenApprovalItem(
              id: 'i1',
              title: 'Expense report',
              submittedBy: 'alice',
              submittedAt: DateTime(2026, 1, 1),
            ),
          ],
          onReject: (List<String> ids, String comment) {},
          showStats: false,
          showFilters: false,
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Reject').first);
      await tester.pumpAndSettle();
    }

    testWidgets('the comment box resolves multilineText — both halves',
        (tester) async {
      await openRejectDialog(tester);

      final TextField field = tester.widget<TextField>(byHint('Add a comment...'));
      expectResolves(field, EdenFieldPurpose.multilineText, 'The approval comment box');
      expect(field.keyboardType, TextInputType.multiline);
      expect(field.textCapitalization, TextCapitalization.sentences);
      expectNoIdentity(field, 'The approval comment box');
    });

    testWidgets(
        'textInputAction became newline, which is legal because maxLines > 1',
        (tester) async {
      await openRejectDialog(tester);

      final TextField field = tester.widget<TextField>(byHint('Add a comment...'));
      expect(field.textInputAction, TextInputAction.newline,
          reason: 'multilineText resolves TextInputAction.newline.');
      expect(field.maxLines, greaterThan(1),
          reason: 'newline is only a sane action on a genuinely multi-line '
              'field. The dialog submits via its ElevatedButton, never via '
              'onSubmitted, so Enter-makes-a-newline is correct here.');
      expect(field.onSubmitted, isNull,
          reason: 'If this box ever gained an onSubmitted, the newline action '
              'resolved by multilineText would stop Enter reaching it.');
    });

    testWidgets('the comment box stays copyable — obscureText is false',
        (tester) async {
      await openRejectDialog(tester);

      await tester.enterText(byHint('Add a comment...'), 'looks wrong');
      await tester.pump();

      final EditableTextState state =
          tester.state<EditableTextState>(find.byType(EditableText).last);
      // MUST set a non-collapsed selection first: copyEnabled is
      // `!obscureText && !selection.isCollapsed`, so without this the
      // assertion is vacuous (40-RESEARCH Appendix A).
      state.widget.controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 5);
      await tester.pump();

      expect(state.textEditingValue.selection.isCollapsed, isFalse,
          reason: 'Guard: without a real selection the copy assertion below '
              'would pass for every field, obscured or not.');
      expect(state.copyEnabled, isTrue,
          reason: 'multilineText resolves obscureText: false, so the comment '
              'stays copyable (editable_text.dart:2641-2646).');
    });
  });

  // ── eden_mobile_ai_chat_sheet.dart + eden_ai/eden_agent_chat.dart ──────────
  group('40-16 / chat composers are explicitly none', () {
    testWidgets('EdenAgentChat composer carries no autofill identity',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenAgentChat(
          activePersona: EdenAiPersona.operations,
          onPersonaChanged: (_) {},
          sendMessage: EdenAgentChatFixtures.noopStreamSender,
          createConversation: EdenAgentChatFixtures.noopCreator,
          pageContext: 'Test page',
        ),
      ));
      await tester.pump();

      final TextField field = tester.widget<TextField>(byHint('Ask a question...'));
      expectNoIdentity(field, 'The agent chat composer');
      expect(field.maxLines, 1,
          reason: 'This is the discriminator for none-vs-multilineText: with '
              'maxLines == 1 the newline action multilineText resolves would '
              'stop Enter reaching onSubmitted and break send-on-Enter.');
      expect(field.onSubmitted, isNotNull,
          reason: 'Send-on-Enter is wired through onSubmitted — the exact '
              'behaviour multilineText would have broken.');
    });

    testWidgets('EdenMobileAiChatSheet composer carries no autofill identity',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenMobileAiChatSheet(
          activePersona: EdenAiPersona.operations,
          onPersonaChanged: (_) {},
          sendMessage: EdenAgentChatFixtures.noopStreamSender,
          createConversation: EdenAgentChatFixtures.noopCreator,
          pageContext: 'Test page',
        ),
        size: const Size(400, 900),
      ));
      await tester.pump();

      final TextField field = tester.widget<TextField>(byHint('Ask a question...'));
      expectNoIdentity(field, 'The mobile AI chat composer');
      expect(field.maxLines, 1);
      expect(field.onSubmitted, isNotNull);
    });
  });

  // ── eden_layout/eden_desktop_layout.dart ───────────────────────────────────
  group('40-16 / eden_desktop_layout.dart', () {
    testWidgets('the top-bar search resolves searchQuery — both halves',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenDesktopLayout(
          navItems: const <EdenNavItem>[
            EdenNavItem(id: 'home', label: 'Home', icon: Icons.home),
          ],
          selectedId: 'home',
          onNavChanged: (_) {},
          topBar: const EdenTopBarConfig(
            title: 'Dashboard',
            showSearch: true,
            searchHint: 'Search everything…',
          ),
          body: const Text('body'),
        ),
      ));
      await tester.pump();

      final TextField field = tester.widget<TextField>(byHint('Search everything…'));
      expectResolves(field, EdenFieldPurpose.searchQuery, 'The top-bar search');
      expect(field.textInputAction, TextInputAction.search);
      expectNoIdentity(field, 'The top-bar search');
    });

    testWidgets(
        'TRD 40-06 guard: the body is still wrapped and nav labels stay OUTSIDE it',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenDesktopLayout(
          navItems: const <EdenNavItem>[
            EdenNavItem(id: 'home', label: 'NavLabelHome', icon: Icons.home),
          ],
          selectedId: 'home',
          onNavChanged: (_) {},
          topBar: const EdenTopBarConfig(
            title: 'Dashboard',
            showSearch: true,
            searchHint: 'Search everything…',
          ),
          body: const Text('BodyText'),
        ),
      ));
      await tester.pump();

      expect(find.byType(EdenSelectableRegion), findsOneWidget,
          reason: 'TRD 40-06 wrapped the BODY slot. This sweep added a field '
              'purpose only and must not move, remove or duplicate it.');
      expect(
        find.descendant(
          of: find.byType(EdenSelectableRegion),
          matching: find.text('BodyText'),
        ),
        findsOneWidget,
        reason: 'The body must be INSIDE the region.',
      );
      expect(
        find.descendant(
          of: find.byType(EdenSelectableRegion),
          matching: find.text('NavLabelHome'),
        ),
        findsNothing,
        reason: 'Nav labels must stay OUTSIDE the region — this is the '
            'assertion that distinguishes "wrap body" from "wrap Scaffold".',
      );
    });
  });

  // ── support_panel/eden_ticket_tab.dart ─────────────────────────────────────
  group('40-16 / support_panel/eden_ticket_tab.dart', () {
    Future<void> openCreateForm(WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        EdenTicketTab(
          config: EdenSupportPanelConfig(
            listTickets: () async => const <SupportTicket>[],
            createTicket: ({
              required String subject,
              required String description,
              required SupportTicketPriority priority,
            }) async =>
                const SupportTicket(
              id: 't1',
              subject: 'x',
              status: SupportTicketStatus.open,
              priority: SupportTicketPriority.normal,
              tags: <String>[],
            ),
          ),
        ),
        size: const Size(420, 900),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Ticket').last);
      await tester.pumpAndSettle();
    }

    testWidgets('Subject is explicitly none — no identity claimed',
        (tester) async {
      await openCreateForm(tester);

      final TextField field =
          tester.widget<TextField>(byHint('Describe your issue briefly'));
      expectNoIdentity(field, 'The ticket subject');
      expect(field.obscureText, isFalse);
    });

    testWidgets('Description resolves multilineText — both halves',
        (tester) async {
      await openCreateForm(tester);

      final TextField field =
          tester.widget<TextField>(byHint('Provide more detail (optional)'));
      expectResolves(
          field, EdenFieldPurpose.multilineText, 'The ticket description');
      expect(field.keyboardType, TextInputType.multiline,
          reason: 'Previously hand-passed as keyboardType: '
              'TextInputType.multiline; the purpose now resolves it so hint '
              'and keyboard cannot drift apart.');
      expect(field.textInputAction, TextInputAction.newline);
      expect(field.maxLines, 4,
          reason: 'newline is only correct on a genuinely multi-line body.');
    });
  });

  // ── support_panel/eden_ticket_detail_view.dart ─────────────────────────────
  group('40-16 / support_panel/eden_ticket_detail_view.dart', () {
    testWidgets('the reply composer is explicitly none — Enter still submits',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenTicketDetailView(
          ticket: const SupportTicket(
            id: 't1',
            subject: 'Printer offline',
            status: SupportTicketStatus.open,
            priority: SupportTicketPriority.normal,
            tags: <String>[],
          ),
          config: EdenSupportPanelConfig(
            listComments: (String id) async => const <SupportComment>[],
            addComment: ({
              required String ticketId,
              required String body,
            }) async =>
                SupportComment(id: 'c1', ticketId: ticketId, body: body),
          ),
          onBack: () {},
        ),
        size: const Size(420, 900),
      ));
      await tester.pumpAndSettle();

      final TextField field = tester.widget<TextField>(byHint('Add a comment...'));
      expectNoIdentity(field, 'The ticket reply composer');
      expect(field.maxLines, 1);
      expect(field.onSubmitted, isNotNull,
          reason: 'Send-on-Enter runs through onSubmitted; multilineText '
              'would resolve TextInputAction.newline and break it.');
    });
  });

  // ── dev_app/explorer/sidebar.dart ──────────────────────────────────────────
  group('40-16 / dev_app/explorer/sidebar.dart', () {
    testWidgets('the story search resolves searchQuery — both halves',
        (tester) async {
      await tester.pumpWidget(wrap(
        ExplorerSidebar(selectedStoryId: null, onSelect: (_) {}),
      ));
      await tester.pump();

      final TextField field = tester.widget<TextField>(byHint('Search stories'));
      expectResolves(field, EdenFieldPurpose.searchQuery, 'The story search');
      expect(field.textInputAction, TextInputAction.search);
      expectNoIdentity(field, 'The story search');
    });
  });

  // ── dev_app/screens/inputs_screen.dart ─────────────────────────────────────
  group('40-16 / dev_app/screens/inputs_screen.dart', () {
    testWidgets('the catalog shows a realistic purposed mix', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: InputsScreen()));
      await tester.pumpAndSettle();

      final TextField email = tester.widget<TextField>(byHint('you@example.com'));
      expectResolves(email, EdenFieldPurpose.email, 'The catalog Email field');
      expect(email.keyboardType, TextInputType.emailAddress,
          reason: 'AutofillHints.email works ONLY with '
              'TextInputType.emailAddress (editable_text.dart:1855-1858).');
      expect(email.autofillHints?.first, AutofillHints.email);

      final TextField username =
          tester.widget<TextField>(byHint('Enter your username'));
      expectResolves(
          username, EdenFieldPurpose.username, 'The catalog Username field');
      expect(username.autofillHints?.first, AutofillHints.username);
    });

    testWidgets(
        'the Password demo is obscured AND carries a password-family hint',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: InputsScreen()));
      await tester.pumpAndSettle();

      final TextField pw = tester.widget<TextField>(byHint('Enter password'));
      expect(pw.obscureText, isTrue,
          reason: 'currentPassword resolves obscureText: true.');
      final Iterable<String>? hints = pw.autofillHints;
      expect(hints, isNotNull);
      expect(hints!.isNotEmpty, isTrue);
      expect(
        hints.first.toLowerCase().contains('password'),
        isTrue,
        reason: 'text_editing.dart:514-531 derives DOM type="password" from '
            'the HINT STRING, never from obscureText. An obscured field with '
            'no password-family hint renders as type="text" — the secret '
            'plaintext in the DOM and invisible to password managers. '
            'Lowercased first because AutofillHints.password is the raw '
            'Flutter constant (Appendix B2). Got: $hints',
      );
      expect(hints.first, AutofillHints.password);
    });

    testWidgets('the obscured Password demo cannot be copied', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: InputsScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(byHint('Enter password'), 'hunter2xyz');
      await tester.pump();

      final EditableTextState state = tester.state<EditableTextState>(
        find.descendant(
          of: byHint('Enter password'),
          matching: find.byType(EditableText),
        ),
      );
      state.widget.controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 10);
      await tester.pump();

      expect(state.textEditingValue.selection.isCollapsed, isFalse,
          reason: 'Guard: copyEnabled is '
              '!obscureText && !selection.isCollapsed, so without a real '
              'selection this assertion would pass vacuously.');
      expect(state.copyEnabled, isFalse,
          reason: 'obscureText HARD-DISABLES copy '
              '(editable_text.dart:2641-2646). Secrets need an explicit copy '
              'button, which is why EdenSecretField has one.');
    });

    testWidgets('the Message textarea resolves multilineText', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: InputsScreen()));
      await tester.pumpAndSettle();

      final TextField msg =
          tester.widget<TextField>(byHint('Type your message...'));
      expectResolves(
          msg, EdenFieldPurpose.multilineText, 'The catalog Message textarea');
      expect(msg.keyboardType, TextInputType.multiline);
      expect(msg.maxLines, 4);
    });

    testWidgets('the purposeless demo fields are explicitly none, not omitted',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: InputsScreen()));
      await tester.pumpAndSettle();

      for (final String hint in <String>[
        'Type something...',
        'This input is disabled',
        'sm input',
        'md input',
        'lg input',
      ]) {
        final TextField f = tester.widget<TextField>(byHint(hint));
        expectNoIdentity(f, 'The catalog demo field "$hint"');
        expect(f.obscureText, isFalse, reason: '"$hint" must not be obscured.');
      }
    });
  });

  // ── dev_app/screens/settings_screen.dart ───────────────────────────────────
  group('40-16 / dev_app/screens/settings_screen.dart', () {
    testWidgets('the Profile section carries real identity purposes',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      final TextField name =
          tester.widget<TextField>(byHint('Enter your name'));
      expectResolves(name, EdenFieldPurpose.personName, 'Display Name');
      expect(name.keyboardType, TextInputType.name,
          reason: 'AutofillHints.name requires TextInputType.name '
              '(editable_text.dart:1855-1858).');
      expect(name.autofillHints?.first, AutofillHints.name);

      final TextField email =
          tester.widget<TextField>(byHint('you@example.com'));
      expectResolves(email, EdenFieldPurpose.email, 'Email');
      expect(email.keyboardType, TextInputType.emailAddress);
    });
  });

  // ── dev_app/screens/overlays_screen.dart ───────────────────────────────────
  group('40-16 / dev_app/screens/overlays_screen.dart', () {
    testWidgets('the Edit Profile modal fields carry real purposes',
        (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: OverlaysScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Large Modal'));
      await tester.pumpAndSettle();

      final TextField name =
          tester.widget<TextField>(byHint('Enter your name'));
      expectResolves(name, EdenFieldPurpose.personName, 'Full Name');
      expect(name.autofillHints?.first, AutofillHints.name);

      final TextField email =
          tester.widget<TextField>(byHint('you@example.com'));
      expectResolves(email, EdenFieldPurpose.email, 'Email');

      final TextField bio =
          tester.widget<TextField>(byHint('Tell us about yourself'));
      expectResolves(bio, EdenFieldPurpose.multilineText, 'Bio');
      expect(bio.keyboardType, TextInputType.multiline);
    });

    testWidgets('the drawer filter resolves searchQuery', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: OverlaysScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      final TextField search =
          tester.widget<TextField>(byHint('Filter by name...'));
      expectResolves(search, EdenFieldPurpose.searchQuery, 'The drawer filter');
      expect(search.textInputAction, TextInputAction.search);
      expectNoIdentity(search, 'The drawer filter');
    });
  });

  // ── dev_app/screens/trades_screen.dart ─────────────────────────────────────
  group('40-16 / dev_app/screens/trades_screen.dart', () {
    /// Mounts TradesScreen and scrolls the wizard's first step into view.
    ///
    /// The screen carries a PRE-EXISTING RenderFlex overflow at every test
    /// viewport probed: the wizard's `SizedBox(height: 420)` is shorter than
    /// its own step content. Measured identical BEFORE and AFTER this sweep
    /// (3 overflows either way, with the file restored byte-identically), so
    /// it is not a regression introduced here. It is drained explicitly below,
    /// and anything that is NOT an overflow still fails the test.
    Future<void> mountTrades(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Intercept errors individually. The binding otherwise collapses them
      // into an opaque "Multiple exceptions (N)" summary that cannot be
      // inspected, which would force this helper to swallow ANY error
      // unexamined — exactly the kind of blanket suppression that hides a
      // real regression.
      final List<FlutterErrorDetails> caught = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? priorOnError =
          FlutterError.onError;
      FlutterError.onError = caught.add;

      final Finder target = byHint('e.g. Robert Johnson');
      try {
        await tester.pumpWidget(const MaterialApp(home: TradesScreen()));
        await tester.pump(const Duration(milliseconds: 300));
        for (int i = 0; i < 60 && target.evaluate().isEmpty; i++) {
          await tester.drag(
              find.byType(Scrollable).first, const Offset(0, -500));
          await tester.pump(const Duration(milliseconds: 60));
        }
      } finally {
        FlutterError.onError = priorOnError;
      }

      expect(target, findsOneWidget,
          reason: 'Guard: the wizard step must actually be mounted, or every '
              'assertion below would be measuring an empty tree.');

      for (final FlutterErrorDetails details in caught) {
        expect(
          details.exception.toString(),
          contains('overflowed'),
          reason: 'Only the demo screen\'s pre-existing RenderFlex overflow '
              'is tolerated here (measured identical before and after this '
              'sweep). Any other error is a real failure. Got: '
              '${details.exception}',
        );
      }
    }

    testWidgets('the wizard Customer Info step carries real purposes',
        (tester) async {
      await mountTrades(tester);

      final TextField name =
          tester.widget<TextField>(byHint('e.g. Robert Johnson'));
      expectResolves(name, EdenFieldPurpose.personName, 'Customer Name');
      expect(name.keyboardType, TextInputType.name,
          reason: 'AutofillHints.name requires TextInputType.name '
              '(editable_text.dart:1855-1858).');
      expect(name.autofillHints?.first, AutofillHints.name);

      final TextField phone =
          tester.widget<TextField>(byHint('(555) 123-4567'));
      expectResolves(phone, EdenFieldPurpose.telephoneNumber, 'Phone');
      expect(phone.keyboardType, TextInputType.phone,
          reason: 'A phone hint without TextInputType.phone is the exact '
              'mismatch EdenFieldPurpose exists to prevent.');
      expect(phone.autofillHints?.first, AutofillHints.telephoneNumber);

      final TextField address =
          tester.widget<TextField>(byHint('742 Evergreen Terrace'));
      expectResolves(address, EdenFieldPurpose.streetAddressLine1, 'Address');
      expect(address.keyboardType, TextInputType.streetAddress);
      expect(address.autofillHints?.first, AutofillHints.streetAddressLine1);
    });

    testWidgets('no mounted wizard field is obscured or mis-keyboarded',
        (tester) async {
      await mountTrades(tester);

      // Scoped to the three fields the linear wizard actually mounts. Steps 2
      // and 3 (Service Type, Issue Description, Priority, Preferred Date, Time
      // Window, Assigned Technician) never build until the wizard advances, so
      // their `none` / multilineText assignments are covered by the source
      // self-check and TRD 40-17's guard rather than by a widget test — the
      // gap is recorded in 40-16-SUMMARY.md.
      for (final String hint in <String>[
        'e.g. Robert Johnson',
        '(555) 123-4567',
        '742 Evergreen Terrace',
      ]) {
        final TextField f = tester.widget<TextField>(byHint(hint));
        expect(f.obscureText, isFalse,
            reason: '"$hint" is not a secret; obscuring it would '
                'HARD-DISABLE copy (editable_text.dart:2641-2646).');
        expect(f.keyboardType, isNot(TextInputType.text),
            reason: '"$hint" has a real purpose, so it must NOT have fallen '
                'back to TextField\'s default TextInputType.text. That '
                'fallback is exactly what a hint-only change leaves behind '
                '(Appendix B1).');
      }
    });

    testWidgets('EdenFieldPurpose.none genuinely resolves no autofill identity',
        (tester) async {
      // Covers the semantic half of the `none` decisions on the wizard fields
      // that cannot be mounted (see the note above): choosing `none` must mean
      // "no identity", not "some identity I forgot to set".
      final EdenFieldSemantics s = EdenFieldPurpose.none.semantics;
      expect(s.autofillHints, isNull,
          reason: 'EdenFieldSemantics uses null — never an empty list — for '
              '"no autofill purpose" (Appendix B6 asymmetry note).');
      expect(s.obscureText, isFalse);
    });
  });

  // ── dev_app/stories/inputs_story.dart ──────────────────────────────────────
  group('40-16 / dev_app/stories/inputs_story.dart', () {
    testWidgets('the interactive story demo field is explicitly none',
        (tester) async {
      await tester.pumpWidget(wrap(
        Builder(
          builder: (BuildContext context) => inputsInteractiveStory.build(
            context,
            const KnobValues(<String, Object>{
              'size': EdenInputSize.md,
              'enabled': true,
              'error': false,
            }),
          ),
        ),
      ));
      await tester.pump();

      final TextField field =
          tester.widget<TextField>(byHint('Type something...'));
      expectNoIdentity(field, 'The inputs story demo field');
      expect(field.obscureText, isFalse);
    });
  });
}
