import 'dart:async';

import 'package:flutter/material.dart';

import '../eden_empty_state.dart';
import '../eden_search_input.dart';
import '../eden_spinner.dart';
import '../../tokens/spacing.dart';
import '../../tokens/radii.dart';
import 'eden_support_panel_config.dart';
import 'support_panel_models.dart';

/// Full Help tab with search, category browsing, and article list.
///
/// Supports drill-down navigation to article detail via an internal widget
/// stack — no Navigator required.
class EdenHelpTab extends StatefulWidget {
  const EdenHelpTab({super.key, required this.config});

  final EdenSupportPanelConfig config;

  @override
  State<EdenHelpTab> createState() => _EdenHelpTabState();
}

class _EdenHelpTabState extends State<EdenHelpTab> {
  List<SupportArticle> _articles = [];
  List<SupportCategory> _categories = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  final List<Widget> _viewStack = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (widget.config.listCategories != null) {
        final cats = await widget.config.listCategories!();
        if (mounted) setState(() => _categories = cats);
      }
      if (widget.config.listArticles != null) {
        final arts = await widget.config.listArticles!();
        if (mounted) setState(() => _articles = arts);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadArticles({String? categoryId}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (widget.config.listArticles != null) {
        final arts =
            await widget.config.listArticles!(categoryId: categoryId);
        if (mounted) setState(() => _articles = arts);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _searchQuery = query;
        _isLoading = true;
        _error = null;
      });
      try {
        if (query.isEmpty) {
          await _loadArticles(categoryId: _selectedCategoryId);
        } else if (widget.config.searchArticles != null) {
          final results = await widget.config.searchArticles!(query);
          if (mounted) {
            setState(() {
              _articles = results;
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    });
  }

  void _onCategoryTap(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _searchQuery = '';
    });
    _loadArticles(categoryId: categoryId);
  }

  void _pushArticleView(SupportArticle article) {
    setState(() {
      _viewStack.add(
        _ArticleDetailHost(
          article: article,
          config: widget.config,
          onBack: _popView,
        ),
      );
    });
  }

  void _popView() {
    setState(() => _viewStack.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    if (_viewStack.isNotEmpty) {
      return _viewStack.last;
    }
    return _buildListView(context);
  }

  Widget _buildListView(BuildContext context) {
    final theme = Theme.of(context);
    final showSearch = widget.config.searchArticles != null;
    final showCategories =
        widget.config.listCategories != null && _categories.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search input
        if (showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EdenSpacing.space4,
              EdenSpacing.space4,
              EdenSpacing.space4,
              EdenSpacing.space2,
            ),
            child: EdenSearchInput(
              hint: 'Search articles...',
              onChanged: _onSearchChanged,
            ),
          ),

        // Category chips
        if (showCategories)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space2,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: _selectedCategoryId == null,
                    onTap: () => _onCategoryTap(null),
                  ),
                  ..._categories.map((cat) => _CategoryChip(
                        label: cat.name,
                        selected: _selectedCategoryId == cat.id,
                        onTap: () => _onCategoryTap(cat.id),
                      )),
                ],
              ),
            ),
          ),

        // Article list body
        Expanded(
          child: _buildBody(theme),
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: EdenSpinner());
    }

    if (_error != null) {
      return EdenEmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        description: _error,
        actionLabel: 'Retry',
        onAction: _loadInitialData,
      );
    }

    if (_articles.isEmpty) {
      return EdenEmptyState(
        icon: Icons.menu_book,
        title: 'No articles found',
        description: _searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'No articles available',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space2,
      ),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        return _ArticleListItem(
          article: article,
          onTap: () => _pushArticleView(article),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Category chip
// ---------------------------------------------------------------------------

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: EdenSpacing.space2),
      child: Semantics(
        button: true,
        selected: selected,
        label: '${selected ? "Selected category: " : "Category: "}$label',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space3,
              vertical: EdenSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(EdenRadii.full),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Article list item
// ---------------------------------------------------------------------------

class _ArticleListItem extends StatelessWidget {
  const _ArticleListItem({
    required this.article,
    required this.onTap,
  });

  final SupportArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'View article: ${article.title}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: EdenSpacing.space2),
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space4,
            vertical: EdenSpacing.space3,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(EdenRadii.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (article.viewCount > 0) ...[
                      const SizedBox(height: EdenSpacing.space1),
                      Text(
                        '${article.viewCount} views',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Article detail host (thin shell that delegates to EdenArticleView)
// ---------------------------------------------------------------------------

/// Internal host widget that connects article detail back to the help tab
/// stack. Imported here to avoid a circular dependency on the public export.
class _ArticleDetailHost extends StatefulWidget {
  const _ArticleDetailHost({
    required this.article,
    required this.config,
    required this.onBack,
  });

  final SupportArticle article;
  final EdenSupportPanelConfig config;
  final VoidCallback onBack;

  @override
  State<_ArticleDetailHost> createState() => _ArticleDetailHostState();
}

class _ArticleDetailHostState extends State<_ArticleDetailHost> {
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
    // If body already present, no need to fetch.
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
    if (_feedbackGiven) return;
    try {
      await widget.config.articleFeedback!(widget.article.id, helpful);
      if (mounted) setState(() => _feedbackGiven = true);
    } catch (_) {
      // Feedback is best-effort; silent failure acceptable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: EdenSpinner());
    }

    if (_error != null) {
      return EdenEmptyState(
        icon: Icons.error_outline,
        title: 'Could not load article',
        description: _error,
        actionLabel: 'Retry',
        onAction: () {
          setState(() {
            _isLoading = true;
            _error = null;
          });
          _loadArticle();
        },
      );
    }

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
                  theme: theme),
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

          // "Was this helpful?" feedback
          if (widget.config.articleFeedback != null)
            _FeedbackRow(
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
// Feedback row
// ---------------------------------------------------------------------------

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({
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
