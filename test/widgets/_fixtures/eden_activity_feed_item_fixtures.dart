// Do NOT regenerate via LLM — hand-built fixtures for EdenActivityFeedItem.
//
// 4 canonical activity rows (one per variant) + a long-entity-name row for
// iPhone-narrow soft-wrap assertions. Add new fixtures by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenActivityFeedItemFixtures {
  EdenActivityFeedItemFixtures._();

  static const EdenActivityFeedItemData successSample =
      EdenActivityFeedItemData(
    actorName: 'John Smith',
    actorInitials: 'JS',
    action: 'created',
    entityName: 'Customer #42',
    timeAgo: '5m ago',
    variant: EdenActivityVariant.success,
  );

  static const EdenActivityFeedItemData warningSample =
      EdenActivityFeedItemData(
    actorName: 'Maria Garcia',
    actorInitials: 'MG',
    action: 'flagged',
    entityName: 'Invoice #1029',
    timeAgo: '12m ago',
    variant: EdenActivityVariant.warning,
  );

  static const EdenActivityFeedItemData dangerSample =
      EdenActivityFeedItemData(
    actorName: 'Alex Park',
    actorInitials: 'AP',
    action: 'deleted',
    entityName: 'Project Atlas',
    timeAgo: '1h ago',
    variant: EdenActivityVariant.danger,
  );

  static const EdenActivityFeedItemData infoSample =
      EdenActivityFeedItemData(
    actorName: 'Dev Bot',
    actorInitials: 'DB',
    action: 'commented on',
    entityName: 'Ticket T-501',
    timeAgo: 'just now',
    variant: EdenActivityVariant.info,
  );

  static const EdenActivityFeedItemData longEntitySample =
      EdenActivityFeedItemData(
    actorName: 'Long Name',
    actorInitials: 'LN',
    action: 'updated',
    entityName:
        'A really long entity name that should ellipsize gracefully on narrow viewports',
    timeAgo: 'yesterday',
    variant: EdenActivityVariant.info,
  );
}
