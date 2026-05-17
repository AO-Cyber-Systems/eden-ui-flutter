import 'package:flutter/material.dart';

import 'eden_secret_field.dart';

/// State machine for [EdenCacPivButton] / [EdenCacPivController].
enum EdenCacPivState {
  idle,
  reading,
  promptPin,
  authenticating,
  error,
}

/// Controller for [EdenCacPivButton]. Drives the 5-state authentication
/// flow via [transitionTo] and exposes current [state] + [errorMessage].
///
/// Lifecycle: extends [ChangeNotifier]. The widget [addListener]s in
/// `initState` and `removeListener`s in `dispose`. Consumer is
/// responsible for `dispose()`ing the controller when it owns the
/// instance.
class EdenCacPivController extends ChangeNotifier {
  EdenCacPivState _state = EdenCacPivState.idle;
  String? _errorMessage;

  EdenCacPivState get state => _state;
  String? get errorMessage => _errorMessage;

  /// Transition to a new state. Optional [errorMessage] applies when
  /// transitioning into [EdenCacPivState.error]; otherwise cleared.
  void transitionTo(EdenCacPivState s, {String? errorMessage}) {
    _state = s;
    _errorMessage = errorMessage;
    notifyListeners();
  }

  /// Reset back to [EdenCacPivState.idle] with no error message.
  void reset() {
    _state = EdenCacPivState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}

/// Smartcard authentication affordance — CAC (Common Access Card / DOD)
/// or PIV (Personal Identity Verification / federal civilian).
///
/// Renders a 5-state UI cycling through:
///   1. `idle` — 'Insert your CAC/PIV card' button.
///   2. `reading` — spinner + 'Reading card…'.
///   3. `promptPin` — [EdenSecretField] for PIN + Submit button.
///   4. `authenticating` — spinner + 'Verifying credentials…'.
///   5. `error` — error icon + message + 'Try again' button.
///
/// **Library scope: interface-only.** This widget renders the UI + state
/// machine + collects PIN input. The consumer app wires native
/// platform-channel calls to the smartcard reader (iOS/Android/macOS)
/// and drives state transitions via [EdenCacPivController]. The library
/// has no smartcard / platform-channel package dependencies.
///
/// Consumer flow:
///   1. User taps button in `idle` → [onInsertRequested] fires.
///   2. Consumer calls native smartcard reader → calls
///      `controller.transitionTo(reading)`, then `(promptPin)`.
///   3. User enters PIN → [onPinSubmitted] fires with PIN string;
///      internal PIN field clears.
///   4. Consumer verifies PIN → calls `controller.transitionTo(...)`
///      to indicate success (e.g., `reset()`) or
///      `(error, errorMessage: ...)`.
///   5. From error, user taps 'Try again' → [onRetry] fires AND the
///      controller resets to `idle`.
///
/// Civilian re-use: although named for CAC/PIV federal contexts, the
/// pattern works for any smartcard/hardware-credential flow (e.g.,
/// commercial PKI tokens, healthcare provider smartcards).
class EdenCacPivButton extends StatefulWidget {
  const EdenCacPivButton({
    super.key,
    required this.controller,
    this.onInsertRequested,
    this.onPinSubmitted,
    this.onRetry,
  });

  final EdenCacPivController controller;

  /// Fires when the user taps the 'Insert card' button from idle.
  final VoidCallback? onInsertRequested;

  /// Fires when the user taps 'Submit PIN' with the entered PIN string.
  /// The internal PIN field clears immediately after this fires.
  final ValueChanged<String>? onPinSubmitted;

  /// Fires when the user taps 'Try again' from the error state. The
  /// widget ALSO calls `controller.reset()` after this fires.
  final VoidCallback? onRetry;

  @override
  State<EdenCacPivButton> createState() => _EdenCacPivButtonState();
}

class _EdenCacPivButtonState extends State<EdenCacPivButton> {
  String _pin = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(covariant EdenCacPivButton old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _submitPin() {
    final pin = _pin;
    setState(() => _pin = '');
    widget.onPinSubmitted?.call(pin);
  }

  void _retry() {
    widget.onRetry?.call();
    widget.controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final semanticLabel = 'CAC/PIV smartcard authentication, ${state.name}';
    return Semantics(
      label: semanticLabel,
      container: true,
      child: switch (state) {
        EdenCacPivState.idle => ElevatedButton.icon(
            onPressed: widget.onInsertRequested,
            icon: const Icon(Icons.credit_card),
            label: const Text('Insert your CAC/PIV card'),
          ),
        EdenCacPivState.reading => const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Reading card…'),
            ],
          ),
        EdenCacPivState.promptPin => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter PIN'),
              const SizedBox(height: 8),
              EdenSecretField(
                value: _pin,
                label: 'CAC/PIV PIN entry',
                onChanged: (v) => setState(() => _pin = v),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submitPin,
                child: const Text('Submit PIN'),
              ),
            ],
          ),
        EdenCacPivState.authenticating => const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Verifying credentials…'),
            ],
          ),
        EdenCacPivState.error => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.controller.errorMessage ??
                          'Authentication failed',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _retry,
                child: const Text('Try again'),
              ),
            ],
          ),
      },
    );
  }
}
