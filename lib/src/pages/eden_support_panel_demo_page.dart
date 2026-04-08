import 'package:flutter/material.dart';

import '../widgets/support_panel/eden_support_panel.dart';
import '../widgets/support_panel/eden_support_panel_config.dart';
import '../widgets/support_panel/support_panel_models.dart';

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

final _mockCategories = [
  const SupportCategory(id: 'cat-1', name: 'Getting Started', sortOrder: 0),
  const SupportCategory(id: 'cat-2', name: 'Account and Billing', sortOrder: 1),
  const SupportCategory(id: 'cat-3', name: 'Integrations', sortOrder: 2),
];

final _mockArticles = [
  const SupportArticle(
    id: 'art-1',
    title: 'How to create your first project',
    body:
        'Creating your first project is easy. Navigate to the Projects section '
        'and click the New Project button. Fill in the project name and select '
        'a template to get started quickly.',
    categoryId: 'cat-1',
    viewCount: 1240,
    helpfulCount: 98,
  ),
  const SupportArticle(
    id: 'art-2',
    title: 'Inviting team members to your workspace',
    body:
        'You can invite team members from the Settings > Members page. Enter '
        'their email addresses and choose a role. Invitations expire after 7 '
        'days and can be resent from the same page.',
    categoryId: 'cat-1',
    viewCount: 870,
    helpfulCount: 74,
  ),
  const SupportArticle(
    id: 'art-3',
    title: 'Understanding your subscription plan',
    body:
        'Eden offers three tiers: Starter, Pro, and Enterprise. Each plan '
        'includes a different number of seats and storage limits. You can '
        'upgrade or downgrade at any time from the Billing settings page.',
    categoryId: 'cat-2',
    viewCount: 530,
    helpfulCount: 45,
  ),
  const SupportArticle(
    id: 'art-4',
    title: 'How billing works at the end of the month',
    body:
        'Billing is calculated on a monthly cycle tied to your signup date. '
        'Pro-rated charges apply when you add seats mid-cycle. Invoices are '
        'emailed automatically and available in the Billing portal.',
    categoryId: 'cat-2',
    viewCount: 410,
    helpfulCount: 38,
  ),
  const SupportArticle(
    id: 'art-5',
    title: 'Connecting your GitHub repository',
    body:
        'To connect GitHub, go to Settings > Integrations and click Connect '
        'next to GitHub. Authorise the Eden GitHub App and select which '
        'repositories to grant access to. Changes sync automatically.',
    categoryId: 'cat-3',
    viewCount: 980,
    helpfulCount: 88,
  ),
  const SupportArticle(
    id: 'art-6',
    title: 'Setting up Slack notifications',
    body:
        'The Eden Slack integration sends real-time notifications for events '
        'you choose. Install the Slack app from Settings > Integrations, then '
        'pick a channel and configure which event types trigger alerts.',
    categoryId: 'cat-3',
    viewCount: 620,
    helpfulCount: 55,
  ),
];

