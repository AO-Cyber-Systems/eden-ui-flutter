import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A newsletter subscription section with email input and subscribe button.
///
/// Used on landing pages for email capture.
class EdenNewsletterSection extends StatefulWidget {
  const EdenNewsletterSection({
    super.key,
    required this.onSubscribe,
    this.title = 'Stay up to date',
    this.description = 'Subscribe to our newsletter for the latest updates.',
    this.inputHint = 'Enter your email',
    this.buttonLabel = 'Subscribe',
    this.successMessage,
    this.loading = false,
    this.padding,
  });

  /// Called when the subscribe button is tapped with a valid email.
  final void Function(String email) onSubscribe;

  final String title;
  final String description;
  final String inputHint;
  final String buttonLabel;

  /// If set, shows a success message instead of the form.
  final String? successMessage;

  final bool loading;
  final EdgeInsets? padding;

  @override
  State<EdenNewsletterSection> createState() => _EdenNewsletterSectionState();
}

class _EdenNewsletterSectionState extends State<EdenNewsletterSection> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubscribe() {
    final email = _controller.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Email is required');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() => _error = null);
    widget.onSubscribe(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: widget.padding ??
          const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space8,
            vertical: EdenSpacing.space12,
          ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: EdenRadii.borderRadiusXl,
      ),
      child: Column(
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: EdenSpacing.space2),
          Text(
            widget.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: EdenSpacing.space6),
          if (widget.successMessage != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle,
                    size: 20, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  widget.successMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleSubscribe(),
                          decoration: InputDecoration(
                            hintText: widget.inputHint,
                            errorText: _error,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: EdenRadii.borderRadiusMd,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: EdenSpacing.space3),
                      FilledButton(
                        onPressed: widget.loading ? null : _handleSubscribe,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: EdenSpacing.space5,
                            vertical: EdenSpacing.space3,
                          ),
                        ),
                        child: widget.loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(widget.buttonLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
