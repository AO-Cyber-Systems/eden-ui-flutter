import 'package:flutter/foundation.dart';

import '../widgets/eden_data_display/agent_intent_data.dart';
// FOR THE `componentId` STATICS ONLY. The decoder needs no widget to do its
// job, but keying `kIntentDataDecoders` off each widget's own static is what
// keeps the map from becoming a second list of re-typed id literals — the
// drift `kDataDisplayComponents` and its closed-partition test exist to
// close.
import '../widgets/eden_data_display/eden_data_display_exports.dart';
import 'eden_agent_intent.dart';

/// The outcome of decoding an agent-intent payload.
///
/// SEALED, so the compiler makes the caller handle both halves. Contract 5
/// says what this layer cannot do honestly becomes a refusal rather than a
/// guess or a crash; a sealed result is that rule expressed in the type
/// system instead of in a comment nobody re-reads.
@immutable
sealed class EdenIntentDecodeResult {
  const EdenIntentDecodeResult();
}

/// A payload this package can draw.
@immutable
final class EdenIntentDecoded extends EdenIntentDecodeResult {
  const EdenIntentDecoded({
    required this.componentId,
    required this.data,
    required this.actions,
  });

  /// The `component_id` that selected the decoder.
  final String componentId;

  /// One of the typed data classes from `agent_intent_data.dart`.
  final Object data;

  /// The payload's actions, still raw. Narrowing them to tool actions or
  /// proposal actions is per-component and belongs to the dispatcher, which
  /// knows which kind the widget takes.
  final List<EdenRawAction> actions;
}

/// A payload this package will not draw, and why.
///
/// ZERO ACTIONS, ALWAYS (contract 4). A refusal that kept the payload's
/// actions would offer controls for an observation that failed.
@immutable
final class EdenIntentRefused extends EdenIntentDecodeResult {
  const EdenIntentRefused({
    required this.reason,
    this.componentId,
    this.field,
  });

  /// Human-readable, and it NAMES THE CAUSE. "Could not render" is not a
  /// reason; it is the absence of one.
  final String reason;

  /// The id that failed, when the envelope was readable enough to say.
  final String? componentId;

  /// The offending field, when there was one.
  final String? field;

  @override
  String toString() => 'EdenIntentRefused($reason)';
}

/// Raised by the field readers, caught at the entry point, turned into an
/// [EdenIntentRefused]. Private: an exception never leaves this library.
class _FieldError implements Exception {
  _FieldError(this.field, this.message);
  final String field;
  final String message;
}

Map<String, dynamic> _obj(Object? v, String field) {
  if (v is! Map<String, dynamic>) {
    throw _FieldError(field, '"$field" is ${v.runtimeType}, want an object');
  }
  return v;
}

List<dynamic> _list(Object? v, String field) {
  if (v is! List) {
    throw _FieldError(field, '"$field" is ${v.runtimeType}, want a list');
  }
  return v;
}

String _string(Map<String, dynamic> m, String field) {
  final Object? v = m[field];
  if (v is! String) {
    throw _FieldError(field,
        '"$field" is ${v == null ? 'missing' : 'a ${v.runtimeType}'}, '
        'want a string');
  }
  return v;
}

/// An optional string. ABSENT STAYS ABSENT — this never substitutes `''`.
/// The recordings carry `notes` on some rows and not others, and collapsing
/// the two would make the nullable field pointless.
String? _stringOrNull(Map<String, dynamic> m, String field) {
  final Object? v = m[field];
  if (v == null) return null;
  if (v is! String) {
    throw _FieldError(field, '"$field" is a ${v.runtimeType}, want a string');
  }
  return v;
}

int _int(Map<String, dynamic> m, String field) {
  final Object? v = m[field];
  // NO COERCION FROM A STRING. A "5000" silently becoming 5000 is the same
  // class of defect as a defaulted currency: it renders a complete,
  // plausible value that nothing on screen distinguishes from a correct one.
  if (v is! int) {
    throw _FieldError(field,
        '"$field" is ${v == null ? 'missing' : 'a ${v.runtimeType}'}, '
        'want an integer');
  }
  return v;
}

bool _bool(Map<String, dynamic> m, String field, {bool? orElse}) {
  final Object? v = m[field];
  if (v == null && orElse != null) return orElse;
  if (v is! bool) {
    throw _FieldError(field,
        '"$field" is ${v == null ? 'missing' : 'a ${v.runtimeType}'}, '
        'want a boolean');
  }
  return v;
}

