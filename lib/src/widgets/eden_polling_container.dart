import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// A container that automatically refreshes its child widget at a specified
/// interval.
///
/// Shows an optional "last updated" indicator and provides manual refresh
/// and pause/resume controls.
class EdenPollingContainer extends StatefulWidget {
  /// Creates a polling container.
  const EdenPollingContainer({
    super.key,
    required this.child,
    required this.interval,
    required this.onRefresh,
    this.enabled = true,
    this.showLastUpdated = true,
  });

  /// The child widget to wrap.
  final Widget child;

  /// How often to refresh.
  final Duration interval;

  /// The async callback invoked on each refresh cycle.
  final Future<void> Function() onRefresh;

  /// Whether automatic polling is enabled.
  final bool enabled;

  /// Whether to show the last-updated header row.
  final bool showLastUpdated;

  @override
  State<EdenPollingContainer> createState() => _EdenPollingContainerState();
}

class _EdenPollingContainerState extends State<EdenPollingContainer> {
  DateTime? _lastUpdated;
  bool _refreshing = false;
  Timer? _timer;
  late bool _paused;

  @override
  void initState() {
    super.initState();
    _paused = !widget.enabled;
    _startTimer();
  }

  @override
  void didUpdateWidget(EdenPollingContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval ||
        oldWidget.enabled != widget.enabled) {
      _stopTimer();
      _paused = !widget.enabled;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    if (_paused) return;
    _timer = Timer.periodic(widget.interval, (_) => _doRefresh());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _doRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh();
      if (mounted) {
        setState(() {
          _lastUpdated = DateTime.now();
          _refreshing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _stopTimer();
      } else {
        _startTimer();
      }
    });
  }

  String _formatLastUpdated() {
    if (_lastUpdated == null) return 'Not yet updated';
    final diff = DateTime.now().difference(_lastUpdated!);
    if (diff.inSeconds < 5) return 'Updated just now';
    if (diff.inSeconds < 60) return 'Updated ${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    return 'Updated ${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_refreshing)
          LinearProgressIndicator(
            minHeight: 2,
            color: theme.colorScheme.primary,
            backgroundColor: isDark
                ? EdenColors.neutral[800]
                : EdenColors.neutral[100],
          ),
        if (widget.showLastUpdated)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space3,
              vertical: EdenSpacing.space1,
            ),
            child: Row(
              children: [
                Text(
                  _refreshing ? 'Updating...' : _formatLastUpdated(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: EdenColors.neutral[500],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshing ? null : _doRefresh,
                    tooltip: 'Refresh now',
                  ),
                ),
                const SizedBox(width: EdenSpacing.space1),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                    onPressed: _togglePause,
                    tooltip: _paused ? 'Resume polling' : 'Pause polling',
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
