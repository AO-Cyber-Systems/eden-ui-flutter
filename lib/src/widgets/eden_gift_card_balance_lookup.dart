// Sibling surface to EdenGiftCardManager (obj 015 — sell + reload + lookup
// composite). This widget is the staff-side lookup-only surface — same
// onLookup callback shape as the manager's lookup tab. When obj 015 lands,
// consumer apps may use either:
//   - EdenGiftCardBalanceLookup for a dedicated lookup screen, OR
//   - EdenGiftCardManager.lookup for the in-flow lookup tab.
// No code change needed in this widget when obj 015 lands.

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_activity_feed_item.dart';
import 'eden_alert.dart';
import 'eden_badge.dart';
import 'eden_currency_display.dart';
import 'eden_secret_field.dart';

// ─────────────────────────────────────────────────────────────────────────
// Value classes + enums
// ─────────────────────────────────────────────────────────────────────────

enum EdenGiftCardStatus { active, deactivated, expired, notFound }

enum EdenGiftCardActivityType { loaded, redeemed, refunded, adjustment, expired }

@immutable
class EdenGiftCardActivity {
  const EdenGiftCardActivity({
    required this.id,
    required this.occurredAt,
    required this.type,
    required this.amountCents,
    this.reason,
    this.receiptRef,
  });

  final String id;
  final DateTime occurredAt;
  final EdenGiftCardActivityType type;

  /// Signed amount. loaded / refunded positive; redeemed / expired negative;
  /// adjustment can be either. Render tint follows sign, not type.
  final int amountCents;

  final String? reason;
  final String? receiptRef;
}

@immutable
class EdenGiftCardBalanceResult {
  const EdenGiftCardBalanceResult({
    required this.cardNumber,
    required this.balanceCents,
    required this.status,
    this.recentActivity = const [],
    this.lastUsedAt,
    this.expiresAt,
  });

  /// Raw card number — masked by the widget before display via [cardMaskFn]
  /// or the default `'****-****-****-{last4}'` mask.
  final String cardNumber;

  final int balanceCents;
  final EdenGiftCardStatus status;
  final List<EdenGiftCardActivity> recentActivity;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;
}

// ─────────────────────────────────────────────────────────────────────────
// Library-private top-level helpers (exposed for unit tests).
// ─────────────────────────────────────────────────────────────────────────

String edenGiftCardDefaultMask(String full) {
  if (full.length < 4) return '****';
  return '****-****-****-${full.substring(full.length - 4)}';
}

String edenGiftCardStatusLabel(EdenGiftCardStatus s) {
  switch (s) {
    case EdenGiftCardStatus.active:
      return 'Active';
    case EdenGiftCardStatus.deactivated:
      return 'Deactivated';
    case EdenGiftCardStatus.expired:
      return 'Expired';
    case EdenGiftCardStatus.notFound:
      return 'Not found';
  }
}

EdenBadgeVariant edenGiftCardStatusBadgeVariant(EdenGiftCardStatus s) {
  switch (s) {
    case EdenGiftCardStatus.active:
      return EdenBadgeVariant.success;
    case EdenGiftCardStatus.deactivated:
      return EdenBadgeVariant.danger;
    case EdenGiftCardStatus.expired:
      return EdenBadgeVariant.neutral;
    case EdenGiftCardStatus.notFound:
      return EdenBadgeVariant.danger;
  }
}

String edenGiftCardActivityLabel(EdenGiftCardActivityType t) {
  switch (t) {
    case EdenGiftCardActivityType.loaded:
      return 'Loaded';
    case EdenGiftCardActivityType.redeemed:
      return 'Redeemed';
    case EdenGiftCardActivityType.refunded:
      return 'Refunded';
    case EdenGiftCardActivityType.adjustment:
      return 'Adjustment';
    case EdenGiftCardActivityType.expired:
      return 'Expired';
  }
}

String edenGiftCardFormatSignedMoney(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final dollars = abs ~/ 100;
  final fraction = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : '+'}\$$dollars.$fraction';
}

String edenGiftCardFormatRelativeTime(DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inSeconds.abs() < 60) return 'just now';
  if (diff.inMinutes.abs() < 60) {
    return diff.inMinutes >= 0
        ? '${diff.inMinutes}m ago'
        : 'in ${-diff.inMinutes}m';
  }
  if (diff.inHours.abs() < 24) {
    return diff.inHours >= 0
        ? '${diff.inHours}h ago'
        : 'in ${-diff.inHours}h';
  }
  if (diff.inHours.abs() < 48) {
    return diff.inHours >= 0 ? 'yesterday' : 'tomorrow';
  }
  if (diff.inDays.abs() < 14) {
    return diff.inDays >= 0
        ? '${diff.inDays}d ago'
        : 'in ${-diff.inDays}d';
  }
  if (diff.inDays.abs() < 60) {
    final wks = (diff.inDays / 7).floor();
    return wks >= 0 ? '${wks}w ago' : 'in ${-wks}w';
  }
  return '${then.month}/${then.day}/${then.year}';
}

// ─────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────

enum _LookupState { idle, loading, result, notFound }

class EdenGiftCardBalanceLookup extends StatefulWidget {
  const EdenGiftCardBalanceLookup({
    super.key,
    required this.onLookup,
    this.maxRecent = 5,
    this.cardMaskFn,
    this.now,
  });

