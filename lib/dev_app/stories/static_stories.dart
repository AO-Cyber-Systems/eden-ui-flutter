// lib/dev_app/stories/static_stories.dart
//
// Zero-knob EdenStory wrappers for all 33 non-interactive screens.
//
// These stories render their respective screen at fixed size with no knob
// controls — they exist to make every screen visible in the explorer and
// to provide a stable pump target for the registry smoke test.
//
// Each id uses lowercase kebab-case: `<component>/<component>`.
// StatefulWidget screens use a non-const call; StatelessWidget screens use
// a const call (where the constructor permits it).

import 'package:flutter/material.dart';

import '../registry/eden_story.dart';
import '../screens/avatars_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/colors_screen.dart';
import '../screens/commerce_screen.dart';
import '../screens/companion_screen.dart';
import '../screens/compliance_screen.dart';
import '../screens/composers_screen.dart';
import '../screens/compound_screen.dart';
import '../screens/data_display_screen.dart';
import '../screens/devflow_infra_screen.dart';
import '../screens/devflow_project_screen.dart';
import '../screens/devflow_tools_screen.dart';
import '../screens/diagram_screen.dart';
import '../screens/eod_screen.dart';
import '../screens/field_screen.dart';
import '../screens/fuel_screen.dart';
import '../screens/layouts_screen.dart';
import '../screens/medical_screen.dart';
import '../screens/misc_screen.dart';
import '../screens/motion_screen.dart';
import '../screens/process_builder_screen.dart';
import '../screens/retail_polish_screen.dart';
import '../screens/retail_screen.dart';
import '../screens/salon_screen.dart';
import '../screens/scheduler_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/staff_screen.dart';
import '../screens/template_builder_screen.dart';
import '../screens/theme_profiles_screen.dart';
import '../screens/trades_screen.dart';
import '../screens/typography_screen.dart';
import '../screens/uswds_screen.dart';
import '../screens/workflow_designer_screen.dart';

