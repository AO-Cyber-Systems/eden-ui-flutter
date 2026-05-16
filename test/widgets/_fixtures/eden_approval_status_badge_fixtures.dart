// Do NOT regenerate via LLM — hand-built fixtures for EdenApprovalStatusBadge.
//
// Constants for the 10 canonical approval statuses + alias + unknown samples
// enumerated in 003-03-TRD.md test list. Add new tuples by hand only.

class EdenApprovalStatusBadgeFixtures {
  EdenApprovalStatusBadgeFixtures._();

  /// All 11 input strings the donor + library recognise (10 canonical statuses
  /// plus the `pending_approval` alias).
  static const List<String> knownStatuses = <String>[
    'pending',
    'pending_approval',
    'approved',
    'rejected',
    'draft',
    'ordered',
    'received',
    'in_transit',
    'completed',
    'fulfilled',
    'cancelled',
  ];

  /// Display labels for each known input. `pending_approval` aliases to
  /// 'Pending'. `in_transit` is hand-written 'In Transit' (NOT default-branch
  /// underscore replacement).
  static const Map<String, String> expectedLabels = <String, String>{
    'pending': 'Pending',
    'pending_approval': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'draft': 'Draft',
    'ordered': 'Ordered',
    'received': 'Received',
    'in_transit': 'In Transit',
    'completed': 'Completed',
    'fulfilled': 'Fulfilled',
    'cancelled': 'Cancelled',
  };

  /// Unknown samples for default-branch testing. `Approved` (uppercase) falls
  /// through the case-sensitive switch and lands in the default branch.
  static const List<String> unknownSamples = <String>[
    'in_review',
    'awaiting',
    'Approved',
  ];
}
