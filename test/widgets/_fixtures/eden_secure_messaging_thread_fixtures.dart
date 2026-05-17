// Do NOT regenerate via LLM — hand-built secure messaging fixtures for EdenSecureMessagingThread.
// Realistic-but-fabricated patient/provider exchanges; no real PHI.
//
// Synthetic patient identifiers:
//   patient-alpha   — active provider-patient + attachments thread
//   patient-bravo   — system notification thread
//   patient-charlie — closed (read-only) billing dispute thread
//   patient-delta   — mixed-roles care-coordination thread

import 'package:eden_ui_flutter/src/widgets/eden_attachment_preview.dart';
import 'package:eden_ui_flutter/src/widgets/eden_secure_messaging_thread.dart';

class SecureMessagingFixtures {
  SecureMessagingFixtures._();

  /// Active provider/patient back-and-forth about a sertraline dosage
  /// follow-up. 5 messages alternating patient + provider. All encrypted
  /// + audit-tagged. Last message unread by recipient.
  static EdenSecureMessageThread activeProviderPatient({
    String patientId = 'patient-alpha',
  }) {
    return EdenSecureMessageThread(
      id: 'thread-alpha-001',
      patientId: patientId,
      subject: 'Sertraline dosage follow-up',
      participantNames: ['Alex Alpha', 'Dr. Smith, PsyD'],
      lastActivityAt: DateTime(2026, 5, 17, 14, 30),
      messages: [
        EdenSecureMessage(
          id: 'msg-001',
          threadId: 'thread-alpha-001',
          patientId: patientId,
          senderId: 'user-pat-alpha',
          senderName: 'Alex Alpha',
          senderRole: EdenMessageSenderRole.patient,
          sentAt: DateTime(2026, 5, 16, 9, 15),
          body: 'Hi Dr. Smith, the new dose seems to be working well — '
              'I noticed my sleep has improved. Should I continue at 50mg '
              'or step up?',
          readAt: DateTime(2026, 5, 16, 10, 30),
        ),
        EdenSecureMessage(
          id: 'msg-002',
          threadId: 'thread-alpha-001',
          patientId: patientId,
          senderId: 'user-prv-smith',
          senderName: 'Dr. Smith',
          senderRole: EdenMessageSenderRole.provider,
          sentAt: DateTime(2026, 5, 16, 11, 5),
          body: 'Great to hear. Let\'s stay at 50mg for another 4 weeks, '
              'then we can reassess at your follow-up. Any side effects?',
          readAt: DateTime(2026, 5, 16, 11, 30),
        ),
        EdenSecureMessage(
          id: 'msg-003',
          threadId: 'thread-alpha-001',
          patientId: patientId,
          senderId: 'user-pat-alpha',
          senderName: 'Alex Alpha',
          senderRole: EdenMessageSenderRole.patient,
          sentAt: DateTime(2026, 5, 16, 14, 20),
          body: 'No side effects so far. Mild dry mouth in the first week '
              'but that\'s resolved.',
          readAt: DateTime(2026, 5, 16, 15, 10),
        ),
        EdenSecureMessage(
          id: 'msg-004',
          threadId: 'thread-alpha-001',
          patientId: patientId,
          senderId: 'user-prv-smith',
          senderName: 'Dr. Smith',
          senderRole: EdenMessageSenderRole.provider,
          sentAt: DateTime(2026, 5, 17, 8, 0),
          body: 'Perfect. Your next appointment is June 14. See you then.',
          readAt: DateTime(2026, 5, 17, 9, 0),
        ),
        EdenSecureMessage(
          id: 'msg-005',
          threadId: 'thread-alpha-001',
          patientId: patientId,
          senderId: 'user-pat-alpha',
          senderName: 'Alex Alpha',
          senderRole: EdenMessageSenderRole.patient,
          sentAt: DateTime(2026, 5, 17, 14, 30),
          body: 'Sounds good. One quick question about insurance...',
          readAt: null, // unread by provider
        ),
      ],
    );
  }

