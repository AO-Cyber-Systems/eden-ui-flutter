import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Showcase screen for batch 3 compound / application-level components.
class CompoundScreen extends StatefulWidget {
  const CompoundScreen({super.key});

  @override
  State<CompoundScreen> createState() => _CompoundScreenState();
}

class _CompoundScreenState extends State<CompoundScreen> {
  double _rating = 3.5;
  int _bottomNavIndex = 0;
  final _tasks = [
    EdenTaskItemData(title: 'Design new landing page', subtitle: 'Due tomorrow', completed: true),
    EdenTaskItemData(title: 'Review pull requests', subtitle: '3 pending'),
    EdenTaskItemData(title: 'Update documentation', completed: false),
    EdenTaskItemData(title: 'Deploy to staging'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compound Components')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // Kanban
          const Section(
            title: 'KANBAN BOARD',
            child: SizedBox(
              height: 400,
              child: EdenKanbanBoard(
                children: [
                  EdenKanbanColumn(
                    title: 'To Do',
                    color: EdenKanbanColumnColor.neutral,
                    count: 2,
                    children: [
                      EdenKanbanCard(title: 'Research competitors', tags: [EdenKanbanTag(label: 'Research')], priority: EdenKanbanPriority.low),
                      EdenKanbanCard(title: 'Write user stories', tags: [EdenKanbanTag(label: 'Planning')], dueDate: 'Mar 15'),
                    ],
                  ),
                  EdenKanbanColumn(
                    title: 'In Progress',
                    color: EdenKanbanColumnColor.primary,
                    count: 1,
                    children: [
                      EdenKanbanCard(
                        title: 'Build dashboard UI',
                        tags: [EdenKanbanTag(label: 'Frontend'), EdenKanbanTag(label: 'UI')],
                        priority: EdenKanbanPriority.high,
                        assigneeInitials: ['A'],
                      ),
                    ],
                  ),
                  EdenKanbanColumn(
                    title: 'Done',
                    color: EdenKanbanColumnColor.success,
                    count: 1,
                    children: [
                      EdenKanbanCard(title: 'Setup project', tags: [EdenKanbanTag(label: 'DevOps')], priority: EdenKanbanPriority.medium),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Calendar
          Section(
            title: 'CALENDAR',
            child: EdenCalendar(
              onDateSelected: (d) {},
              events: [
                EdenCalendarEvent(date: DateTime(2026, 3, 8)),
                EdenCalendarEvent(date: DateTime(2026, 3, 8)),
                EdenCalendarEvent(date: DateTime(2026, 3, 12)),
                EdenCalendarEvent(date: DateTime(2026, 3, 20)),
                EdenCalendarEvent(date: DateTime(2026, 3, 20)),
                EdenCalendarEvent(date: DateTime(2026, 3, 20)),
              ],
            ),
          ),

          // Timeline
          const Section(
            title: 'TIMELINE',
            child: EdenTimeline(
              items: [
                EdenTimelineItemData(
                  title: 'Order placed',
                  body: 'Your order #1234 has been confirmed.',
                  datetime: '10:00 AM',
                  icon: Icons.shopping_cart,
                ),
                EdenTimelineItemData(
                  title: 'Payment received',
                  body: 'Payment of \$99.00 processed.',
                  datetime: '10:05 AM',
                  icon: Icons.payment,
                ),
                EdenTimelineItemData(
                  title: 'Shipped',
                  datetime: '2:30 PM',
                  icon: Icons.local_shipping,
                ),
                EdenTimelineItemData(
                  title: 'Delivered',
                  datetime: 'Pending',
                  icon: Icons.check_circle,
                ),
              ],
            ),
          ),

          // Breadcrumb
          Section(
            title: 'BREADCRUMB',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EdenBreadcrumb(
                  items: [
                    EdenBreadcrumbItem(label: 'Home', icon: Icons.home, onTap: () {}),
                    EdenBreadcrumbItem(label: 'Products', onTap: () {}),
                    const EdenBreadcrumbItem(label: 'Electronics'),
                  ],
                ),
                const SizedBox(height: EdenSpacing.space3),
                EdenBreadcrumb(
                  items: [
                    EdenBreadcrumbItem(label: 'Dashboard', onTap: () {}),
                    EdenBreadcrumbItem(label: 'Settings', onTap: () {}),
                    EdenBreadcrumbItem(label: 'Profile', onTap: () {}),
                    const EdenBreadcrumbItem(label: 'Edit'),
                  ],
                ),
              ],
            ),
          ),

          // Rating
          Section(
            title: 'RATING',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EdenRating(value: 4, size: EdenRatingSize.sm),
                const SizedBox(height: EdenSpacing.space2),
                EdenRating(
                  value: _rating,
                  size: EdenRatingSize.md,
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: EdenSpacing.space2),
                const EdenRating(value: 3.5, size: EdenRatingSize.lg),
              ],
            ),
          ),

          // Code Block
          const Section(
            title: 'CODE BLOCK',
            child: EdenCodeBlock(
              language: 'dart',
              code: 'void main() {\n  runApp(const MyApp());\n}\n\nclass MyApp extends StatelessWidget {\n  const MyApp({super.key});\n\n  @override\n  Widget build(BuildContext context) {\n    return MaterialApp(\n      home: Scaffold(),\n    );\n  }\n}',
              lineNumbers: true,
            ),
          ),

          // Kbd
          const Section(
            title: 'KEYBOARD SHORTCUTS',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                EdenKbd('⌘'),
                EdenKbd('K'),
                SizedBox(width: 16),
                EdenKbd('Ctrl'),
                EdenKbd('Shift'),
                EdenKbd('P'),
                SizedBox(width: 16),
                EdenKbd('Esc'),
              ],
            ),
          ),

          // Indicator
          const Section(
            title: 'STATUS INDICATOR',
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                EdenIndicator(variant: EdenIndicatorVariant.success, label: 'Online'),
                EdenIndicator(variant: EdenIndicatorVariant.warning, label: 'Away'),
                EdenIndicator(variant: EdenIndicatorVariant.danger, label: 'Busy', ping: true),
                EdenIndicator(variant: EdenIndicatorVariant.info, label: 'Syncing', ping: true),
                EdenIndicator(variant: EdenIndicatorVariant.neutral, label: 'Offline'),
              ],
            ),
          ),

