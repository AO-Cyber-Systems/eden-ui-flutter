import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/spacing.dart';
import 'eden_banner.dart';
import 'eden_button.dart';
import 'eden_card.dart';
import 'eden_otp_input.dart';

/// Lifecycle states of [EdenTimeClock].
enum EdenTimeClockState {
  idle,
  authenticating,
  clockedIn,
  onBreak,
  error,
}

/// Actions emitted by [EdenTimeClock].
enum EdenTimeClockAction { clockIn, clockOut, breakStart, breakEnd }

/// Event payload emitted on every clock action.
@immutable
class EdenTimeClockEvent {
  const EdenTimeClockEvent({
    required this.action,
    required this.staffId,
    required this.occurredAt,
  });

  final EdenTimeClockAction action;
  final String staffId;
  final DateTime occurredAt;
}

/// Active session info passed in from the parent.
@immutable
class EdenTimeClockSession {
  const EdenTimeClockSession({
    required this.staffId,
    required this.clockInAt,
    this.lastBreakStartAt,
    this.lastBreakEndAt,
    this.breaksAccumulated = Duration.zero,
    this.isOnBreak = false,
  });

  final String staffId;
  final DateTime clockInAt;
  final DateTime? lastBreakStartAt;
  final DateTime? lastBreakEndAt;
  final Duration breaksAccumulated;
  final bool isOnBreak;

  EdenTimeClockSession copyWith({
    String? staffId,
    DateTime? clockInAt,
    DateTime? lastBreakStartAt,
    DateTime? lastBreakEndAt,
    Duration? breaksAccumulated,
    bool? isOnBreak,
  }) {
    return EdenTimeClockSession(
      staffId: staffId ?? this.staffId,
      clockInAt: clockInAt ?? this.clockInAt,
      lastBreakStartAt: lastBreakStartAt ?? this.lastBreakStartAt,
      lastBreakEndAt: lastBreakEndAt ?? this.lastBreakEndAt,
      breaksAccumulated: breaksAccumulated ?? this.breaksAccumulated,
      isOnBreak: isOnBreak ?? this.isOnBreak,
    );
  }
}

/// PIN-gated kiosk time clock (obj 015-05).
///
/// Idle → PIN entry → onResolveStaff async → clockedIn / error.
/// Live elapsed-time updates every 30s via Timer.periodic.
class EdenTimeClock extends StatefulWidget {
  const EdenTimeClock({
    super.key,
    required this.onResolveStaff,
    required this.onAction,
    this.activeSession,
    this.pinLength = 4,
    this.allowBreaks = true,
    this.kioskTitle = 'Time clock',
  });

  final FutureOr<String?> Function(String pin) onResolveStaff;
  final ValueChanged<EdenTimeClockEvent> onAction;
  final EdenTimeClockSession? activeSession;
  final int pinLength;
  final bool allowBreaks;
  final String? kioskTitle;

  @override
  State<EdenTimeClock> createState() => _EdenTimeClockState();
}

class _EdenTimeClockState extends State<EdenTimeClock> {
  Timer? _ticker;
  bool _authenticating = false;
  bool _showInvalidPin = false;
  int _otpResetSeed = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _handlePinSubmit(String pin) async {
    if (pin.length < widget.pinLength) return;
    setState(() {
      _authenticating = true;
      _showInvalidPin = false;
    });
    final staffId = await widget.onResolveStaff(pin);
    if (!mounted) return;
    if (staffId == null) {
      setState(() {
        _authenticating = false;
        _showInvalidPin = true;
        _otpResetSeed++;
      });
      return;
    }
    setState(() {
      _authenticating = false;
    });
    widget.onAction(EdenTimeClockEvent(
      action: EdenTimeClockAction.clockIn,
      staffId: staffId,
      occurredAt: DateTime.now(),
    ));
  }

  void _emitClockOut(EdenTimeClockSession session) {
    widget.onAction(EdenTimeClockEvent(
      action: EdenTimeClockAction.clockOut,
      staffId: session.staffId,
      occurredAt: DateTime.now(),
    ));
  }

  void _emitBreakStart(EdenTimeClockSession session) {
    widget.onAction(EdenTimeClockEvent(
      action: EdenTimeClockAction.breakStart,
      staffId: session.staffId,
      occurredAt: DateTime.now(),
    ));
  }