  /// System-only thread — appointment reminders. isReadOnly=true.
  static EdenSecureMessageThread systemNotificationThread({
    String patientId = 'patient-bravo',
  }) {
    return EdenSecureMessageThread(
      id: 'thread-bravo-001',
      patientId: patientId,
      subject: 'Appointment reminders',
      participantNames: ['Brett Bravo', 'System'],
      lastActivityAt: DateTime(2026, 5, 17, 8, 0),
      isReadOnly: true,
      messages: [
        EdenSecureMessage(
          id: 'msg-sys-001',
          threadId: 'thread-bravo-001',
          patientId: patientId,
          senderId: 'system',
          senderName: 'System',
          senderRole: EdenMessageSenderRole.system,
          sentAt: DateTime(2026, 5, 10, 9, 0),
          body: 'Your appointment with Dr. Smith is confirmed for May 17 at '
              '10:00 AM.',
        ),
        EdenSecureMessage(
          id: 'msg-sys-002',
          threadId: 'thread-bravo-001',
          patientId: patientId,
          senderId: 'system',
          senderName: 'System',
          senderRole: EdenMessageSenderRole.system,
          sentAt: DateTime(2026, 5, 16, 10, 0),
          body: 'Reminder: appointment tomorrow at 10:00 AM.',
        ),
        EdenSecureMessage(
          id: 'msg-sys-003',
          threadId: 'thread-bravo-001',
          patientId: patientId,
          senderId: 'system',
          senderName: 'System',
          senderRole: EdenMessageSenderRole.system,
          sentAt: DateTime(2026, 5, 17, 9, 0),
          body: 'Reminder: appointment in 1 hour at 10:00 AM.',
        ),
      ],
    );
  }

  /// Closed billing-dispute thread. 8 messages; isReadOnly=true.
  static EdenSecureMessageThread closedReadOnly({
    String patientId = 'patient-charlie',
  }) {
    final base = DateTime(2026, 4, 1, 9, 0);
    final messages = <EdenSecureMessage>[];
    for (var i = 0; i < 8; i++) {
      final isPatient = i.isEven;
      messages.add(EdenSecureMessage(
        id: 'msg-charlie-${i + 1}',
        threadId: 'thread-charlie-001',
        patientId: patientId,
        senderId: isPatient ? 'user-pat-charlie' : 'user-staff-billing',
        senderName: isPatient ? 'Casey Charlie' : 'Billing Staff',
        senderRole: isPatient
            ? EdenMessageSenderRole.patient
            : EdenMessageSenderRole.staff,
        sentAt: base.add(Duration(days: i)),
        body: isPatient
            ? 'I have a question about my recent statement.'
            : 'Thanks for reaching out. We have reviewed your statement.',
        readAt: base.add(Duration(days: i, hours: 2)),
      ));
    }
    return EdenSecureMessageThread(
      id: 'thread-charlie-001',
      patientId: patientId,
      subject: 'Billing dispute resolution',
      participantNames: ['Casey Charlie', 'Billing Staff'],
      lastActivityAt: base.add(const Duration(days: 7)),
      isReadOnly: true,
      messages: messages,
    );
  }