          // Task List
          Section(
            title: 'TASK LIST',
            child: EdenCard(
              child: EdenTaskList(
                title: 'Sprint Tasks',
                tasks: _tasks,
              ),
            ),
          ),

          // Typing Indicator
          const Section(
            title: 'TYPING INDICATOR',
            child: EdenTypingIndicator(),
          ),

          // Notification List
          Section(
            title: 'NOTIFICATION LIST',
            child: EdenNotificationList(
              notifications: [
                const EdenNotificationItemData(
                  title: 'New comment on your post',
                  body: 'John replied to your discussion thread.',
                  time: '2m ago',
                  icon: Icons.comment,
                  variant: EdenNotificationVariant.info,
                ),
                const EdenNotificationItemData(
                  title: 'Deployment successful',
                  body: 'v2.1.0 deployed to production.',
                  time: '15m ago',
                  icon: Icons.rocket_launch,
                  variant: EdenNotificationVariant.success,
                  read: true,
                ),
                const EdenNotificationItemData(
                  title: 'Storage limit warning',
                  body: 'You have used 90% of your storage.',
                  time: '1h ago',
                  icon: Icons.warning_amber,
                  variant: EdenNotificationVariant.warning,
                ),
              ],
              onMarkAllRead: () {},
              onViewAll: () {},
            ),
          ),

          // Carousel
          const Section(
            title: 'CAROUSEL',
            child: EdenCarousel(
              height: 180,
              children: [
                _CarouselSlide(color: EdenColors.gold, label: 'Slide 1'),
                _CarouselSlide(color: EdenColors.blue, label: 'Slide 2'),
                _CarouselSlide(color: EdenColors.emerald, label: 'Slide 3'),
                _CarouselSlide(color: EdenColors.purple, label: 'Slide 4'),
              ],
            ),
          ),

          // Error Page
          Section(
            title: 'ERROR PAGE (404)',
            child: SizedBox(
              height: 350,
              child: EdenCard(
                child: EdenErrorPage.notFound(onAction: () {}),
              ),
            ),
          ),

          // Bottom Nav
          Section(
            title: 'BOTTOM NAVIGATION',
            child: EdenCard(
              child: EdenBottomNav(
                selectedIndex: _bottomNavIndex,
                onChanged: (i) => setState(() => _bottomNavIndex = i),
                items: const [
                  EdenBottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
                  EdenBottomNavItem(icon: Icons.search_outlined, label: 'Search'),
                  EdenBottomNavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alerts'),
                  EdenBottomNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
                ],
              ),
            ),
          ),

          const SizedBox(height: EdenSpacing.space8),
        ],
      ),
    );
  }
}

class _CarouselSlide extends StatelessWidget {
  const _CarouselSlide({required this.color, required this.label});
  final MaterialColor color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
