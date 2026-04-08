import 'package:flutter/material.dart';

import 'eden_support_panel_config.dart';
import 'support_panel_models.dart';

/// Stub ticket detail view. Full implementation added in TRD-03.
class EdenTicketDetailView extends StatelessWidget {
  const EdenTicketDetailView({
    super.key,
    required this.ticket,
    required this.config,
    required this.onBack,
  });

  final SupportTicket ticket;
  final EdenSupportPanelConfig config;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        ticket.subject,
        textAlign: TextAlign.center,
      ),
    );
  }
}