  /// Thread with 2 attachments on one message (lab PDF + image).
  static EdenSecureMessageThread threadWithAttachments({
    String patientId = 'patient-alpha',
  }) {
    return EdenSecureMessageThread(
      id: 'thread-alpha-002',
      patientId: patientId,
      subject: 'Lab results review',
      participantNames: ['Alex Alpha', 'Dr. Smith, PsyD'],
      lastActivityAt: DateTime(2026, 5, 17, 12, 0),
      messages: [
        EdenSecureMessage(
          id: 'msg-att-001',
          threadId: 'thread-alpha-002',
          patientId: patientId,
          senderId: 'user-prv-smith',
          senderName: 'Dr. Smith',
          senderRole: EdenMessageSenderRole.provider,
          sentAt: DateTime(2026, 5, 17, 10, 0),
          body: 'Your CBC + TSH results are in. Both look great. '
              'Attached PDFs for your records.',
          attachments: const [
            EdenAttachment(
              name: 'cbc-2026-05-15.pdf',
              size: 245000,
              type: 'application/pdf',
            ),
            EdenAttachment(
              name: 'tsh-2026-05-15.pdf',
              size: 124000,
              type: 'application/pdf',
            ),
          ],
          readAt: null,
        ),
        EdenSecureMessage(
          id: 'msg-att-002',
          threadId: 'thread-alpha-002',
          patientId: patientId,
          senderId: 'user-pat-alpha',
          senderName: 'Alex Alpha',
          senderRole: EdenMessageSenderRole.patient,
          sentAt: DateTime(2026, 5, 17, 11, 30),
          body: 'Thank you!',
          readAt: DateTime(2026, 5, 17, 11, 45),
        ),
        EdenSecureMessage(
          id: 'msg-att-003',
          threadId: 'thread-alpha-002',
          patientId: patientId,
          senderId: 'user-prv-smith',
          senderName: 'Dr. Smith',
          senderRole: EdenMessageSenderRole.provider,
          sentAt: DateTime(2026, 5, 17, 12, 0),
          body: 'You\'re welcome. Reach out if you have questions.',
          readAt: DateTime(2026, 5, 17, 12, 30),
        ),
      ],
    );
  }

  /// Mixed-roles care-coordination thread.
  static EdenSecureMessageThread mixedRolesThread({
    String patientId = 'patient-delta',
  }) {
    return EdenSecureMessageThread(
      id: 'thread-delta-001',
      patientId: patientId,
      subject: 'Care coordination',
      participantNames: [
        'Drew Delta',
        'Dr. Lee, MD',
        'Care Coordinator',
        'System',
      ],
      lastActivityAt: DateTime(2026, 5, 17, 15, 0),
      messages: [
        EdenSecureMessage(
          id: 'msg-mix-001',
          threadId: 'thread-delta-001',
          patientId: patientId,
          senderId: 'user-pat-delta',
          senderName: 'Drew Delta',
          senderRole: EdenMessageSenderRole.patient,
          sentAt: DateTime(2026, 5, 16, 9, 0),
          body: 'Hi team, I was referred to Dr. Lee for cardiology.',
        ),
        EdenSecureMessage(
          id: 'msg-mix-002',
          threadId: 'thread-delta-001',
          patientId: patientId,
          senderId: 'user-prv-lee',
          senderName: 'Dr. Lee',
          senderRole: EdenMessageSenderRole.provider,
          sentAt: DateTime(2026, 5, 16, 10, 0),
          body: 'Welcome. Let\'s schedule your initial consult.',
        ),
        EdenSecureMessage(
          id: 'msg-mix-003',
          threadId: 'thread-delta-001',
          patientId: patientId,
          senderId: 'user-staff-coord',
          senderName: 'Care Coordinator',
          senderRole: EdenMessageSenderRole.staff,
          sentAt: DateTime(2026, 5, 16, 11, 0),
          body: 'I have a few times available next week — '
              'I will send a portal link.',
        ),
        EdenSecureMessage(
          id: 'msg-mix-004',
          threadId: 'thread-delta-001',
          patientId: patientId,
          senderId: 'system',
          senderName: 'System',
          senderRole: EdenMessageSenderRole.system,
          sentAt: DateTime(2026, 5, 16, 11, 5),
          body: 'Care coordinator scheduling link sent.',
        ),
        EdenSecureMessage(
          id: 'msg-mix-005',
          threadId: 'thread-delta-001',
          patientId: patientId,
          senderId: 'user-pat-delta',
          senderName: 'Drew Delta',
          senderRole: EdenMessageSenderRole.patient,
          sentAt: DateTime(2026, 5, 17, 14, 0),
          body: 'Booked for Thursday at 2pm. Thanks!',
        ),
        EdenSecureMessage(
          id: 'msg-mix-006',
          threadId: 'thread-delta-001',
          patientId: patientId,
          senderId: 'user-prv-lee',
          senderName: 'Dr. Lee',
          senderRole: EdenMessageSenderRole.provider,
          sentAt: DateTime(2026, 5, 17, 15, 0),
          body: 'See you Thursday. Please bring any prior cardiology records.',
        ),
      ],
    );
  }
}
