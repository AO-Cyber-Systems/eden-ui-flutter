import 'support_panel_models.dart';

// ---------------------------------------------------------------------------
// Callback typedefs
// ---------------------------------------------------------------------------

/// Searches articles by query string.
typedef SearchArticlesCallback = Future<List<SupportArticle>> Function(
    String query);

/// Lists top-level or child categories.
typedef ListCategoriesCallback = Future<List<SupportCategory>> Function(
    {String? parentId});

/// Lists articles, optionally filtered by category.
typedef ListArticlesCallback = Future<List<SupportArticle>> Function(
    {String? categoryId});

/// Fetches a single article by id.
typedef GetArticleCallback = Future<SupportArticle?> Function(String articleId);

/// Records "was this helpful?" feedback for an article.
typedef ArticleFeedbackCallback = Future<void> Function(
    String articleId, bool helpful);

/// Creates a new support ticket.
typedef CreateTicketCallback = Future<SupportTicket> Function({
  required String subject,
  required String description,
  required SupportTicketPriority priority,
});

/// Lists all tickets for the current user.
typedef ListTicketsCallback = Future<List<SupportTicket>> Function();

/// Adds a comment to an existing ticket.
typedef AddCommentCallback = Future<SupportComment> Function({
  required String ticketId,
  required String body,
});

/// Lists comments for a ticket.
typedef ListCommentsCallback = Future<List<SupportComment>> Function(
    String ticketId);

/// Called when a tour is completed so the app can persist the state.
typedef OnTourCompleteCallback = void Function(String tourId);

// ---------------------------------------------------------------------------
// Config class
// ---------------------------------------------------------------------------

/// Configuration object passed to [EdenSupportPanel].
///
/// Tab visibility is derived from which callbacks are provided:
/// - Help tab visible when [searchArticles] or [listArticles] is non-null.
/// - Support tab visible when [createTicket] or [listTickets] is non-null.
/// - Tours tab visible when [tours] is non-empty.
class EdenSupportPanelConfig {
  const EdenSupportPanelConfig({
    this.searchArticles,
    this.listCategories,
    this.listArticles,
    this.getArticle,
    this.articleFeedback,
    this.createTicket,
    this.listTickets,
    this.addComment,
    this.listComments,
    this.onTourComplete,
    this.tours = const [],
    this.panelWidth = 380,
    this.initialTab = 0,
  });

  // Help tab callbacks
  final SearchArticlesCallback? searchArticles;
  final ListCategoriesCallback? listCategories;
  final ListArticlesCallback? listArticles;
  final GetArticleCallback? getArticle;
  final ArticleFeedbackCallback? articleFeedback;

  // Support tab callbacks
  final CreateTicketCallback? createTicket;
  final ListTicketsCallback? listTickets;
  final AddCommentCallback? addComment;
  final ListCommentsCallback? listComments;

  // Tours tab
  final List<EdenTourDefinition> tours;
  final OnTourCompleteCallback? onTourComplete;

  // Layout
  final double panelWidth;
  final int initialTab;

  // ---------------------------------------------------------------------------
  // Tab visibility getters
  // ---------------------------------------------------------------------------

  /// True when at least one help-article callback is provided.
  bool get showHelpTab =>
      searchArticles != null || listArticles != null || getArticle != null;

  /// True when at least one support-ticket callback is provided.
  bool get showSupportTab => createTicket != null || listTickets != null;

  /// True when the tours list is non-empty.
  bool get showToursTab => tours.isNotEmpty;
}
