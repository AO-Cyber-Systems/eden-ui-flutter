import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'eden_attachment_preview.dart';
import 'eden_audit_log_viewer.dart';
import 'eden_classification_banner.dart';
import 'eden_message_input.dart';

/// Sender role for a [EdenSecureMessage]. Drives visual treatment +
/// alignment of the rendered message bubble.
enum EdenMessageSenderRole {
  /// Patient — left-aligned light blue bubble.
  patient,

  /// Provider (clinician) — right-aligned teal bubble.
  provider,

  /// Staff (front desk / billing / care-coordinator) — right-aligned
  /// gray bubble.
  staff,

  /// System (automated message) — center-aligned italic, no bubble fill.
  system,
}

/// A single secure message within a [EdenSecureMessageThread].
@immutable
class EdenSecureMessage {
  const EdenSecureMessage({
    required this.id,
    required this.threadId,
    required this.patientId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.sentAt,
    required this.body,
    this.readAt,
    this.attachments = const [],
    this.encryptedAtRest = true,
    this.auditLogTagged = true,
  });

  /// Stable id.
  final String id;

  /// Parent thread id.
  final String threadId;

  /// HIPAA isolation key — MUST equal the thread's patientId.
  final String patientId;

  /// Sender's user id.
  final String senderId;

  /// Sender's display name.
  final String senderName;

  /// Sender role (drives visual styling).
  final EdenMessageSenderRole senderRole;

  /// When the message was sent.
  final DateTime sentAt;

  /// Message body text.
  final String body;

  /// When the recipient read the message; null = unread.
  final DateTime? readAt;

  /// Optional file/image attachments.
  final List<EdenAttachment> attachments;

  /// Display indicator only — consumer wires actual encryption.
  final bool encryptedAtRest;

  /// Display indicator only — consumer wires actual audit logging.
  final bool auditLogTagged;
}

/// Aggregate secure-messaging thread value class.
@immutable
class EdenSecureMessageThread {
  const EdenSecureMessageThread({
    required this.id,
    required this.patientId,
    required this.subject,
    required this.participantNames,
    required this.messages,
    this.isReadOnly = false,
    required this.lastActivityAt,
  });

  /// Stable thread id.
  final String id;

  /// HIPAA isolation key.
  final String patientId;

  /// Subject line.
  final String subject;

  /// Participant display names for the header.
  final List<String> participantNames;

  /// Chronological message list (oldest first).
  final List<EdenSecureMessage> messages;

  /// When true: reply input is hidden + 'thread closed' banner shown.
  final bool isReadOnly;

  /// Timestamp of most recent activity (display only).
  final DateTime lastActivityAt;
}

/// HIPAA-aware secure messaging thread (obj 017-05).
///
/// Composes obj 011-01 [EdenClassificationBanner] for the PHI banner,
/// obj 011-04 [EdenAuditLogViewer] for the optional audit trail, and
/// [EdenMessageInput] for the reply input. Per-message lock + shield
/// icons surface encryption + audit-log discipline.
///
/// **HIPAA isolation** — constructor asserts that every message's
/// patientId equals the thread's patientId. Mismatches throw
/// [AssertionError] in debug.
///
/// **Library is transport-agnostic** — consumer wires actual encryption,
/// audit-log persistence, E2E key management. The widget renders the UX
/// cues.
class EdenSecureMessagingThread extends StatelessWidget {
  EdenSecureMessagingThread({
    super.key,
    required this.thread,
    this.onSendMessage,
    this.onMessageTap,
    this.onAttachmentTap,
    this.onAuditTrailRequested,
    this.showAuditLog = false,
  }) : assert(
          thread.messages.every((m) => m.patientId == thread.patientId),
          'EdenSecureMessagingThread: every message.patientId must equal '
          'thread.patientId (${thread.patientId}). HIPAA isolation invariant.',
        );

  /// The thread to render.
  final EdenSecureMessageThread thread;

