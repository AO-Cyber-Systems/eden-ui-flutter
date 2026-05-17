// EdenWorkflowActionFieldSpec — schema for action-config form fields.
//
// Drives the dynamic config-field UI rendered inside EdenActionNode's
// popover editor. Donor parity: ActionNode.tsx ACTION_CONFIG_FIELDS (lines
// 56-83).

/// A single option for a `select`-type field. Donor uses `{value, label}`
/// tuples; library mirrors with Dart records for type safety.
typedef EdenWorkflowActionFieldOption = ({String value, String label});

/// Spec for one form field inside an action's config editor.
///
/// `type` is one of: `'text'`, `'textarea'`, `'select'`, `'number'`.
/// For `select`, populate `options`.
///
/// Equality is by `id` (the field key within the action's config map).
class EdenWorkflowActionFieldSpec {
  const EdenWorkflowActionFieldSpec({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.options = const [],
    this.placeholder,
  });

  final String id;
  final String label;
  final String type;
  final bool required;
  final List<EdenWorkflowActionFieldOption> options;
  final String? placeholder;

  @override
  bool operator ==(Object other) =>
      other is EdenWorkflowActionFieldSpec && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Standard priority options used by `create_task` + `send_notification`
/// default field specs (donor parity — lines 240-249).
const List<EdenWorkflowActionFieldOption> kEdenWorkflowPriorityOptions = [
  (value: 'low', label: 'Low'),
  (value: 'normal', label: 'Normal'),
  (value: 'high', label: 'High'),
  (value: 'urgent', label: 'Urgent'),
];

/// Default field specs per action id (donor ACTION_CONFIG_FIELDS).
///
/// The 6 library defaults ship with these specs auto-attached to their
/// `EdenWorkflowActionType` entry. Consumer-registered action types provide
/// their own specs.
const Map<String, List<EdenWorkflowActionFieldSpec>> kEdenDefaultActionFieldSpecs = {
  'create_task': [
    EdenWorkflowActionFieldSpec(
      id: 'title',
      label: 'Task Title',
      type: 'text',
    ),
    EdenWorkflowActionFieldSpec(
      id: 'description',
      label: 'Description',
      type: 'textarea',
    ),
    EdenWorkflowActionFieldSpec(
      id: 'priority',
      label: 'Priority',
      type: 'select',
      options: kEdenWorkflowPriorityOptions,
    ),
  ],
  'send_notification': [
    EdenWorkflowActionFieldSpec(id: 'title', label: 'Title', type: 'text'),
    EdenWorkflowActionFieldSpec(
      id: 'message',
      label: 'Message',
      type: 'textarea',
    ),
    EdenWorkflowActionFieldSpec(
      id: 'priority',
      label: 'Priority',
      type: 'select',
      options: kEdenWorkflowPriorityOptions,
    ),
  ],
  'create_callback': [
    EdenWorkflowActionFieldSpec(id: 'reason', label: 'Reason', type: 'text'),
    EdenWorkflowActionFieldSpec(
      id: 'notes',
      label: 'Notes',
      type: 'textarea',
    ),
  ],
  'update_status': [
    EdenWorkflowActionFieldSpec(
      id: 'newStatus',
      label: 'New Status',
      type: 'text',
    ),
  ],
  'send_email': [
    EdenWorkflowActionFieldSpec(id: 'to', label: 'To', type: 'text'),
    EdenWorkflowActionFieldSpec(
      id: 'subject',
      label: 'Subject',
      type: 'text',
    ),
    EdenWorkflowActionFieldSpec(id: 'body', label: 'Body', type: 'textarea'),
  ],
  'send_sms': [
    EdenWorkflowActionFieldSpec(
      id: 'phoneNumber',
      label: 'Phone Number',
      type: 'text',
    ),
    EdenWorkflowActionFieldSpec(
      id: 'message',
      label: 'Message',
      type: 'textarea',
    ),
  ],
};