/// All 33 zero-knob static stories — one per non-interactive catalog screen.
///
/// Consumed by `registerAllStories()` in 38-05's central registry assembly.
final List<EdenStory> staticStories = [
  // 1. Colors
  EdenStory(
    id: 'colors/colors',
    component: 'colors',
    name: 'Colors',
    icon: Icons.palette_outlined,
    knobs: const [],
    build: (context, _) => const ColorsScreen(),
  ),

  // 2. Typography
  EdenStory(
    id: 'typography/typography',
    component: 'typography',
    name: 'Typography',
    icon: Icons.text_fields,
    knobs: const [],
    build: (context, _) => const TypographyScreen(),
  ),

  // 3. Avatars
  EdenStory(
    id: 'avatars/avatars',
    component: 'avatars',
    name: 'Avatars',
    icon: Icons.account_circle_outlined,
    knobs: const [],
    build: (context, _) => const AvatarsScreen(),
  ),

  // 4. Misc
  EdenStory(
    id: 'misc/misc',
    component: 'misc',
    name: 'Misc',
    icon: Icons.widgets_outlined,
    knobs: const [],
    build: (context, _) => MiscScreen(),
  ),

  // 5. Data Display
  EdenStory(
    id: 'data-display/data-display',
    component: 'data-display',
    name: 'Data Display',
    icon: Icons.bar_chart,
    knobs: const [],
    build: (context, _) => DataDisplayScreen(),
  ),

  // 6. Settings Pattern
  EdenStory(
    id: 'settings/settings',
    component: 'settings',
    name: 'Settings Pattern',
    icon: Icons.settings_outlined,
    knobs: const [],
    build: (context, _) => SettingsScreen(),
  ),

  // 7. Chat
  EdenStory(
    id: 'chat/chat',
    component: 'chat',
    name: 'Chat',
    icon: Icons.chat_outlined,
    knobs: const [],
    build: (context, _) => ChatScreen(),
  ),

  // 8. Compound
  EdenStory(
    id: 'compound/compound',
    component: 'compound',
    name: 'Compound',
    icon: Icons.dashboard_outlined,
    knobs: const [],
    build: (context, _) => CompoundScreen(),
  ),

  // 9. Diagram / Flow
  EdenStory(
    id: 'diagram/diagram',
    component: 'diagram',
    name: 'Diagram / Flow',
    icon: Icons.account_tree_outlined,
    knobs: const [],
    build: (context, _) => DiagramScreen(),
  ),

  // 10. Process Builder
  EdenStory(
    id: 'process-builder/process-builder',
    component: 'process-builder',
    name: 'Process Builder',
    icon: Icons.schema_outlined,
    knobs: const [],
    build: (context, _) => ProcessBuilderScreen(),
  ),

  // 11. Workflow Designer
  EdenStory(
    id: 'workflow-designer/workflow-designer',
    component: 'workflow-designer',
    name: 'Workflow Designer',
    icon: Icons.account_tree,
    knobs: const [],
    build: (context, _) => WorkflowDesignerScreen(),
  ),

  // 12. Template Builder
  EdenStory(
    id: 'template-builder/template-builder',
    component: 'template-builder',
    name: 'Template Builder',
    icon: Icons.article_outlined,
    knobs: const [],
    build: (context, _) => TemplateBuilderScreen(),
  ),

  // 13. Layouts
  EdenStory(
    id: 'layouts/layouts',
    component: 'layouts',
    name: 'Layouts',
    icon: Icons.view_sidebar_outlined,
    knobs: const [],
    build: (context, _) => LayoutsScreen(),
  ),

  // 14. DevFlow — Infrastructure
  EdenStory(
    id: 'devflow-infra/devflow-infra',
    component: 'devflow-infra',
    name: 'DevFlow — Infrastructure',
    icon: Icons.dns_outlined,
    knobs: const [],
    build: (context, _) => const DevflowInfraScreen(),
  ),

  // 15. DevFlow — Projects & Workflow
  EdenStory(
    id: 'devflow-project/devflow-project',
    component: 'devflow-project',
    name: 'DevFlow — Projects & Workflow',
    icon: Icons.rocket_launch_outlined,
    knobs: const [],
    build: (context, _) => DevflowProjectScreen(),
  ),

  // 16. DevFlow — Tools & Config
  EdenStory(
    id: 'devflow-tools/devflow-tools',
    component: 'devflow-tools',
    name: 'DevFlow — Tools & Config',
    icon: Icons.build_outlined,
    knobs: const [],
    build: (context, _) => DevflowToolsScreen(),
  ),

  // 17. Trades — Enterprise Components
  EdenStory(
    id: 'trades/trades',
    component: 'trades',
    name: 'Trades — Enterprise Components',
    icon: Icons.construction_outlined,
    knobs: const [],
    build: (context, _) => TradesScreen(),
  ),

  // 18. Companion Shell
  EdenStory(
    id: 'companion/companion',
    component: 'companion',
    name: 'Companion Shell',
    icon: Icons.phone_iphone,
    knobs: const [],
    build: (context, _) => CompanionScreen(),
  ),

  // 19. Composers — Obj 008 W3
  EdenStory(
    id: 'composers/composers',
    component: 'composers',
    name: 'Composers — Obj 008 W3',
    icon: Icons.account_tree_outlined,
    knobs: const [],
    build: (context, _) => const ComposersScreen(),
  ),

  // 20. EdenScheduler — Objective 004
  EdenStory(
    id: 'scheduler/scheduler',
    component: 'scheduler',
    name: 'EdenScheduler — Objective 004',
    icon: Icons.calendar_view_week_outlined,
    knobs: const [],
    build: (context, _) => SchedulerScreen(),
  ),

  // 21. Field / Companion Pages — Obj 007
  EdenStory(
    id: 'field/field',
    component: 'field',
    name: 'Field / Companion Pages — Obj 007',
    icon: Icons.engineering_outlined,
    knobs: const [],
    build: (context, _) => const FieldScreen(),
  ),

  // 22. B-Fuel — Vertical Components
  EdenStory(
    id: 'fuel/fuel',
    component: 'fuel',
    name: 'B-Fuel — Vertical Components',
    icon: Icons.local_gas_station_outlined,
    knobs: const [],
    build: (context, _) => FuelScreen(),
  ),

  // 23. B-Medical — Clinical Components
  EdenStory(
    id: 'medical/medical',
    component: 'medical',
    name: 'B-Medical — Clinical Components',
    icon: Icons.monitor_heart_outlined,
    knobs: const [],
    build: (context, _) => const MedicalScreen(),
  ),

  // 24. B-Retail — Back-Office + POS
  EdenStory(
    id: 'retail/retail',
    component: 'retail',
    name: 'B-Retail — Back-Office + POS',
    icon: Icons.point_of_sale_outlined,
    knobs: const [],
    build: (context, _) => RetailScreen(),
  ),

  // 25. B-Retail — Customer & Service Flows
  EdenStory(
    id: 'retail-polish/retail-polish',
    component: 'retail-polish',
    name: 'B-Retail — Customer & Service Flows',
    icon: Icons.loyalty_outlined,
    knobs: const [],
    build: (context, _) => const RetailPolishScreen(),
  ),

  // 26. B-Salon — Salon-Specific Commerce
  EdenStory(
    id: 'salon/salon',
    component: 'salon',
    name: 'B-Salon — Salon-Specific Commerce',
    icon: Icons.spa_outlined,
    knobs: const [],
    build: (context, _) => SalonScreen(),
  ),

  // 27. Staff — Obj 015
  EdenStory(
    id: 'staff/staff',
    component: 'staff',
    name: 'Staff — Obj 015',
    icon: Icons.badge_outlined,
    knobs: const [],
    build: (context, _) => StaffScreen(),
  ),

  // 28. End of Day — Obj 015
  EdenStory(
    id: 'eod/eod',
    component: 'eod',
    name: 'End of Day — Obj 015',
    icon: Icons.point_of_sale,
    knobs: const [],
    build: (context, _) => EodScreen(),
  ),

  // 29. Compliance Overlay
  EdenStory(
    id: 'compliance/compliance',
    component: 'compliance',
    name: 'Compliance Overlay',
    icon: Icons.shield_outlined,
    knobs: const [],
    build: (context, _) => const ComplianceScreen(),
  ),

  // 30. Commerce Primitives
  EdenStory(
    id: 'commerce/commerce',
    component: 'commerce',
    name: 'Commerce Primitives',
    icon: Icons.point_of_sale_outlined,
    knobs: const [],
    build: (context, _) => CommerceScreen(),
  ),

  // 31. USWDS Conformance
  EdenStory(
    id: 'uswds/uswds',
    component: 'uswds',
    name: 'USWDS Conformance',
    icon: Icons.account_balance_outlined,
    knobs: const [],
    build: (context, _) => const UswdsScreen(),
  ),

  // 32. Motion (Obj 010)
  EdenStory(
    id: 'motion/motion',
    component: 'motion',
    name: 'Motion (Obj 010)',
    icon: Icons.animation,
    knobs: const [],
    build: (context, _) => const MotionScreen(),
  ),

  // 33. Theme Profiles — Objective 009
  EdenStory(
    id: 'theme-profiles/theme-profiles',
    component: 'theme-profiles',
    name: 'Theme Profiles — Objective 009',
    icon: Icons.color_lens_outlined,
    knobs: const [],
    build: (context, _) => const ThemeProfilesScreen(),
  ),
];
