import 'package:flutter/material.dart';

/// RED-phase stub — see /tmp/eden_starter_template_card_green.dart for the
/// real implementation. Tests should fail against this stub.
class EdenStarterTemplateCard extends StatelessWidget {
  const EdenStarterTemplateCard({
    super.key,
    required this.title,
    required this.description,
    this.thumbnail,
    this.effortLabel,
    this.selected = false,
    this.onSelect,
  });

  final String title;
  final String description;
  final Widget? thumbnail;
  final String? effortLabel;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