  void _emitBreakEnd(EdenTimeClockSession session) {
    widget.onAction(EdenTimeClockEvent(
      action: EdenTimeClockAction.breakEnd,
      staffId: session.staffId,
      occurredAt: DateTime.now(),
    ));
  }

  Duration _elapsed(DateTime since) {
    return DateTime.now().difference(since);
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  Color _stateBg(BuildContext context, EdenTimeClockState s) {
    final palette = Theme.of(context).extension<EdenStatusPalette>() ??
        EdenStatusPalette.commercial();
    switch (s) {
      case EdenTimeClockState.clockedIn:
        return palette.successBg;
      case EdenTimeClockState.onBreak:
        return palette.warningBg;
      case EdenTimeClockState.error:
        return palette.dangerBg;
      case EdenTimeClockState.idle:
      case EdenTimeClockState.authenticating:
        return Theme.of(context).colorScheme.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.activeSession;
    if (session == null) {
      return _buildIdle();
    }
    if (session.isOnBreak) {
      return _buildOnBreak(session);
    }
    return _buildClockedIn(session);
  }

  Widget _buildIdle() {
    final theme = Theme.of(context);
    return Card(
      color: _stateBg(context, EdenTimeClockState.idle),
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.kioskTitle != null)
              Text(widget.kioskTitle!, style: theme.textTheme.titleLarge),
            const SizedBox(height: EdenSpacing.space2),
            Text('Enter PIN', style: theme.textTheme.titleMedium),
            const SizedBox(height: EdenSpacing.space3),
            Semantics(
              label: 'PIN entry, ${widget.pinLength} digits',
              container: true,
              child: EdenOtpInput(
                key: ValueKey('pin-$_otpResetSeed'),
                length: widget.pinLength,
                onSubmit: _handlePinSubmit,
              ),
            ),
            if (_authenticating) ...[
              const SizedBox(height: EdenSpacing.space3),
              const CircularProgressIndicator(),
            ],
            if (_showInvalidPin) ...[
              const SizedBox(height: EdenSpacing.space3),
              const EdenBanner(
                message: 'Invalid PIN',
                variant: EdenBannerVariant.danger,
                dismissible: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClockedIn(EdenTimeClockSession session) {
    final theme = Theme.of(context);
    final elapsed =
        _elapsed(session.clockInAt) - session.breaksAccumulated;
    final elapsedLabel = _formatElapsed(elapsed);
    return EdenCard(
      child: Container(
        color: _stateBg(context, EdenTimeClockState.clockedIn),
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clocked in', style: theme.textTheme.titleMedium),
            const SizedBox(height: EdenSpacing.space1),
            Text(session.staffId,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: EdenSpacing.space2),
            Text('Elapsed: $elapsedLabel',
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: EdenSpacing.space3),
            Wrap(
              spacing: EdenSpacing.space2,
              runSpacing: EdenSpacing.space2,
              children: [
                Semantics(
                  label: 'Clock out of shift, $elapsedLabel elapsed',
                  container: true,
                  excludeSemantics: true,
                  child: EdenButton(
                    label: 'Clock out',
                    variant: EdenButtonVariant.danger,
                    onPressed: () => _emitClockOut(session),
                  ),
                ),
                if (widget.allowBreaks)
                  EdenButton(
                    label: 'Take break',
                    variant: EdenButtonVariant.secondary,
                    outline: true,
                    onPressed: () => _emitBreakStart(session),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnBreak(EdenTimeClockSession session) {
    final theme = Theme.of(context);
    final breakStart =
        session.lastBreakStartAt ?? DateTime.now();
    final breakElapsed = _elapsed(breakStart);
    final breakLabel = _formatElapsed(breakElapsed);
    return EdenCard(
      child: Container(
        color: _stateBg(context, EdenTimeClockState.onBreak),
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('On break', style: theme.textTheme.titleMedium),
            const SizedBox(height: EdenSpacing.space1),
            Text(session.staffId,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: EdenSpacing.space2),
            Text('Break elapsed: $breakLabel',
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: EdenSpacing.space3),
            EdenButton(
              label: 'Resume work',
              variant: EdenButtonVariant.primary,
              onPressed: () => _emitBreakEnd(session),
            ),
          ],
        ),
      ),
    );
  }
}
