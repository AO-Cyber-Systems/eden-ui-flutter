import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import 'eden_classification_banner.dart';

/// Redaction-pass status for a FOIA request.
enum EdenFoiaRedactionStatus { pending, inProgress, complete, blocked }

/// A FOIA (Freedom of Information Act) records request payload.
///
/// Federal use: HHS, DOJ, DOD FOIA workflows. Civilian re-use: GDPR
/// Data Subject Access Request (DSAR), customer data export, internal
/// records request.
@immutable
class EdenFoiaRequest {
  const EdenFoiaRequest({
    required this.id,
    required this.requesterName,
    required this.submittedAt,
    required this.dueAt,
    required this.subject,
    this.redactionPassStatus = EdenFoiaRedactionStatus.pending,
    this.exemptionCodes = const [],
    this.assignedTo,
    this.responseDocCount = 0,
    this.classification,
  });

  final String id;
  final String requesterName;
  final DateTime submittedAt;
  final DateTime dueAt;
  final String subject;
  final EdenFoiaRedactionStatus redactionPassStatus;

  /// Standard FOIA exemption codes (b1..b9). Library does not ship the
  /// human-readable descriptions; pass via
  /// [EdenFoiaRequestCard.exemptionDescriptions] to surface as tooltips.
  final List<String> exemptionCodes;

  final String? assignedTo;
  final int responseDocCount;

  /// Optional ICD 710 classification. When non-null, the card wraps in
  /// [EdenClassificationBannerScaffold].
  final EdenClassificationLevel? classification;
}

/// Renders a FOIA records-request card with due-date urgency pill,
/// redaction-pass status chip, standard FOIA exemption-code chips, and
/// an optional ICD 710 classification banner overlay.
///
/// Composes [EdenClassificationBannerScaffold] when
/// [EdenFoiaRequest.classification] is non-null.
///
/// Civilian re-use: same card serves any records-request workflow —
/// GDPR DSAR, customer-data export, internal records request.
class EdenFoiaRequestCard extends StatelessWidget {
  const EdenFoiaRequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.now,
    this.exemptionDescriptions,
  });

  final EdenFoiaRequest request;
  final ValueChanged<EdenFoiaRequest>? onTap;

  /// Optional `now` override for deterministic testing. Defaults to
  /// `DateTime.now()`.
  final DateTime? now;

  /// Optional map of exemption code → human-readable description for
  /// Tooltip surfacing. Library doesn't ship descriptions — consumer
  /// provides per their domain (federal FOIA b1..b9 standard, or
  /// custom GDPR DSAR codes for civilian re-use).
  final Map<String, String>? exemptionDescriptions;

  int get _daysRemaining {
    final t = now ?? DateTime.now();
    return request.dueAt.difference(t).inDays;
  }

  ({Color bg, Color fg, String label}) get _duePill {
    final days = _daysRemaining;
    if (days < 0) {
      return (
        bg: EdenColors.error,
        fg: const Color(0xFFFFFFFF),
        label: 'Overdue by ${-days} days',
      );
    }
    if (days < 7) {
      return (
        bg: EdenColors.error,
        fg: const Color(0xFFFFFFFF),
        label: '$days days remaining',
      );
    }
    if (days <= 14) {
      return (
        bg: EdenColors.warning,
        fg: const Color(0xFF000000),
        label: '$days days remaining',
      );
    }
    return (
      bg: EdenColors.success,
      fg: const Color(0xFFFFFFFF),
      label: '$days days remaining',
    );
  }

  String _formatDate(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${pad(t.month)}-${pad(t.day)}';
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final pill = _duePill;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  request.id,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Due urgency: ${pill.label}',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pill.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pill.label,
                    style: TextStyle(
                      color: pill.fg,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.subject,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Requested by ${request.requesterName}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              if (request.assignedTo != null)
                Text(
                  '· Assigned: ${request.assignedTo}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              if (request.responseDocCount > 0)
                Text(
                  '· ${request.responseDocCount} documents',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Chip(
                label: Text(
                  'redaction: ${request.redactionPassStatus.name}',
                  style: const TextStyle(fontSize: 11),
                ),
                visualDensity: VisualDensity.compact,
              ),
              for (final code in request.exemptionCodes)
                Tooltip(
                  message: exemptionDescriptions?[code] ?? 'FOIA exemption $code',
                  child: Chip(
                    label: Text(code, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Card(
      child: InkWell(
        onTap: onTap != null ? () => onTap!(request) : null,
        child: request.classification != null
            ? EdenClassificationBannerScaffold(
                level: request.classification!,
                child: _buildBody(context),
              )
            : _buildBody(context),
      ),
    );
    final semanticLabel = 'FOIA request ${request.id}, '
        'due ${_formatDate(request.dueAt)}, '
        'status ${request.redactionPassStatus.name}';
    return Semantics(
      label: semanticLabel,
      container: true,
      child: body,
    );
  }
}
