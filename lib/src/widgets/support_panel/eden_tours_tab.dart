import 'package:flutter/material.dart';

import 'eden_support_panel_config.dart';

/// Stub widget for the Tours tab. Full implementation is added in TRD-04.
class EdenToursTab extends StatefulWidget {
  const EdenToursTab({super.key, required this.config});

  final EdenSupportPanelConfig config;

  @override
  State<EdenToursTab> createState() => _EdenToursTabState();
}

class _EdenToursTabState extends State<EdenToursTab> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tours will appear here',
        textAlign: TextAlign.center,
      ),
    );
  }
}
