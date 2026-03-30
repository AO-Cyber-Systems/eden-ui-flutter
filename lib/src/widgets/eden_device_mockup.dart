import 'package:flutter/material.dart';

/// Device type for [EdenDeviceMockup].
enum EdenDeviceType { phone, tablet }

/// A phone or tablet frame wrapper for displaying app screenshots or previews.
///
/// Renders a device-shaped border around the [child] content.
class EdenDeviceMockup extends StatelessWidget {
  const EdenDeviceMockup({
    super.key,
    required this.child,
    this.deviceType = EdenDeviceType.phone,
    this.width,
    this.frameColor,
    this.statusBarColor,
    this.showStatusBar = true,
    this.showHomeIndicator = true,
  });

  /// The content to display inside the device frame.
  final Widget child;

  /// The device type (phone or tablet).
  final EdenDeviceType deviceType;

  /// Custom width. Defaults based on device type.
  final double? width;

  /// Frame border color. Defaults to a dark neutral.
  final Color? frameColor;

  /// Status bar background color.
  final Color? statusBarColor;

  /// Whether to show a simulated status bar at the top.
  final bool showStatusBar;

  /// Whether to show a home indicator bar at the bottom.
  final bool showHomeIndicator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final deviceWidth = width ?? (deviceType == EdenDeviceType.phone ? 280.0 : 480.0);
    final aspectRatio = deviceType == EdenDeviceType.phone ? 9.0 / 19.5 : 3.0 / 4.0;
    final borderWidth = deviceType == EdenDeviceType.phone ? 8.0 : 10.0;
    final borderRadiusValue = deviceType == EdenDeviceType.phone ? 32.0 : 24.0;
    final innerRadiusValue = borderRadiusValue - borderWidth;

    final frame = frameColor ?? (isDark ? Colors.grey.shade800 : Colors.grey.shade900);

    return SizedBox(
      width: deviceWidth,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: frame,
            borderRadius: BorderRadius.circular(borderRadiusValue),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(borderWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(innerRadiusValue),
              child: Column(
                children: [
                  // Status bar
                  if (showStatusBar)
                    Container(
                      width: double.infinity,
                      height: deviceType == EdenDeviceType.phone ? 44 : 24,
                      color: statusBarColor ?? (isDark ? Colors.black : Colors.white),
                      child: deviceType == EdenDeviceType.phone
                          ? Center(
                              child: Container(
                                width: 80,
                                height: 24,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: frame,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  // Content
                  Expanded(
                    child: Container(
                      color: isDark ? Colors.black : Colors.white,
                      child: child,
                    ),
                  ),
                  // Home indicator
                  if (showHomeIndicator)
                    Container(
                      width: double.infinity,
                      height: 20,
                      color: isDark ? Colors.black : Colors.white,
                      child: Center(
                        child: Container(
                          width: deviceType == EdenDeviceType.phone ? 120 : 160,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
