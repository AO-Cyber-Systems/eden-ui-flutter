import 'package:flutter/foundation.dart';

/// What the HOST knows and the payload does not.
///
/// Two components need information no eden-biz recording carries:
///
///  * [currencyCode] — `list/services` sends `price_cents` with nothing to
///    interpret it by (eden-biz#860). `appointment_types`, the only table
///    that table quotes prices from, has no `currency` column while eleven
///    other eden-biz tables have one.
///  * [proposalSubject] — `card/proposal` sends `action_id`, `applied`,
///    `status` and `expires_at` and nothing naming the mutation
///    (eden-biz#863).
///
/// BOTH ARE NULLABLE HERE AND REQUIRED ON THE WIDGETS, and the gap between
/// those two facts is the whole design. The widgets cannot default them: a
/// price in the wrong currency renders as convincingly as one in the right
/// currency, and a proposal with no subject asks for consent to something
/// unnamed. So when the host cannot supply what a component needs, the
/// DISPATCHER REFUSES and says which field was missing. It never guesses.
///
/// PER DISPATCH, not per app. One call renders one intent, so
/// [proposalSubject] describes that intent's proposal. A host rendering a
/// list of proposals builds a context per card.
///
/// The right fix is on the other side of the wire — a `currency` column, and
/// `tool_id` + `summary` on the proposal payload — after which these fields
/// come from the payload and stop being the caller's problem.
@immutable
class EdenIntentHostContext {
  const EdenIntentHostContext({
    this.currencyCode,
    this.proposalSubject,
  });

  /// Nothing supplied. The three components that need no context still
  /// render; the two that do will refuse.
  static const EdenIntentHostContext empty = EdenIntentHostContext();

  /// ISO 4217, rendered verbatim and NOT normalised — eden-biz stores
  /// `'USD'` on ten tables and `'usd'` on `payment_intents`, and
  /// upper-casing here would hide that split behind a renderer that always
  /// looks right.
  final String? currencyCode;

  /// One line naming what approving the proposal will do.
  final String? proposalSubject;

  @override
  bool operator ==(Object other) =>
      other is EdenIntentHostContext &&
      other.currencyCode == currencyCode &&
      other.proposalSubject == proposalSubject;

  @override
  int get hashCode => Object.hash(currencyCode, proposalSubject);
}
