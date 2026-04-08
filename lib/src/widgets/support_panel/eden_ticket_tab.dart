import 'package:flutter/material.dart';

import 'eden_support_panel_config.dart';

/// Stub widget for the Support tab. Full implementation is added in TRD-03.
class EdenTicketTab extends StatefulWidget {
  const EdenTicketTab({super.key, required this.config});

  final EdenSupportPanelConfig config;

  @override
  State<EdenTicketTab> createState() => _EdenTicketTabState();
}

class _EdenTicketTabState extends State<EdenTicketTab> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Support tickets will appear here',
        textAlign: TextAlign.center,
      ),
    );
  }
}