/// An RFC3339 instant, kept in the zone it arrived in.
///
/// NO `toLocal()`, matching every component in this package: a localised
/// instant renders a different wall clock on every machine, and under
/// golden capture the baseline would encode the CI runner's timezone.
DateTime _instant(Map<String, dynamic> m, String field) {
  final String raw = _string(m, field);
  final DateTime? parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw _FieldError(field, '"$field" is "$raw", want an RFC3339 instant');
  }
  return parsed;
}

typedef _DataDecoder = Object Function(Map<String, dynamic> data);

EdenAppointmentListData _appointments(Map<String, dynamic> d) {
  final List<EdenAppointmentSummary> rows = <EdenAppointmentSummary>[];
  for (final Object? raw in _list(d['appointments'], 'appointments')) {
    final Map<String, dynamic> a = _obj(raw, 'appointments[]');
    rows.add(EdenAppointmentSummary(
      id: _string(a, 'id'),
      clientName: _string(a, 'client_name'),
      serviceName: _string(a, 'service_name'),
      staffName: _string(a, 'staff_name'),
      startsAt: _instant(a, 'starts_at'),
      endsAt: _instant(a, 'ends_at'),
      status: _string(a, 'status'),
      notes: _stringOrNull(a, 'notes'),
    ));
  }
  // `truncated` is ABSENT in 01 and 02 and true in 04. Absent means not
  // truncated, which is why the data class defaults it rather than making
  // it nullable.
  return EdenAppointmentListData(
    appointments: rows,
    truncated: _bool(d, 'truncated', orElse: false),
  );
}

EdenRefusalData _refusal(Map<String, dynamic> d) => EdenRefusalData(
      reason: _string(d, 'text'),
      isError: _bool(d, 'is_error', orElse: true),
    );

EdenCustomerListData _customers(Map<String, dynamic> d) {
  final List<EdenCustomerSummary> rows = <EdenCustomerSummary>[];
  for (final Object? raw in _list(d['customers'], 'customers')) {
    final Map<String, dynamic> c = _obj(raw, 'customers[]');
    rows.add(EdenCustomerSummary(
      id: _string(c, 'id'),
      name: _string(c, 'name'),
      emailHint: _string(c, 'email_hint'),
    ));
  }
  return EdenCustomerListData(customers: rows);
}

EdenServiceListData _services(Map<String, dynamic> d) {
  final List<EdenServiceSummary> rows = <EdenServiceSummary>[];
  for (final Object? raw in _list(d['services'], 'services')) {
    final Map<String, dynamic> s = _obj(raw, 'services[]');
    rows.add(EdenServiceSummary(
      id: _string(s, 'id'),
      name: _string(s, 'name'),
      durationMinutes: _int(s, 'duration_minutes'),
      priceCents: _int(s, 'price_cents'),
    ));
  }
  return EdenServiceListData(services: rows);
}

EdenProposalData _proposal(Map<String, dynamic> d) => EdenProposalData(
      actionId: _string(d, 'action_id'),
      applied: _bool(d, 'applied'),
      status: _string(d, 'status'),
      expiresAt: _instant(d, 'expires_at'),
    );

/// `component_id` -> the decoder for its `intent.data`.
///
/// Keyed off each widget's OWN `componentId` static, never a re-typed
/// literal: a re-typed string is a second list, and a second list drifts.
final Map<String, _DataDecoder> kIntentDataDecoders = <String, _DataDecoder>{
  EdenAppointmentList.componentId: _appointments,
  EdenRefusal.componentId: _refusal,
  EdenCustomerList.componentId: _customers,
  EdenServiceList.componentId: _services,
  EdenProposalCard.componentId: _proposal,
};

/// Decode one agent-intent payload.
///
/// NEVER THROWS. Every failure — an unreadable envelope, an id with no
/// decoder, a missing or mistyped field, an unparseable instant — comes back
/// as an [EdenIntentRefused] naming the cause.
EdenIntentDecodeResult decodeAgentIntent(Map<String, dynamic> json) {
  late final EdenAgentIntent intent;
  try {
    intent = EdenAgentIntent.fromJson(json);
  } on FormatException catch (e) {
    return EdenIntentRefused(reason: e.message, field: 'component_id');
  }

  final _DataDecoder? decoder = kIntentDataDecoders[intent.componentId];
  if (decoder == null) {
    return EdenIntentRefused(
      componentId: intent.componentId,
      reason: 'no renderer for component_id "${intent.componentId}"',
    );
  }

  try {
    final Map<String, dynamic> data = _obj(intent.data, 'data');
    return EdenIntentDecoded(
      componentId: intent.componentId,
      data: decoder(data),
      actions: intent.actions,
    );
  } on _FieldError catch (e) {
    return EdenIntentRefused(
      componentId: intent.componentId,
      field: e.field,
      reason: '${intent.componentId}: ${e.message}',
    );
  }
}
