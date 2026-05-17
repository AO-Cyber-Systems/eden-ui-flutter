import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenWorkflowActionRegistry', () {
    setUp(() {
      EdenWorkflowActionRegistry.instance.resetToDefaults();
    });

    test('singleton — instance returns same instance across calls', () {
      final a = EdenWorkflowActionRegistry.instance;
      final b = EdenWorkflowActionRegistry.instance;
      expect(identical(a, b), isTrue);
    });

    test('resetToDefaults registers exactly 6 defaults', () {
      expect(EdenWorkflowActionRegistry.instance.all().length, 6);
    });

    test('all 6 default ids present after resetToDefaults', () {
      final ids =
          EdenWorkflowActionRegistry.instance.all().map((t) => t.id).toSet();
      expect(ids, {
        'create_task',
        'send_notification',
        'create_callback',
        'update_status',
        'send_email',
        'send_sms',
      });
    });

    test('lookup("send_email") returns Send Email with mail icon', () {
      final t = EdenWorkflowActionRegistry.instance.lookup('send_email');
      expect(t, isNotNull);
      expect(t!.displayName, 'Send Email');
      expect(t.icon, Icons.mail);
    });

    test('lookup("create_task") returns Create Task action type', () {
      final t = EdenWorkflowActionRegistry.instance.lookup('create_task');
      expect(t?.displayName, 'Create Task');
    });

    test('register adds new action type and lookup returns it', () {
      const push = EdenWorkflowActionType(
        id: 'send_push',
        displayName: 'Send Push Notification',
        icon: Icons.notifications_active,
      );
      EdenWorkflowActionRegistry.instance.register(push);
      expect(EdenWorkflowActionRegistry.instance.lookup('send_push'), push);
      expect(EdenWorkflowActionRegistry.instance.all().length, 7);
    });

    test('register called twice with same id throws StateError', () {
      const push = EdenWorkflowActionType(
        id: 'send_push',
        displayName: 'Send Push',
        icon: Icons.notifications_active,
      );
      EdenWorkflowActionRegistry.instance.register(push);
      expect(
        () => EdenWorkflowActionRegistry.instance.register(push),
        throwsA(isA<StateError>()),
      );
    });

    test('register throws on duplicate default id', () {
      const dup = EdenWorkflowActionType(
        id: 'send_email',
        displayName: 'Custom email',
        icon: Icons.email,
      );
      expect(
        () => EdenWorkflowActionRegistry.instance.register(dup),
        throwsA(isA<StateError>()),
      );
    });

    test('lookup returns null for nonexistent id', () {
      expect(
        EdenWorkflowActionRegistry.instance.lookup('nonexistent'),
        isNull,
      );
    });

    test('reset clears everything', () {
      EdenWorkflowActionRegistry.instance.reset();
      expect(EdenWorkflowActionRegistry.instance.all(), isEmpty);
    });

    test('resetToDefaults re-registers the 6 defaults exactly', () {
      EdenWorkflowActionRegistry.instance.reset();
      expect(EdenWorkflowActionRegistry.instance.all(), isEmpty);
      EdenWorkflowActionRegistry.instance.resetToDefaults();
      expect(EdenWorkflowActionRegistry.instance.all().length, 6);
    });

    test('defaultConfig defaults to empty map', () {
      const t = EdenWorkflowActionType(
        id: 'custom',
        displayName: 'Custom',
        icon: Icons.abc,
      );
      expect(t.defaultConfig, isEmpty);
    });

    test('EdenWorkflowActionType equality by id', () {
      const a = EdenWorkflowActionType(
        id: 'send_push',
        displayName: 'A',
        icon: Icons.notifications,
      );
      const b = EdenWorkflowActionType(
        id: 'send_push',
        displayName: 'B',
        icon: Icons.notifications_active,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
