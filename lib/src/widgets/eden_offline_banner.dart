import 'package:flutter/material.dart';

/// A banner that appears when the device is offline.
///
/// Framework-agnostic — takes [isOffline] as a plain bool. The consumer
/// is responsible for providing connectivity state (e.g., from Riverpod,
/// Provider, or any other state management).
///
/// ```dart
/// // With Riverpod:
/// final isOffline = ref.watch(connectivityProvider).valueOrNull == false;
/// EdenOfflineBanner(isOffline: isOffline)
///
/// // Standalone:
/// EdenOfflineBanner(isOffline: true)
/// ```
class EdenOfflineBanner extends StatelessWidget {
  const EdenOfflineBanner({
    super.key,
    required this.isOffline,
    this.message = 'You are offline. Some features may be unavailable.',
  });

  final bool isOffline;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: theme.colorScheme.errorContainer,
      leading: Icon(
        Icons.wifi_off,
        color: theme.colorScheme.onErrorContainer,
      ),
      content: Text(
        message,
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
      ),
      actions: const [SizedBox.shrink()],
    );
  }
}

/// Compact offline indicator for AppBar or header placement.
///
/// Shows a small "Offline" chip when [isOffline] is true.
///
/// ```dart
/// EdenOfflineIndicator(isOffline: !isConnected)
/// ```
class EdenOfflineIndicator extends StatelessWidget {
  const EdenOfflineIndicator({
    super.key,
    required this.isOffline,
    this.label = 'Offline',
  });

  final bool isOffline;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Tooltip(
      message: 'No network connection',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              size: 14,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
