import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenWorkflowActionFieldSpec', () {
    test('constructs with required + sensible defaults', () {
      const f = EdenWorkflowActionFieldSpec(
        id: 'to',
        label: 'To',
        type: 'text',
      );
      expect(f.id, 'to');
      expect(f.label, 'To');
      expect(f.type, 'text');
      expect(f.required, isFalse);
      expect(f.options, isEmpty);
      expect(f.placeholder, isNull);
    });

    test('select with options', () {
      const f = EdenWorkflowActionFieldSpec(
        id: 'priority',
        label: 'Priority',
        type: 'select',
        options: [(value: 'low', label: 'Low')],
      );
      expect(f.options.length, 1);
      expect(f.options[0].value, 'low');
      expect(f.options[0].label, 'Low');
    });

    test('equality by id', () {
      const a = EdenWorkflowActionFieldSpec(
        id: 'priority',
        label: 'A',
        type: 'text',
      );
      const b = EdenWorkflowActionFieldSpec(
        id: 'priority',
        label: 'B',
        type: 'select',
      );
      expect(a, equals(b));
    });
  });

  group('Default action field specs (kEdenDefaultActionFieldSpecs)', () {
    test('create_task has 3 fields: title, description, priority', () {
      final fields = kEdenDefaultActionFieldSpecs['create_task']!;
      expect(fields.length, 3);
      expect(fields.map((f) => f.id).toList(),
          ['title', 'description', 'priority']);
      expect(
          fields.firstWhere((f) => f.id == 'priority').options.length, 4);
    });

    test('send_notification has 3 fields: title, message, priority', () {
      final fields = kEdenDefaultActionFieldSpecs['send_notification']!;
      expect(fields.map((f) => f.id).toList(),
          ['title', 'message', 'priority']);
    });

    test('create_callback has 2 fields: reason, notes', () {
      final fields = kEdenDefaultActionFieldSpecs['create_callback']!;
      expect(fields.map((f) => f.id).toList(), ['reason', 'notes']);
    });

    test('update_status has 1 field: newStatus', () {
      final fields = kEdenDefaultActionFieldSpecs['update_status']!;
      expect(fields.length, 1);
      expect(fields[0].id, 'newStatus');
    });

    test('send_email has 3 fields: to, subject, body', () {
      final fields = kEdenDefaultActionFieldSpecs['send_email']!;
      expect(fields.map((f) => f.id).toList(), ['to', 'subject', 'body']);
    });

    test('send_sms has 2 fields: phoneNumber, message', () {
      final fields = kEdenDefaultActionFieldSpecs['send_sms']!;
      expect(fields.map((f) => f.id).toList(), ['phoneNumber', 'message']);
    });

    test('kEdenWorkflowPriorityOptions has 4 levels low/normal/high/urgent', () {
      expect(kEdenWorkflowPriorityOptions.map((o) => o.value).toSet(),
          {'low', 'normal', 'high', 'urgent'});
    });
  });

  group('EdenWorkflowActionRegistry — fields auto-attached on defaults', () {
    setUp(() {
      EdenWorkflowActionRegistry.instance.resetToDefaults();
    });

    test('create_task lookup carries 3 field specs', () {
      final t = EdenWorkflowActionRegistry.instance.lookup('create_task');
      expect(t?.fields.length, 3);
    });

    test('send_email lookup carries 3 field specs', () {
      final t = EdenWorkflowActionRegistry.instance.lookup('send_email');
      expect(t?.fields.length, 3);
      expect(t!.fields.map((f) => f.id).toList(),
          ['to', 'subject', 'body']);
    });

    test('all 6 defaults have non-empty fields list', () {
      for (final id in [
        'create_task',
        'send_notification',
        'create_callback',
        'update_status',
        'send_email',
        'send_sms',
      ]) {
        final t = EdenWorkflowActionRegistry.instance.lookup(id);
        expect(t?.fields, isNotEmpty,
            reason: 'Action $id should have at least one field spec');
      }
    });

    test('consumer-registered action without fields gets empty fields list',
        () {
      EdenWorkflowActionRegistry.instance.reset();
      const custom = EdenWorkflowActionType(
        id: 'custom_no_fields',
        displayName: 'Custom',
        icon: Icons.abc,
      );
      EdenWorkflowActionRegistry.instance.register(custom);
      expect(
          EdenWorkflowActionRegistry.instance
              .lookup('custom_no_fields')
              ?.fields,
          isEmpty);
    });

    test('consumer-registered action with fields preserves them', () {
      EdenWorkflowActionRegistry.instance.reset();
      const custom = EdenWorkflowActionType(
        id: 'send_push',
        displayName: 'Send Push',
        icon: Icons.notifications_active,
        fields: [
          EdenWorkflowActionFieldSpec(
            id: 'deviceToken',
            label: 'Device Token',
            type: 'text',
          ),
          EdenWorkflowActionFieldSpec(
            id: 'title',
            label: 'Title',
            type: 'text',
          ),
          EdenWorkflowActionFieldSpec(
            id: 'body',
            label: 'Body',
            type: 'textarea',
          ),
        ],
      );
      EdenWorkflowActionRegistry.instance.register(custom);
      final t = EdenWorkflowActionRegistry.instance.lookup('send_push');
      expect(t?.fields.length, 3);
      expect(t!.fields.map((f) => f.id).toList(),
          ['deviceToken', 'title', 'body']);
    });
  });
}
