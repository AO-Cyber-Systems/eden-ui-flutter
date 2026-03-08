import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class BadgesAlertsScreen extends StatelessWidget {
  const BadgesAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badges & Alerts')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
            title: 'Badge Variants',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EdenBadgeVariant.values.map((v) => EdenBadge(
                label: v.name[0].toUpperCase() + v.name.substring(1),
                variant: v,
              )).toList(),
            ),
          ),
          Section(
            title: 'Badge Sizes',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: EdenBadgeSize.values.map((s) => EdenBadge(
                label: s.name.toUpperCase(),
                size: s,
              )).toList(),
            ),
          ),
          Section(
            title: 'Badge with Icon',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenBadge(label: 'Active', icon: Icons.circle, variant: EdenBadgeVariant.success, size: EdenBadgeSize.sm),
                EdenBadge(label: 'Pending', icon: Icons.schedule, variant: EdenBadgeVariant.warning),
                EdenBadge(label: 'Error', icon: Icons.error_outline, variant: EdenBadgeVariant.danger),
              ],
            ),
          ),
          const EdenDivider(label: 'Alerts'),
          Section(
            title: 'Alert Variants',
            child: Column(
              children: EdenAlertVariant.values.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EdenAlert(
                  title: '${v.name[0].toUpperCase()}${v.name.substring(1)} Alert',
                  message: 'This is a ${v.name} alert message with relevant details.',
                  variant: v,
                ),
              )).toList(),
            ),
          ),
          Section(
            title: 'Dismissible Alert',
            child: EdenAlert(
              title: 'Dismissible',
              message: 'This alert can be dismissed.',
              variant: EdenAlertVariant.info,
              dismissible: true,
              onDismiss: () {},
            ),
          ),
        ],
      ),
    );
  }
}