final _mockTickets = <SupportTicket>[
  SupportTicket(
    id: 'tkt-1',
    subject: 'Cannot export CSV from data table',
    description:
        'When I click the Export button on the main data table the download '
        'spinner appears but no file is saved to disk. Reproduced on Chrome '
        'and Safari. Console shows a 403 error.',
    status: SupportTicketStatus.open,
    priority: SupportTicketPriority.high,
    tags: ['bug', 'export'],
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  SupportTicket(
    id: 'tkt-2',
    subject: 'Request to increase API rate limit',
    description:
        'Our integration polls the API every 30 seconds for status updates '
        'and we are hitting the default rate limit during peak hours. '
        'We need the limit raised from 1000 to 5000 requests per hour.',
    status: SupportTicketStatus.inProgress,
    priority: SupportTicketPriority.normal,
    tags: ['api', 'rate-limit'],
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  SupportTicket(
    id: 'tkt-3',
    subject: 'Dark mode colors incorrect in settings page',
    description:
        'Several text elements on the Settings > Security page use the wrong '
        'contrast ratio in dark mode, making them hard to read. Screenshots '
        'attached.',
    status: SupportTicketStatus.resolved,
    priority: SupportTicketPriority.low,
    tags: ['ui', 'dark-mode'],
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

final _mockComments = <SupportComment>[
  SupportComment(
    id: 'cmt-1',
    ticketId: 'tkt-1',
    body: 'Thanks for the report! We have reproduced the issue internally and '
        'it appears to be a permissions misconfiguration in the export endpoint.',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  SupportComment(
    id: 'cmt-2',
    ticketId: 'tkt-1',
    body: 'A fix is being prepared and will be deployed in the next release, '
        'expected within 24 hours.',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  SupportComment(
    id: 'cmt-3',
    ticketId: 'tkt-2',
    body: 'We have reviewed your usage patterns and will increase your limit to '
        '3000 requests per hour as a temporary measure while we assess the '
        'full 5000 request tier.',
    createdAt: DateTime.now().subtract(const Duration(hours: 20)),
  ),
  SupportComment(
    id: 'cmt-4',
    ticketId: 'tkt-3',
    body: 'Fixed in v2.14.1. The text tokens for secondary content in dark mode '
        'have been corrected. Please update your app and let us know if the '
        'issue persists.',
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
  SupportComment(
    id: 'cmt-5',
    ticketId: 'tkt-3',
    body: 'Confirmed fixed — everything looks great in dark mode now. Thank you!',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

// ---------------------------------------------------------------------------
// Tour keys (used in mock EdenTourDefinition steps)
// ---------------------------------------------------------------------------

final _tourKeyNav = GlobalKey(debugLabel: 'tour-nav');
final _tourKeyBody = GlobalKey(debugLabel: 'tour-body');
final _tourKeyFab = GlobalKey(debugLabel: 'tour-fab');
final _tourKeySettings = GlobalKey(debugLabel: 'tour-settings');
final _tourKeyHelp = GlobalKey(debugLabel: 'tour-help');

final _mockTours = [
  EdenTourDefinition(
    id: 'tour-welcome',
    title: 'Welcome Tour',
    description:
        'A quick 3-step introduction to the main areas of the application.',
    steps: [_tourKeyNav, _tourKeyBody, _tourKeyFab],
    icon: Icons.waving_hand_outlined,
    isCompleted: false,
  ),
  EdenTourDefinition(
    id: 'tour-settings',
    title: 'Settings Tour',
    description: 'Learn where to find key configuration options in 2 steps.',
    steps: [_tourKeySettings, _tourKeyHelp],
    icon: Icons.settings_outlined,
    isCompleted: false,
  ),
];

// ---------------------------------------------------------------------------
// Mock callbacks (500 ms simulated async delay)
// ---------------------------------------------------------------------------

Future<T> _delay<T>(T value) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  return value;
}

Future<List<SupportArticle>> _searchArticles(String query) {
  final q = query.toLowerCase();
  return _delay(
    _mockArticles
        .where((a) => a.title.toLowerCase().contains(q))
        .toList(),
  );
}

Future<List<SupportCategory>> _listCategories({String? parentId}) {
  return _delay(
    _mockCategories
        .where((c) => c.parentId == parentId)
        .toList(),
  );
}

Future<List<SupportArticle>> _listArticles({String? categoryId}) {
  return _delay(
    categoryId == null
        ? List<SupportArticle>.from(_mockArticles)
        : _mockArticles.where((a) => a.categoryId == categoryId).toList(),
  );
}

Future<SupportArticle?> _getArticle(String articleId) {
  return _delay(
    _mockArticles.where((a) => a.id == articleId).firstOrNull,
  );
}

Future<void> _articleFeedback(String articleId, bool helpful) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  debugPrint('Article feedback: $articleId helpful=$helpful');
}

Future<SupportTicket> _createTicket({
  required String subject,
  required String description,
  required SupportTicketPriority priority,
}) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  final ticket = SupportTicket(
    id: 'tkt-${DateTime.now().millisecondsSinceEpoch}',
    subject: subject,
    description: description,
    status: SupportTicketStatus.open,
    priority: priority,
    tags: [],
    createdAt: DateTime.now(),
  );
  _mockTickets.add(ticket);
  return ticket;
}

Future<List<SupportTicket>> _listTickets() {
  return _delay(List<SupportTicket>.from(_mockTickets));
}

Future<SupportComment> _addComment({
  required String ticketId,
  required String body,
}) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  final comment = SupportComment(
    id: 'cmt-${DateTime.now().millisecondsSinceEpoch}',
    ticketId: ticketId,
    body: body,
    createdAt: DateTime.now(),
  );
  _mockComments.add(comment);
  return comment;
}

Future<List<SupportComment>> _listComments(String ticketId) {
  return _delay(
    _mockComments.where((c) => c.ticketId == ticketId).toList(),
  );
}

void _onTourComplete(String tourId) {
  debugPrint('Tour $tourId completed');
}

// ---------------------------------------------------------------------------
// Demo page
// ---------------------------------------------------------------------------

/// Dev catalog demo page for [EdenSupportPanel].
///
/// Renders the panel wrapping a simple content placeholder. All three tabs
/// (Help, Support, Tours) are populated with realistic mock data and 500ms
/// simulated async delays so loading states are visible in the catalog.
///
/// Use this page to visually verify:
/// - Panel open/close animation
/// - Help tab: search, category browsing, article detail, feedback buttons
/// - Support tab: ticket list, ticket creation, ticket detail, comment thread
/// - Tours tab: tour list with descriptions and step counts
class EdenSupportPanelDemoPage extends StatelessWidget {
  const EdenSupportPanelDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = EdenSupportPanelConfig(
      searchArticles: _searchArticles,
      listCategories: _listCategories,
      listArticles: _listArticles,
      getArticle: _getArticle,
      articleFeedback: _articleFeedback,
      createTicket: _createTicket,
      listTickets: _listTickets,
      addComment: _addComment,
      listComments: _listComments,
      onTourComplete: _onTourComplete,
      tours: _mockTours,
    );

    return EdenSupportPanel(
      config: config,
      child: _DemoContent(),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder content area
// ---------------------------------------------------------------------------

class _DemoContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Support Panel Demo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Support Panel Demo',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click the FAB in the bottom-right corner to open the support panel. '
                'All three tabs are populated with realistic mock data.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _FeatureChip(label: 'Help tab', icon: Icons.menu_book_outlined),
                  _FeatureChip(label: 'Support tab', icon: Icons.confirmation_number_outlined),
                  _FeatureChip(label: 'Tours tab', icon: Icons.map_outlined),
                  _FeatureChip(label: '500ms delays', icon: Icons.hourglass_top_outlined),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
