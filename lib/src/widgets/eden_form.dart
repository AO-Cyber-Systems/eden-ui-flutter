import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Validator function signature for Eden form fields.
typedef EdenValidator = String? Function(String? value);

/// Built-in validators for common form field validation patterns.
class EdenValidators {
  EdenValidators._();

  /// Validates that a field is not empty.
  static EdenValidator required([String? message]) => (value) =>
      (value == null || value.trim().isEmpty)
          ? (message ?? 'This field is required')
          : null;

  /// Validates that a field contains a valid email address.
  static EdenValidator email([String? message]) => (value) {
        if (value == null || value.isEmpty) return null;
        final regex = RegExp(r'^[\w\-]+(\.[\w\-]+)*@([\w\-]+\.)+[\w\-]{2,4}$');
        return regex.hasMatch(value)
            ? null
            : (message ?? 'Enter a valid email');
      };

  /// Validates minimum character length.
  static EdenValidator minLength(int min, [String? message]) => (value) =>
      (value != null && value.length < min)
          ? (message ?? 'Minimum $min characters')
          : null;

  /// Validates maximum character length.
  static EdenValidator maxLength(int max, [String? message]) => (value) =>
      (value != null && value.length > max)
          ? (message ?? 'Maximum $max characters')
          : null;

  /// Validates that a field matches a regular expression pattern.
  static EdenValidator pattern(RegExp regex, [String? message]) => (value) =>
      (value != null && value.isNotEmpty && !regex.hasMatch(value))
          ? (message ?? 'Invalid format')
          : null;

  /// Composes multiple validators into a single validator that runs sequentially.
  static EdenValidator compose(List<EdenValidator> validators) => (value) {
        for (final v in validators) {
          final error = v(value);
          if (error != null) return error;
        }
        return null;
      };

  /// Validates that a field value matches another controller's text.
  static EdenValidator match(TextEditingController other, [String? message]) =>
      (value) =>
          value != other.text ? (message ?? 'Fields do not match') : null;
}

/// Controls when auto-validation runs.
enum EdenAutovalidateMode { disabled, onBlur, onChange, onSubmit }

/// Error display mode for form fields.
enum EdenErrorDisplayMode {
  /// Show errors inline under each field.
  inline,

  /// Aggregate errors into the form-level banner only.
  banner,
}

/// A form validation framework that wraps Flutter's [Form] with eden-ui patterns.
///
/// Manages validation state, dirty tracking, and provides a form-level error
/// banner. Use [EdenForm.of] to access state from descendant widgets.
class EdenForm extends StatefulWidget {
  const EdenForm({
    super.key,
    required this.child,
    this.onSubmit,
    this.autovalidateMode = EdenAutovalidateMode.onBlur,
    this.errorDisplayMode = EdenErrorDisplayMode.inline,
    this.showErrorBanner = false,
  });

  final Widget child;
  final VoidCallback? onSubmit;
  final EdenAutovalidateMode autovalidateMode;
  final EdenErrorDisplayMode errorDisplayMode;
  final bool showErrorBanner;

  /// Retrieves the nearest [EdenFormState] ancestor.
  static EdenFormState of(BuildContext context) {
    final state = context.findAncestorStateOfType<EdenFormState>();
    assert(state != null, 'No EdenForm found in context');
    return state!;
  }

  @override
  EdenFormState createState() => EdenFormState();
}

/// State for [EdenForm], providing validation, dirty tracking, and submission.
class EdenFormState extends State<EdenForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String?> _errors = {};
  bool _isDirty = false;
  bool _isSubmitting = false;

  /// Whether any field has been modified.
  bool get isDirty => _isDirty;

  /// Whether the form is currently submitting.
  bool get isSubmitting => _isSubmitting;

  /// Whether all tracked fields have no errors.
  bool get isValid => _errors.values.every((e) => e == null);

  /// All current field errors keyed by field name.
  Map<String, String?> get errors => Map.unmodifiable(_errors);

  /// Mark the form as dirty (a field has been modified).
  void markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  /// Set or clear an error for a specific field.
  void setFieldError(String field, String? error) {
    setState(() => _errors[field] = error);
  }

  /// Remove a field from tracking (e.g. when a field is disposed).
  void unregisterField(String field) {
    _errors.remove(field);
  }

  /// Validate all fields in the form. Returns true if all pass.
  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  /// Reset all fields and clear dirty/error state.
  void reset() {
    _formKey.currentState?.reset();
    setState(() {
      _errors.clear();
      _isDirty = false;
    });
  }

  /// Validate and submit the form. Calls [EdenForm.onSubmit] only when valid.
  Future<void> submit() async {
    if (!validate()) return;
    setState(() => _isSubmitting = true);
    try {
      widget.onSubmit?.call();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeErrors =
        _errors.entries.where((e) => e.value != null).toList();

    return Form(
      key: _formKey,
      autovalidateMode: widget.autovalidateMode == EdenAutovalidateMode.onChange
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showErrorBanner && activeErrors.isNotEmpty)
            _EdenFormErrorBanner(errors: activeErrors),
          widget.child,
        ],
      ),
    );
  }
}

/// A form-level error banner that displays all current field errors.
class _EdenFormErrorBanner extends StatelessWidget {
  const _EdenFormErrorBanner({required this.errors});

  final List<MapEntry<String, String?>> errors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: EdenSpacing.space4),
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: EdenColors.errorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EdenColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: EdenColors.error),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please fix the following errors:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: EdenColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                for (final entry in errors)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '- ${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: EdenColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps any eden input widget to connect it to [EdenForm] validation.
///
/// The [builder] receives the current error text (or null) so the child
/// widget can display inline errors via its `errorText` parameter.
class EdenFormField extends StatefulWidget {
  const EdenFormField({
    super.key,
    required this.name,
    required this.builder,
    this.validators = const [],
  });

  /// Unique field name used for error tracking within the form.
  final String name;

  /// Builds the child widget, receiving the current error text.
  final Widget Function(String? errorText) builder;

  /// Validators to run against the field value.
  final List<EdenValidator> validators;

  @override
  State<EdenFormField> createState() => _EdenFormFieldState();
}

class _EdenFormFieldState extends State<EdenFormField> {
  EdenFormState? _formState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formState = context.findAncestorStateOfType<EdenFormState>();
  }

  @override
  void dispose() {
    _formState?.unregisterField(widget.name);
    super.dispose();
  }

  String? _validate(String? value) {
    for (final validator in widget.validators) {
      final error = validator(value);
      if (error != null) {
        _formState?.setFieldError(widget.name, error);
        return _formState?.widget.errorDisplayMode == EdenErrorDisplayMode.banner
            ? null
            : error;
      }
    }
    _formState?.setFieldError(widget.name, null);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final formState = _formState;
    final autoMode = formState?.widget.autovalidateMode ??
        EdenAutovalidateMode.disabled;

    return FormField<String>(
      validator: _validate,
      autovalidateMode: autoMode == EdenAutovalidateMode.onChange
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      builder: (fieldState) {
        final showInline =
            formState?.widget.errorDisplayMode != EdenErrorDisplayMode.banner;
        return Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus && autoMode == EdenAutovalidateMode.onBlur) {
              fieldState.validate();
            }
            if (hasFocus) {
              formState?.markDirty();
            }
          },
          child: widget.builder(showInline ? fieldState.errorText : null),
        );
      },
    );
  }
}