  /// Fires with the raw body string when the user submits the reply
  /// input. Does NOT include patientId or threadId — consumer attaches
  /// metadata before persisting.
  final ValueChanged<String>? onSendMessage;

  /// Fires when the user taps a message (e.g., for context menu / detail).
  final ValueChanged<EdenSecureMessage>? onMessageTap;

  /// Fires when the user taps an attachment.
  final ValueChanged<EdenSecureMessage>? onAttachmentTap;

  /// Fires when the user taps "View audit trail" (when showAuditLog=false).
  final VoidCallback? onAuditTrailRequested;

  /// When true: render [EdenAuditLogViewer] below the messages with
  /// synthesized audit entries from message-send + message-read events.
  /// When false: render an escalation button when [onAuditTrailRequested]
  /// is non-null.
  final bool showAuditLog;

  // medicalInstitutional teal (placeholder until obj 009 theme extension
  // exposes it via context lookup).
  static const Color _medicalTeal = Color(0xFF008080);
  static const Color _patientBlue = Color(0xFFE3F2FD);
  static const Color _staffGray = Color(0xFFF0F0F0);

  static String _formatTimestamp(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${pad(t.month)}-${pad(t.day)} '
        '${pad(t.hour)}:${pad(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPhiBanner(context),
        const SizedBox(height: EdenSpacing.space2),
        _buildThreadHeader(context, theme),
        const SizedBox(height: EdenSpacing.space3),
        for (final m in thread.messages) ...[
          _buildMessage(context, theme, m),
          const SizedBox(height: EdenSpacing.space2),
        ],
        const SizedBox(height: EdenSpacing.space2),
        _buildReplyArea(context, theme),
        const SizedBox(height: EdenSpacing.space3),
        _buildAuditSection(context, theme),
      ],
    );
  }

  Widget _buildPhiBanner(BuildContext context) {
    return const EdenClassificationBanner(
      key: ValueKey('eden-secure-msg-phi-banner'),
      level: EdenClassificationLevel.custom,
      labelText: 'PHI — HIPAA Protected',
      backgroundColor: _medicalTeal,
      foregroundColor: Colors.white,
      display: EdenClassificationDisplay.bar,
    );
  }

  Widget _buildThreadHeader(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          thread.subject,
          style: (theme.textTheme.titleMedium ?? const TextStyle())
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: EdenSpacing.space1),
        Text(
          'Participants: ${thread.participantNames.join(', ')}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          'Last activity: ${_formatTimestamp(thread.lastActivityAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(
    BuildContext context,
    ThemeData theme,
    EdenSecureMessage m,
  ) {
    if (m.senderRole == EdenMessageSenderRole.system) {
      return _buildSystemMessage(context, theme, m);
    }
    final isLeft = m.senderRole == EdenMessageSenderRole.patient;
    final bg = switch (m.senderRole) {
      EdenMessageSenderRole.provider => _medicalTeal.withValues(alpha: 0.15),
      EdenMessageSenderRole.staff => _staffGray,
      EdenMessageSenderRole.patient => _patientBlue,
      EdenMessageSenderRole.system => Colors.transparent,
    };
    final bubble = Container(
      key: ValueKey('eden-secure-msg-bubble-${m.id}'),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(EdenRadii.lg),
      ),
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSenderRow(theme, m),
          const SizedBox(height: EdenSpacing.space1),
          Text(m.body, style: theme.textTheme.bodyMedium),
          if (m.attachments.isNotEmpty) ...[
            const SizedBox(height: EdenSpacing.space2),
            _buildAttachmentBlock(context, m),
          ],
          const SizedBox(height: EdenSpacing.space1),
          _buildTimestampRow(theme, m),
        ],
      ),
    );

    Widget aligned = Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: bubble,
      ),
    );

    if (onMessageTap != null) {
      aligned = InkWell(
        key: ValueKey('eden-secure-msg-tap-${m.id}'),
        borderRadius: BorderRadius.circular(EdenRadii.lg),
        onTap: () => onMessageTap!(m),
        child: aligned,
      );
    }
    return aligned;
  }

  Widget _buildSystemMessage(
    BuildContext context,
    ThemeData theme,
    EdenSecureMessage m,
  ) {
    return Align(
      key: ValueKey('eden-secure-msg-system-${m.id}'),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space1,
        ),
        child: Text(
          m.body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSenderRow(ThemeData theme, EdenSecureMessage m) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            m.senderName,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (m.encryptedAtRest) ...[
          const SizedBox(width: EdenSpacing.space1),
          Tooltip(
            message: 'Encrypted at rest',
            child: Icon(
              Icons.lock_outline,
              size: 14,
              key: ValueKey('eden-secure-msg-lock-${m.id}'),
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimestampRow(ThemeData theme, EdenSecureMessage m) {
    return Wrap(
      spacing: EdenSpacing.space1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          _formatTimestamp(m.sentAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (m.auditLogTagged)
          Tooltip(
            message: 'Logged for HIPAA audit',
            child: Icon(
              Icons.shield_outlined,
              size: 14,
              key: ValueKey('eden-secure-msg-shield-${m.id}'),
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (m.readAt != null)
          Text(
            '• Read ${_formatTimestamp(m.readAt!)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildAttachmentBlock(BuildContext context, EdenSecureMessage m) {
    return Column(
      key: ValueKey('eden-secure-msg-attachments-${m.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final att in m.attachments) ...[
          EdenAttachmentPreview(
            attachment: att,
            onTap: onAttachmentTap == null ? null : () => onAttachmentTap!(m),
          ),
          const SizedBox(height: EdenSpacing.space1),
        ],
      ],
    );
  }

  Widget _buildReplyArea(BuildContext context, ThemeData theme) {
    if (thread.isReadOnly) {
      return Container(
        key: const ValueKey('eden-secure-msg-readonly-banner'),
        width: double.infinity,
        padding: const EdgeInsets.all(EdenSpacing.space3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(EdenRadii.md),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              child: Text(
                'This thread is closed. Contact your provider for follow-up.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (onSendMessage == null) {
      return const SizedBox.shrink();
    }
    return EdenMessageInput(
      key: const ValueKey('eden-secure-msg-input'),
      onSubmit: (body) => onSendMessage!(body),
    );
  }

  Widget _buildAuditSection(BuildContext context, ThemeData theme) {
    if (showAuditLog) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audit trail',
            style: (theme.textTheme.titleSmall ?? const TextStyle())
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: EdenSpacing.space2),
          EdenAuditLogViewer(
            key: const ValueKey('eden-secure-msg-audit-viewer'),
            entries: _synthesizeAudit(),
            showFilters: false,
          ),
        ],
      );
    }
    if (onAuditTrailRequested == null) return const SizedBox.shrink();
    return OutlinedButton.icon(
      key: const ValueKey('eden-secure-msg-audit-button'),
      icon: const Icon(Icons.history),
      label: const Text('View audit trail'),
      onPressed: onAuditTrailRequested,
    );
  }

  List<EdenAuditLogEntry> _synthesizeAudit() {
    final entries = <EdenAuditLogEntry>[];
    for (final m in thread.messages) {
      entries.add(EdenAuditLogEntry(
        id: '${m.id}-sent',
        timestamp: m.sentAt,
        actor: m.senderName,
        action: 'message_sent',
        target: 'thread:${thread.id}',
        category: 'messaging',
      ));
      if (m.readAt != null) {
        entries.add(EdenAuditLogEntry(
          id: '${m.id}-read',
          timestamp: m.readAt!,
          actor: 'Recipient',
          action: 'message_read',
          target: 'message:${m.id}',
          category: 'messaging',
        ));
      }
    }
    return entries;
  }
}
