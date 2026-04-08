import 'package:flutter/material.dart';

import 'eden_support_panel_config.dart';

/// Stub widget for the Help tab. Full implementation is added in TRD-02.
class EdenHelpTab extends StatefulWidget {
  const EdenHelpTab({super.key, required this.config});

  final EdenSupportPanelConfig config;

  @override
  State<EdenHelpTab> createState() => _EdenHelpTabState();
}

class _EdenHelpTabState extends State<EdenHelpTab> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Help articles will appear here',
        textAlign: TextAlign.center,
      ),
    );
  }
}
