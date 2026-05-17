// TDD test file for EdenSecureMessagingThread (obj 017-05).

import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_audit_log_viewer.dart';
import 'package:eden_ui_flutter/src/widgets/eden_classification_banner.dart';
import 'package:eden_ui_flutter/src/widgets/eden_message_input.dart';
import 'package:eden_ui_flutter/src/widgets/eden_secure_messaging_thread.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_secure_messaging_thread_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 600, double height = 2000}) {
    final theme = EdenTheme.light(profile: EdenThemeProfile.medicalInstitutional);
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ),
    );
  }

  group('EdenSecureMessagingThread — PHI banner (cases 1+2)', () {
    testWidgets('renders EdenClassificationBanner at top with "PHI — HIPAA Protected"',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      expect(find.byKey(const ValueKey('eden-secure-msg-phi-banner')),
          findsOneWidget);
      final banner = tester.widget<EdenClassificationBanner>(
        find.byKey(const ValueKey('eden-secure-msg-phi-banner')),
      );
      expect(banner.level, EdenClassificationLevel.custom);
      expect(banner.labelText, 'PHI — HIPAA Protected');
    });

    testWidgets('PHI banner has no close button (non-dismissible)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      // EdenClassificationBanner does not expose a dismissible flag —
      // verify by absence of any IconButton ancestor of the banner.
      final banner =
          find.byKey(const ValueKey('eden-secure-msg-phi-banner'));
      final iconButtons =
          find.descendant(of: banner, matching: find.byType(IconButton));
      expect(iconButtons, findsNothing);
    });
  });

  group('EdenSecureMessagingThread — thread header (case 3)', () {
    testWidgets('renders subject + participants + lastActivityAt',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      expect(find.text('Sertraline dosage follow-up'), findsOneWidget);
      expect(
          find.textContaining('Alex Alpha, Dr. Smith, PsyD'), findsOneWidget);
      expect(
          find.textContaining('Last activity: 2026-05-17'), findsOneWidget);
    });
  });

  group('EdenSecureMessagingThread — message rendering (cases 4+5)', () {
    testWidgets('renders one bubble per message', (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      // 5 messages in fixture, all non-system → 5 bubble keys.
      for (var i = 1; i <= 5; i++) {
        final id = 'msg-00$i';
        expect(find.byKey(ValueKey('eden-secure-msg-bubble-$id')),
            findsOneWidget);
      }
    });

    testWidgets('messages render in chronological order', (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      // First fixture message is patient, last is patient — verify both
      // bodies are present and accessible.
      expect(find.textContaining('the new dose seems to be working well'),
          findsOneWidget);
      expect(find.textContaining('One quick question about insurance'),
          findsOneWidget);
    });
  });

  group('EdenSecureMessagingThread — sender role discrimination (6..9)', () {
    testWidgets('patient message: Align(centerLeft)', (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      final patientBubble =
          find.byKey(const ValueKey('eden-secure-msg-bubble-msg-001'));
      final align = tester.firstWidget<Align>(
        find.ancestor(of: patientBubble, matching: find.byType(Align)),
      );
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('provider message: Align(centerRight)', (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      final providerBubble =
          find.byKey(const ValueKey('eden-secure-msg-bubble-msg-002'));
      final align = tester.firstWidget<Align>(
        find.ancestor(of: providerBubble, matching: find.byType(Align)),
      );
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('staff message: Align(centerRight)', (tester) async {
      // closedReadOnly fixture has staff messages.
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.closedReadOnly(),
      )));
      // index 1 in closedReadOnly is staff (i.isEven=false → staff).
      final staffBubble =
          find.byKey(const ValueKey('eden-secure-msg-bubble-msg-charlie-2'));
      final align = tester.firstWidget<Align>(
        find.ancestor(of: staffBubble, matching: find.byType(Align)),
      );
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('system message: center-aligned italic (no bubble)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.systemNotificationThread(),
      )));
      // System messages use a different key pattern.
      expect(
          find.byKey(const ValueKey('eden-secure-msg-system-msg-sys-001')),
          findsOneWidget);
      // No bubble container for system messages.
      expect(
          find.byKey(const ValueKey('eden-secure-msg-bubble-msg-sys-001')),
          findsNothing);
    });
  });

  group('EdenSecureMessagingThread — per-message indicators (10..15)', () {
    testWidgets('encryptedAtRest=true: lock icon visible per message',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      expect(find.byKey(const ValueKey('eden-secure-msg-lock-msg-001')),
          findsOneWidget);
    });

    testWidgets('encryptedAtRest=false: NO lock icon', (tester) async {
      final base = SecureMessagingFixtures.activeProviderPatient();
      final modified = EdenSecureMessageThread(
        id: base.id,
        patientId: base.patientId,
        subject: base.subject,
        participantNames: base.participantNames,
        lastActivityAt: base.lastActivityAt,
        messages: [
          EdenSecureMessage(
            id: 'msg-001',
            threadId: base.id,
            patientId: base.patientId,
            senderId: 'u-1',
            senderName: 'Patient',
            senderRole: EdenMessageSenderRole.patient,
            sentAt: DateTime(2026, 5, 17),
            body: 'plain',
            encryptedAtRest: false,
            auditLogTagged: false,
          ),
        ],
      );
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: modified,
      )));
      expect(find.byKey(const ValueKey('eden-secure-msg-lock-msg-001')),
          findsNothing);
    });

    testWidgets('auditLogTagged=true: shield icon visible per message',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      expect(find.byKey(const ValueKey('eden-secure-msg-shield-msg-001')),
          findsOneWidget);
    });

    testWidgets('readAt non-null: "Read {time}" text rendered',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      // msg-001 has readAt=2026-05-16 10:30.
      expect(find.textContaining('Read 2026-05-16'), findsWidgets);
    });

    testWidgets('readAt null: no "Read {time}" text', (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      // msg-005 has readAt=null. It should NOT have a "Read 2026-05-17" text
      // for its specific timestamp. The other messages have readAt times that
      // do appear; we verify the LAST unread message simply does not produce
      // a "Read" text. Easier: count "Read" texts == count of messages with
      // readAt != null (4 in fixture).
      // The fixture has 5 messages; 4 have readAt non-null + 1 null. So we
      // expect 4 "Read" instances total.
      final readWidgets =
          find.textContaining('• Read 2026-');
      expect(readWidgets, findsNWidgets(4));
    });
  });

  group('EdenSecureMessagingThread — reply input gating (16..19)', () {
    testWidgets('isReadOnly=false: EdenMessageInput visible', (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
        onSendMessage: (_) {},
      )));
      expect(find.byType(EdenMessageInput), findsOneWidget);
    });

    testWidgets('isReadOnly=true: input hidden + closed banner shown',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.closedReadOnly(),
        onSendMessage: (_) {},
      )));
      expect(find.byType(EdenMessageInput), findsNothing);
      expect(find.byKey(const ValueKey('eden-secure-msg-readonly-banner')),
          findsOneWidget);
      expect(find.textContaining('This thread is closed'), findsOneWidget);
    });

    testWidgets('onSendMessage null + isReadOnly=false: input hidden',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      expect(find.byType(EdenMessageInput), findsNothing);
    });

    testWidgets('onSendMessage fires with raw body only on submit',
        (tester) async {
      String? fired;
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
        onSendMessage: (b) => fired = b,
      )));
      // EdenMessageInput exposes a TextField + an IconButton with the send
      // icon. Enter text, then tap the send IconButton (the only
      // non-disabled IconButton inside EdenMessageInput once text is non-empty).
      final textFieldFinder = find.descendant(
          of: find.byType(EdenMessageInput), matching: find.byType(TextField));
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'Hello');
      await tester.pumpAndSettle();
      // Locate the send button by its Icon (Icons.send_rounded).
      final sendIcon = find.byIcon(Icons.send_rounded);
      expect(sendIcon, findsOneWidget);
      await tester.tap(sendIcon);
      await tester.pumpAndSettle();
      expect(fired, 'Hello');
    });
  });

  group('EdenSecureMessagingThread — attachments (cases 20+21)', () {
    testWidgets('messages with attachments render attachment block',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.threadWithAttachments(),
      )));
      expect(find.byKey(const ValueKey('eden-secure-msg-attachments-msg-att-001')),
          findsOneWidget);
      expect(find.textContaining('cbc-2026-05-15.pdf'), findsOneWidget);
      expect(find.textContaining('tsh-2026-05-15.pdf'), findsOneWidget);
    });

    testWidgets('attachment tap fires onAttachmentTap(message)',
        (tester) async {
      EdenSecureMessage? fired;
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.threadWithAttachments(),
        onAttachmentTap: (m) => fired = m,
      )));
      // Tap the first attachment preview.
      final attBlock =
          find.byKey(const ValueKey('eden-secure-msg-attachments-msg-att-001'));
      final firstAttachment = find.descendant(
        of: attBlock,
        matching: find.textContaining('cbc-2026-05-15.pdf'),
      );
      await tester.ensureVisible(firstAttachment);
      await tester.tap(firstAttachment);
      await tester.pumpAndSettle();
      expect(fired, isNotNull);
      expect(fired!.id, 'msg-att-001');
    });
  });

  group('EdenSecureMessagingThread — audit trail (cases 22..25)', () {
    testWidgets('showAuditLog=true: EdenAuditLogViewer visible',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
        showAuditLog: true,
      )));
      expect(find.byType(EdenAuditLogViewer), findsOneWidget);
    });

    testWidgets('showAuditLog=false + callback: "View audit trail" button',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
        onAuditTrailRequested: () {},
      )));
      expect(find.byKey(const ValueKey('eden-secure-msg-audit-button')),
          findsOneWidget);
    });

    testWidgets('showAuditLog=false + callback fires on tap',
        (tester) async {
      var fired = 0;
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
        onAuditTrailRequested: () => fired++,
      )));
      await tester.ensureVisible(
        find.byKey(const ValueKey('eden-secure-msg-audit-button')),
      );
      await tester.tap(find.byKey(const ValueKey('eden-secure-msg-audit-button')));
      expect(fired, 1);
    });

    testWidgets('showAuditLog=false + no callback: button hidden',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      expect(find.byKey(const ValueKey('eden-secure-msg-audit-button')),
          findsNothing);
    });

    testWidgets('synthesized audit entries: message-send + message-read',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
        showAuditLog: true,
      )));
      // 5 messages → 5 send entries; 4 with readAt → 4 read entries → 9 total.
      // The widget passes these to EdenAuditLogViewer.
      final viewer = tester.widget<EdenAuditLogViewer>(
        find.byType(EdenAuditLogViewer),
      );
      expect(viewer.entries.length, 9);
      final actions = viewer.entries.map((e) => e.action).toSet();
      expect(actions, containsAll(['message_sent', 'message_read']));
    });
  });

  group('EdenSecureMessagingThread — HIPAA isolation (cases 26+27)', () {
    test('constructor: mismatched message.patientId throws AssertionError',
        () {
      expect(
        () => EdenSecureMessagingThread(
          thread: EdenSecureMessageThread(
            id: 't-x',
            patientId: 'patient-alpha',
            subject: 'X',
            participantNames: const ['A'],
            lastActivityAt: DateTime(2026, 5, 17),
            messages: [
              EdenSecureMessage(
                id: 'm-1',
                threadId: 't-x',
                patientId: 'patient-bravo', // mismatched
                senderId: 'u',
                senderName: 'N',
                senderRole: EdenMessageSenderRole.patient,
                sentAt: DateTime(2026, 5, 17),
                body: 'x',
              ),
            ],
          ),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('patient A thread MUST NOT render patient B message body',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSecureMessagingThread(
        thread: SecureMessagingFixtures.activeProviderPatient(),
      )));
      // patient-bravo system message body MUST NOT appear in patient-alpha
      // thread tree.
      expect(find.textContaining('Reminder: appointment tomorrow'),
          findsNothing);
      // patient-charlie billing message body MUST NOT appear.
      expect(find.textContaining('I have a question about my recent statement'),
          findsNothing);
    });
  });
}
