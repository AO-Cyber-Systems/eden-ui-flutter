import 'package:flutter/material.dart';

import '../eden_empty_state.dart';
import '../eden_spinner.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';
import 'eden_support_panel_config.dart';
import 'support_panel_models.dart';

/// Full article detail view with "was this helpful?" feedback.
///
/// Fetches the full article body via [EdenSupportPanelConfig.getArticle] when
/// the provided article has no [SupportArticle.body]. Displays metadata,
/// selectable body text, and optional thumbs up/down feedback.
///
/// Navigation is handled via [onBack]; no Navigator is used.
class EdenArticleView extends StatefulWidget {
  const EdenArticleView({
    super.key,
    required this.article,
    required this.config,
    required this.onBack,
  });

  final SupportArticle article;
  final EdenSupportPanelConfig config;
  final VoidCallback onBack;

  @override
  State<EdenArticleView> createState() => _EdenArticleViewState();
}

class _EdenArticleViewState extends State<EdenArticleView> {
  SupportArticle? _fullArticle;
  bool _isLoading = true;
  bool _feedbackGiven = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // If body is already present, no network call needed.
    if (widget.article.body != null) {
      setState(() {
        _fullArticle = widget.article;
        _isLoading = false;
      });
      return;
    }
    if (widget.config.getArticle == null) {
      setState(() {
        _fullArticle = widget.article;
        _isLoading = false;
      });
      return;
    }
    try {
      final fetched = await widget.config.getArticle!(widget.article.id);
      if (mounted) {
        setState(() {
          _fullArticle = fetched ?? widget.article;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onFeedback(bool helpful) async {
    if (_feedbackGiven || widget.config.articleFeedback == null) return;
    try {
      await widget.config.articleFeedback!(widget.article.id, helpful);
      if (mounted) setState(() => _feedbackGiven = true);
    } catch (_) {
      // Feedback is best-effort; silent failure is acceptable here.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: EdenSpinner());
    }

    if (_error != null) {
      return EdenEmptyState(
        icon: Icons.error_outline,
        title: 'Could not load article',
        description: _error,
        actionLabel: 'Retry',
        onAction: _loadArticle,
      );
    }

    final theme = Theme.of(context);
    final article = _fullArticle!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Semantics(
            button: true,
            label: 'Back to articles',
            child: GestureDetector(
              onTap: widget.onBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 18),
                  const SizedBox(width: EdenSpacing.space2),
                  Text(
                    'Back',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EdenSpacing.space4),

          // Title
          Text(
            article.title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: EdenSpacing.space3),

          // Metadata row
          Row(
            children: [
              _MetaBadge(label: '${article.viewCount} views', theme: theme),
              const SizedBox(width: EdenSpacing.space2),
              _MetaBadge(
                label: '${article.helpfulCount} found helpful',
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: EdenSpacing.space4),

          const Divider(),
          const SizedBox(height: EdenSpacing.space4),

          // Body
          SelectableText(
            article.body?.isNotEmpty == true
                ? article.body!
                : 'No content available.',
            style: theme.textTheme.bodyMedium,
          ),

          const SizedBox(height: EdenSpacing.space6),

          // "Was this helpful?" feedback section
          if (widget.config.articleFeedback != null)
            _FeedbackSection(
              feedbackGiven: _feedbackGiven,
              onFeedback: _onFeedback,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meta badge
// ---------------------------------------------------------------------------

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EdenRadii.sm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback section
// ---------------------------------------------------------------------------

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({
    required this.feedbackGiven,
    required this.onFeedback,
    required this.theme,
  });

  final bool feedbackGiven;
  final Future<void> Function(bool helpful) onFeedback;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (feedbackGiven) {
      return Text(
        'Thanks for your feedback!',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      children: [
        Text(
          'Was this helpful?',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(width: EdenSpacing.space3),
        Semantics(
          button: true,
          label: 'Helpful',
          child: GestureDetector(
            onTap: () => onFeedback(true),
            child: Icon(
              Icons.thumb_up_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: EdenSpacing.space3),
        Semantics(
          button: true,
          label: 'Not helpful',
          child: GestureDetector(
            onTap: () => onFeedback(false),
            child: Icon(
              Icons.thumb_down_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