  /// Consumer-supplied lookup callback. Return null to indicate `notFound`.
  /// Throws are caught internally and treated as `notFound`.
  final Future<EdenGiftCardBalanceResult?> Function(String cardNumber) onLookup;

  final int maxRecent;

  /// Override the default `'****-****-****-{last4}'` mask. Receives the raw
  /// card number from the lookup result; returns the user-facing display.
  final String Function(String fullCardNumber)? cardMaskFn;

  /// Injectable clock for deterministic tests.
  final DateTime? now;

  @override
  State<EdenGiftCardBalanceLookup> createState() =>
      _EdenGiftCardBalanceLookupState();
}

class _EdenGiftCardBalanceLookupState extends State<EdenGiftCardBalanceLookup> {
  String _draft = '';
  _LookupState _state = _LookupState.idle;
  EdenGiftCardBalanceResult? _result;

  DateTime _now() => widget.now ?? DateTime.now();

  Future<void> _doLookup() async {
    final query = _draft;
    setState(() => _state = _LookupState.loading);
    EdenGiftCardBalanceResult? res;
    try {
      res = await widget.onLookup(query);
    } catch (_) {
      res = null;
    }
    if (!mounted) return;
    setState(() {
      _result = res;
      _state = res == null ? _LookupState.notFound : _LookupState.result;
      _draft = '';
    });
  }

  void _onDraftChanged(String value) {
    setState(() {
      _draft = value;
      // If we were in notFound, typing transitions back to idle so the user
      // can retry without an extra clear-state interaction.
      if (_state == _LookupState.notFound) {
        _state = _LookupState.idle;
        _result = null;
      }
    });
  }

  bool get _canLookup =>
      _draft.length >= 4 && _state != _LookupState.loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Gift card balance lookup', style: theme.textTheme.titleLarge),
        const SizedBox(height: EdenSpacing.space3),
        _buildInputRow(context),
        _buildResultSection(context),
      ],
    );
  }

  Widget _buildInputRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 500;
        final field = EdenSecretField(
          label: 'Gift card #',
          value: _draft,
          clipboardMode: EdenSecretClipboardMode.classified,
          onChanged: _onDraftChanged,
        );
        final button = ElevatedButton(
          onPressed: _canLookup ? _doLookup : null,
          child: const Text('Lookup'),
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field,
              const SizedBox(height: EdenSpacing.space2),
              button,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: field),
            const SizedBox(width: EdenSpacing.space3),
            button,
          ],
        );
      },
    );
  }

  Widget _buildResultSection(BuildContext context) {
    switch (_state) {
      case _LookupState.idle:
        return const SizedBox.shrink();
      case _LookupState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Looking up...'),
            ],
          ),
        );
      case _LookupState.notFound:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: EdenAlert(
            variant: EdenAlertVariant.warning,
            message: 'Card not found. Check the number and try again.',
          ),
        );
      case _LookupState.result:
        return _buildResult(context, _result!);
    }
  }

  Widget _buildResult(BuildContext context, EdenGiftCardBalanceResult result) {
    final theme = Theme.of(context);
    final maskFn = widget.cardMaskFn ?? edenGiftCardDefaultMask;
    final n = _now();
    return Padding(
      padding: const EdgeInsets.only(top: EdenSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: masked # + status badge.
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(maskFn(result.cardNumber),
                  style: theme.textTheme.titleMedium),
              EdenBadge(
                label: edenGiftCardStatusLabel(result.status),
                variant: edenGiftCardStatusBadgeVariant(result.status),
                size: EdenBadgeSize.sm,
              ),
            ],
          ),
          const SizedBox(height: 8),
          EdenCurrencyDisplay(
            cents: result.balanceCents,
            style: theme.textTheme.headlineMedium,
          ),
          if (result.status == EdenGiftCardStatus.deactivated ||
              result.status == EdenGiftCardStatus.expired)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: EdenAlert(
                variant: EdenAlertVariant.warning,
                message: result.status == EdenGiftCardStatus.deactivated
                    ? 'This gift card is deactivated and cannot be redeemed.'
                    : 'This gift card has expired.',
              ),
            ),
          if (result.lastUsedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Last used: ${edenGiftCardFormatRelativeTime(result.lastUsedAt!, n)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (result.expiresAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Expires: ${edenGiftCardFormatRelativeTime(result.expiresAt!, n)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Recent activity (last ${widget.maxRecent})',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          if (result.recentActivity.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No recent activity'),
            )
          else
            for (final a in result.recentActivity.take(widget.maxRecent))
              EdenActivityFeedItem(
                item: EdenActivityFeedItemData(
                  actorName: 'Gift card',
                  actorInitials: 'GC',
                  action: edenGiftCardActivityLabel(a.type).toLowerCase(),
                  entityName:
                      '${edenGiftCardFormatSignedMoney(a.amountCents)}${a.reason != null ? ' — ${a.reason}' : ''}',
                  timeAgo: edenGiftCardFormatRelativeTime(a.occurredAt, n),
                  variant: a.amountCents >= 0
                      ? EdenActivityVariant.success
                      : EdenActivityVariant.info,
                ),
              ),
        ],
      ),
    );
  }
}
