import 'package:flutter/material.dart';

/// Layout modes for responsive design.
enum EdenLayoutMode { mobile, tablet, desktop, wide }

/// Breakpoint layout utilities.
class EdenResponsive {
  EdenResponsive._();

  // Breakpoints
  static const double mobileMax = 768;
  static const double tabletMax = 1024;
  static const double desktopMax = 1280;

  // Common component sizes
  static const double sidebarExpanded = 260;
  static const double sidebarCollapsed = 72;
  static const double contentMaxWidth = 1200;
  static const double panelWidth = 400;

  /// Get current layout mode from context.
  static EdenLayoutMode layoutMode(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileMax) return EdenLayoutMode.mobile;
    if (width < tabletMax) return EdenLayoutMode.tablet;
    if (width < desktopMax) return EdenLayoutMode.desktop;
    return EdenLayoutMode.wide;
  }

  static bool isMobile(BuildContext context) =>
      layoutMode(context) == EdenLayoutMode.mobile;

  static bool isTablet(BuildContext context) =>
      layoutMode(context) == EdenLayoutMode.tablet;

  static bool isDesktop(BuildContext context) =>
      layoutMode(context) == EdenLayoutMode.desktop ||
      layoutMode(context) == EdenLayoutMode.wide;

  static bool isTabletOrWider(BuildContext context) => !isMobile(context);
}

/// Responsive builder widget that rebuilds based on layout mode.
class EdenResponsiveBuilder extends StatelessWidget {
  const EdenResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, EdenLayoutMode mode) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = EdenResponsive.layoutMode(context);
        return builder(context, mode);
      },
    );
  }
}
