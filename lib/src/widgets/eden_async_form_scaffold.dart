import 'package:flutter/material.dart';

import 'eden_button.dart';
import 'eden_spinner.dart';

/// Async snapshot states accepted by [EdenAsyncFormScaffold].
///
/// Mirrors a subset of the Riverpod `AsyncValue<T>` shape without taking a
/// dependency on `flutter_riverpod`. Callers using Riverpod can build one of
/// these via `edenSnapshotFromAsyncValue` (defined in
/// `eden_platform_flutter`).
sealed class EdenAsyncSnapshot<T> {
  const EdenAsyncSnapshot();

  /// Hydrated, has data.
  const factory EdenAsyncSnapshot.data(T data) = EdenAsyncData<T>;

  /// In-flight, no data yet.
  const factory EdenAsyncSnapshot.loading() = EdenAsyncLoading<T>;

  /// Failed; carries the error and (optional) stack trace.
  const factory EdenAsyncSnapshot.error(Object error, [StackTrace? st]) =
      EdenAsyncError<T>;

  /// Reduce-style helper.
  R when<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(Object error, StackTrace? stack) error,
  });

  /// Returns the data if hydrated; null otherwise.
  T? get value;
}

class EdenAsyncData<T> extends EdenAsyncSnapshot<T> {
  const EdenAsyncData(this.data);
  final T data;
  @override
  T? get value => data;
  @override
  R when<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(Object error, StackTrace? stack) error,
  }) =>
      data(this.data);
}

class EdenAsyncLoading<T> extends EdenAsyncSnapshot<T> {
  const EdenAsyncLoading();
  @override
  T? get value => null;
  @override
  R when<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(Object error, StackTrace? stack) error,
  }) =>
      loading();
}

class EdenAsyncError<T> extends EdenAsyncSnapshot<T> {
  const EdenAsyncError(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
  @override
  T? get value => null;
  @override
  R when<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(Object error, StackTrace? stack) error,
  }) =>
      error(this.error, stackTrace);
}

/// Scaffold for edit forms whose initial state must be hydrated from an
/// asynchronously-loaded resource.
///
/// ## Why this exists
///
/// Every edit form in a typical app fetches its resource via an async
/// provider. Historically each form re-invented the same pattern (a
/// `_initialized` flag, a `populateFromX` method, ad-hoc loading UI) and
/// each got it subtly wrong in a different way — blank controllers,
/// missing loading state, state mutated during build, etc. The bugs
/// manifested the same way: the edit form opens with blank fields and
/// "saves" a PATCH that nulls every unchanged column.
///
/// `EdenAsyncFormScaffold` pins down one correct pattern:
///
/// 1. Wait for data. While loading, show a spinner; on error, show an
///    error card with a retry button.
/// 2. When data arrives for the first time, invoke [onHydrate] exactly
///    once. This callback seeds `TextEditingController`s and any local
///    form state (sliders, toggles, dropdowns) from the fetched entity.
/// 3. Build the form body via [builder] with the hydrated entity in hand.
///
/// [onHydrate] is invoked in a `WidgetsBinding.instance.addPostFrameCallback`
/// so callers may safely call `setState` from it — writing to controllers
/// would be fine during build, but sliders/switches need a rebuild to
/// pick up new local field values.
///
/// ## Usage with Riverpod
///
/// ```dart
/// // From eden_platform_flutter:
/// // import 'package:eden_platform_flutter/eden_platform.dart' show edenSnapshotFromAsyncValue;
///
/// class _MyFormState extends ConsumerState<MyForm> {
///   final _nameCtrl = TextEditingController();
///   bool _flag = false;
///
///   @override
///   Widget build(BuildContext context) {
///     final async = ref.watch(myDetailProvider(widget.id));
///     return EdenAsyncFormScaffold<MyEntity>(
///       value: edenSnapshotFromAsyncValue(async),
///       onRetry: () => ref.invalidate(myDetailProvider(widget.id)),
///       onHydrate: (entity) => setState(() {
///         _nameCtrl.text = entity.name;
///         _flag = entity.flag;
///       }),
///       builder: (context, entity) => _buildForm(),
///     );
///   }
/// }
/// ```
///
/// For **create** (new entity) mode, bypass this widget entirely and just
/// render the form — this scaffold is strictly for **edit** mode.
class EdenAsyncFormScaffold<T> extends StatefulWidget {
  const EdenAsyncFormScaffold({
    super.key,
    required this.value,
    required this.builder,
    required this.onHydrate,
    this.onRetry,
    this.errorMessage = 'Failed to load',
    this.retryLabel = 'Retry',
  });

  /// The asynchronously-loaded resource to hydrate the form from.
  final EdenAsyncSnapshot<T> value;

  /// Invoked exactly once — on the first successful data arrival — to seed
  /// form state (controllers, sliders, toggles) from the entity.
  ///
  /// Safe to call `setState` from here; the callback runs in a post-frame
  /// callback, outside the build phase.
  final void Function(T data) onHydrate;

  /// Builds the form body after hydration. Invoked on every rebuild once
  /// data has arrived (including during refresh cycles).
  final Widget Function(BuildContext context, T data) builder;

  /// Optional retry hook shown on the error card. Typically
  /// `() => ref.invalidate(someProvider)`.
  final VoidCallback? onRetry;

  /// Headline shown on the error card.
  final String errorMessage;

  /// Label on the retry button.
  final String retryLabel;

  @override
  State<EdenAsyncFormScaffold<T>> createState() =>
      _EdenAsyncFormScaffoldState<T>();
}

class _EdenAsyncFormScaffoldState<T> extends State<EdenAsyncFormScaffold<T>> {
  bool _hydrated = false;

  void _maybeHydrate(T data) {
    if (_hydrated) return;
    _hydrated = true;
    // Defer to post-frame so [onHydrate] can call setState on the parent
    // without "setState called during build" assertions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onHydrate(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.value.when(
      loading: () => const Center(child: EdenSpinner()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.errorMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 16),
                EdenButton(
                  label: widget.retryLabel,
                  onPressed: widget.onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
      data: (data) {
        _maybeHydrate(data);
        return widget.builder(context, data);
      },
    );
  }
}
