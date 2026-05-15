// Do NOT regenerate via LLM — hand-built fixtures for the EdenAppTourOverlay
// + EdenContextualTip + EdenStarterTemplateCard triplet (TRD 001-12).
//
// Shared across the three onboarding-triplet widget tests so the test
// surface is consistent.

import 'package:flutter/material.dart';

@immutable
class StarterTemplateData {
  const StarterTemplateData({
    required this.title,
    required this.description,
    required this.effortLabel,
    required this.icon,
  });

  final String title;
  final String description;
  final String effortLabel;
  final IconData icon;
}

class StarterTemplateFixtures {
  StarterTemplateFixtures._();

  static const StarterTemplateData salonStarter = StarterTemplateData(
    title: 'Salon Quickstart',
    description: 'Pre-configured services + commission rules',
    effortLabel: '~10 min',
    icon: Icons.cut,
  );

  static const StarterTemplateData tradesStarter = StarterTemplateData(
    title: 'HVAC Pro',
    description: 'Work orders + dispatch + invoicing',
    effortLabel: '~15 min',
    icon: Icons.handyman,
  );

  static const StarterTemplateData medicalStarter = StarterTemplateData(
    title: 'Medical Practice',
    description: 'Patient intake + appointments + clinical notes',
    effortLabel: '~20 min',
    icon: Icons.medical_services,
  );

  static const StarterTemplateData legalStarter = StarterTemplateData(
    title: 'Legal Firm',
    description: 'Matter intake + time tracking + invoicing',
    effortLabel: '~15 min',
    icon: Icons.gavel,
  );
}

class ContextualTipFixtures {
  ContextualTipFixtures._();

  static const String shortMessage =
      'Drag phases from the palette to build your process flow';
  static const String longMessage =
      'This builder lets you sequence work into phases. Each phase '
      'has its own state machine; transitions trigger automations.';
}
