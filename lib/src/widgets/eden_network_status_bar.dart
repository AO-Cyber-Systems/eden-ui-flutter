import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Network connectivity state — passed in by the host app.
///
/// Library is transport-agnostic: it does NOT subscribe to `connectivity_plus`,
/// `navigator.onLine`, or any platform connectivity signal. Downstream apps
/// own connectivity detection and pipe the state into this widget.
enum EdenNetworkStatus { online, offline, reconnecting, syncing }

/// Top-of-app slim banner indicating connectivity state.
///
/// Renders nothing for [EdenNetworkStatus.online] (zero chrome cost when
/// connection is fine). Other states render a slim, animated banner via
/// [SlideTransition].
class EdenNetworkStatusBar extends StatelessWidget {
  const EdenNetworkStatusBar({
    super.key,
    required this.status,
    this.attemptCount,
    this.retryButton = false,
    this.onRetry,
    this.height = 32.0,
  });

  final EdenNetworkStatus status;
  final int? attemptCount;
  final bool retryButton;
  final VoidCallback? onRetry;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
      child: _buildBanner(context),
    );
  }

  Widget _buildBanner(BuildContext context) {
    if (status == EdenNetworkStatus.online) {
      return const SizedBox.shrink(key: ValueKey('online'));
    }

    final Color bg;
    final Color fg;
    final IconData? icon;
    final Widget? leadingWidget;
    final String text;

    switch (status) {
      case EdenNetworkStatus.offline:
        bg = EdenColors.errorBg;
        fg = EdenColors.error;
        icon = Icons.wifi_off;
        leadingWidget = null;
        text = 'No internet connection';
        break;
      case EdenNetworkStatus.reconnecting:
        bg = EdenColors.warningBg;
        fg = EdenColors.warning;
        icon = null;
        leadingWidget = SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: fg),
        );
        text = attemptCount != null
            ? 'Reconnecting (attempt $attemptCount)...'
            : 'Reconnecting...';
        break;
      case EdenNetworkStatus.syncing:
        bg = EdenColors.infoBg;
        fg = EdenColors.info;
        icon = Icons.sync;
        leadingWidget = null;
        text = 'Syncing changes...';
        break;
      case EdenNetworkStatus.online:
        // Handled above.
        return const SizedBox.shrink(key: ValueKey('online'));
    }

    return Container(
      key: ValueKey(status.name),
      height: height,
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space3),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, size: 16, color: fg)
          else if (leadingWidget != null)
            leadingWidget,
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (retryButton && status == EdenNetworkStatus.offline) ...[
            const SizedBox(width: EdenSpacing.space2),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: fg,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
