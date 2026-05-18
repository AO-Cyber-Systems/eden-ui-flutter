import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'eden_card.dart';
import 'eden_empty_state.dart';
import 'eden_status_badge.dart';
import 'eden_urgency_badge.dart';
import 'scheduler/scheduler_controller.dart';
import 'scheduler/scheduler_models.dart';

/// Status of a single work item in the dispatch queue.
enum EdenDispatchWorkItemStatus { pending, assigned, inProgress, completed }

/// Generic value class for a single dispatchable work item (job, delivery,
/// service call, home visit). Consumer maps domain row → this class.
@immutable
class EdenDispatchWorkItem {
  const EdenDispatchWorkItem({
    required this.id,
    required this.title,
    required this.customerName,
    required this.address,
    required this.urgency,
    required this.estimatedDuration,
    this.requiredSkills = const [],
    this.requestedDate,
    this.status = EdenDispatchWorkItemStatus.pending,
  });

  final String id;
  final String title;
  final String customerName;
  final String address;

  /// Canonical urgency string forwarded to [EdenUrgencyBadge] —
  /// `low` / `medium` / `high` / `critical` (any other string renders verbatim).
  final String urgency;

  final Duration estimatedDuration;
  final List<String> requiredSkills;
  final DateTime? requestedDate;
  final EdenDispatchWorkItemStatus status;
}

/// Emitted by [EdenDispatchPage] when the dispatcher assigns a work item
/// to a crew.
@immutable
class EdenDispatchAssignment {
  const EdenDispatchAssignment({
    required this.workItemId,
    required this.crewResourceId,
    required this.scheduledStart,
    required this.scheduledDuration,
  });

  final String workItemId;
  final String crewResourceId;
  final DateTime scheduledStart;
  final Duration scheduledDuration;
}

/// Slot-builder typedef for consumer-supplied map/AI panels.
typedef EdenDispatchSlotBuilder = Widget Function(
    BuildContext context, EdenDispatchData data);

/// Consumer-supplied map widget slot (wired to EdenMapPreview, leaflet,
/// google_maps_flutter, or any other map provider). Returns no-op when
/// the consumer wants the map zone hidden.
@immutable
class EdenDispatchMapSlot {
  const EdenDispatchMapSlot({required this.builder});
  final EdenDispatchSlotBuilder builder;
}

/// Consumer-supplied AI panel slot (typically wraps EdenAiPanel).
@immutable
class EdenDispatchAiSlot {
  const EdenDispatchAiSlot({required this.builder});
  final EdenDispatchSlotBuilder builder;
}

/// Scheduler portion of the dispatch page state. Composes the scheduler
/// controller (obj 004-01) + crew resources + scheduled events.
@immutable
class EdenDispatchSchedulerSlot {
  const EdenDispatchSchedulerSlot({
    required this.controller,
    required this.events,
    required this.crewResources,
    this.dayStart,
    this.dayEnd,
  });

  final EdenSchedulerController controller;
  final List<EdenSchedulerEvent> events;
  final List<EdenSchedulerResource> crewResources;
  final TimeOfDay? dayStart;
  final TimeOfDay? dayEnd;
}

/// Work queue portion of the dispatch page state.
@immutable
class EdenDispatchWorkQueue {
  const EdenDispatchWorkQueue({
    required this.items,
    this.onItemTap,
    this.headerSlot,
  });

  final List<EdenDispatchWorkItem> items;
  final ValueChanged<String>? onItemTap;
  final Widget? headerSlot;
}

/// Immutable container for all dispatch page state.
@immutable
class EdenDispatchData {
  const EdenDispatchData({
    required this.scheduler,
    required this.queue,
    this.mapSlot,
    this.aiSlot,
  });

  final EdenDispatchSchedulerSlot scheduler;
  final EdenDispatchWorkQueue queue;
  final EdenDispatchMapSlot? mapSlot;
  final EdenDispatchAiSlot? aiSlot;
}

/// Canonical dispatch screen composite — scheduler swimlane + open-work
/// queue + optional map + optional AI sidebar.
///
/// Responsive: 3-zone Row (>=1280pt) → 2-zone (>=1024pt) → tabbed (<1024pt).
///
/// Cross-vertical: trades crew dispatch, fuel multi-truck routing, medical
/// home-visit dispatch. Consumer maps domain entities to [EdenDispatchWorkItem]
/// + [EdenSchedulerResource]; library renders the canonical shape.
///
/// Drag-from-queue-to-scheduler at >=1024pt; long-press 'Assign...' menu
/// fallback in tabbed mode.
class EdenDispatchPage extends StatefulWidget {
  const EdenDispatchPage({
    super.key,
    required this.data,
    required this.onDispatchAssignment,
    this.onDataChange,
    this.showMapZone = true,
    this.showAiZone = false,
  });

  final EdenDispatchData data;
  final ValueChanged<EdenDispatchAssignment> onDispatchAssignment;
  final ValueChanged<EdenDispatchData>? onDataChange;
  final bool showMapZone;
  final bool showAiZone;

  /// Returns true when the crew can accept this work item. Default rule:
  /// either the item has no required skills, OR the crew's name contains
  /// one of the required skill tokens (case-insensitive).
  static bool defaultCrewCanHandle(
      EdenSchedulerResource crew, EdenDispatchWorkItem item) {
    if (item.requiredSkills.isEmpty) return true;
    final crewSkills =
        (crew.crew ?? const <String>[]).map((s) => s.toLowerCase()).toSet();
    crewSkills.add(crew.name.toLowerCase());
    return item.requiredSkills
        .every((s) => crewSkills.any((c) => c.contains(s.toLowerCase())));
  }

  @override
  State<EdenDispatchPage> createState() => _EdenDispatchPageState();
}

class _EdenDispatchPageState extends State<EdenDispatchPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final width = constraints.maxWidth;
      if (width >= 1280) {
        // breakpoint: 1280 — dispatch full-desktop tier
        return _ThreeZoneLayout(parent: widget);
      } else if (width >= 1024) {
        // breakpoint: 1024 — dispatch tablet-landscape tier
        return _TwoZoneLayout(parent: widget);
      } else {
        return _TabbedLayout(parent: widget);
      }
    });
  }
}

// ─────────────────────────── Three-zone (>=1280pt) ────────────────────────

class _ThreeZoneLayout extends StatelessWidget {
  const _ThreeZoneLayout({required this.parent});

  final EdenDispatchPage parent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 5, child: _SchedulerZone(parent: parent)),
        const VerticalDivider(width: 1),
        Expanded(flex: 3, child: _QueueZone(parent: parent)),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              if (parent.showMapZone) Expanded(child: _MapZone(parent: parent)),
              if (parent.showMapZone && parent.showAiZone)
                const Divider(height: 1),
              if (parent.showAiZone) Expanded(child: _AiZone(parent: parent)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Two-zone (>=1024pt) ──────────────────────────

class _TwoZoneLayout extends StatelessWidget {
  const _TwoZoneLayout({required this.parent});

  final EdenDispatchPage parent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(flex: 5, child: _SchedulerZone(parent: parent)),
            const VerticalDivider(width: 1),
            Expanded(flex: 3, child: _QueueZone(parent: parent)),
          ],
        ),
        if (parent.showMapZone || parent.showAiZone)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              key: const Key('dispatch-floating-drawer'),
              onPressed: () => _showOverlayDrawer(context, parent),
              icon: const Icon(Icons.map),
              label: const Text('Map / AI'),
            ),
          ),
      ],
    );
  }

  void _showOverlayDrawer(BuildContext context, EdenDispatchPage parent) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: 500,
        child: Column(
          children: [
            if (parent.showMapZone) Expanded(child: _MapZone(parent: parent)),
            if (parent.showAiZone) Expanded(child: _AiZone(parent: parent)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Tabbed (<1024pt) ─────────────────────────────

class _TabbedLayout extends StatelessWidget {
  const _TabbedLayout({required this.parent});

  final EdenDispatchPage parent;

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[
      const Tab(text: 'Schedule'),
      const Tab(text: 'Queue'),
      if (parent.showMapZone) const Tab(text: 'Map'),
      if (parent.showAiZone) const Tab(text: 'AI'),
    ];
    final views = <Widget>[
      _SchedulerZone(parent: parent),
      _QueueZone(parent: parent, isTabbed: true),
      if (parent.showMapZone) _MapZone(parent: parent),
      if (parent.showAiZone) _AiZone(parent: parent),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(tabs: tabs),
          Expanded(child: TabBarView(children: views)),
        ],
      ),
    );
  }
}

// ─────────────────────────── Scheduler Zone ───────────────────────────────

class _SchedulerZone extends StatelessWidget {
  const _SchedulerZone({required this.parent});

  final EdenDispatchPage parent;

  @override
  Widget build(BuildContext context) {
    final crews = parent.data.scheduler.crewResources;
    if (crews.isEmpty) {
      return const EdenEmptyState(
        title: 'No crews configured',
        description: 'Add crews to start dispatching work.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Text(
            'Schedule',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: crews
                  .map((crew) => _CrewColumn(crew: crew, parent: parent))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CrewColumn extends StatelessWidget {
  const _CrewColumn({required this.crew, required this.parent});

  final EdenSchedulerResource crew;
  final EdenDispatchPage parent;

  static const _columnWidth = 220.0;
  static const _dayStartHour = 7;

  DateTime _slotTimeFromDropPosition(double dropY) {
    final base = parent.data.scheduler.controller.focusedDate;
    final start = parent.data.scheduler.dayStart ??
        const TimeOfDay(hour: _dayStartHour, minute: 0);
    // 1pt = 1 minute by convention (documented in TRD gotcha).
    final minutes = (dropY).clamp(0, 720).toInt();
    return DateTime(base.year, base.month, base.day, start.hour, start.minute)
        .add(Duration(minutes: minutes));
  }

  @override
  Widget build(BuildContext context) {
    final crewEvents = parent.data.scheduler.events
        .where((e) => e.resourceIds?.contains(crew.id) ?? false)
        .toList();
    return SizedBox(
      width: _columnWidth,
      child: DragTarget<EdenDispatchWorkItem>(
        onWillAcceptWithDetails: (details) =>
            EdenDispatchPage.defaultCrewCanHandle(crew, details.data),
        onAcceptWithDetails: (details) {
          final item = details.data;
          // Drop position on column → slot time
          final RenderBox box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.offset);
          final slotTime = _slotTimeFromDropPosition(local.dy);
          parent.onDispatchAssignment(EdenDispatchAssignment(
            workItemId: item.id,
            crewResourceId: crew.id,
            scheduledStart: slotTime,
            scheduledDuration: item.estimatedDuration,
          ));
        },
        builder: (ctx, candidate, rejected) {
          final highlighted = candidate.isNotEmpty;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: highlighted
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.06)
                  : null,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(EdenSpacing.space2),
                  decoration: BoxDecoration(
                    color: crew.color ?? EdenColors.neutral[100],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(crew.name,
                          style: Theme.of(context).textTheme.titleSmall),
                      if (crew.crew != null && crew.crew!.isNotEmpty)
                        Text(crew.crew!.join(', '),
                            style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(EdenSpacing.space2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (crewEvents.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No scheduled jobs',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        )
                      else
                        for (final event in crewEvents)
                          _ScheduledEventChip(event: event),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScheduledEventChip extends StatelessWidget {
  const _ScheduledEventChip({required this.event});

  final EdenSchedulerEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(EdenSpacing.space2),
      decoration: BoxDecoration(
        color: (event.color ?? Theme.of(context).colorScheme.primary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(event.title, style: Theme.of(context).textTheme.bodySmall),
          Text(
            '${event.start.hour}:${event.start.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Queue Zone ───────────────────────────────────

class _QueueZone extends StatelessWidget {
  const _QueueZone({required this.parent, this.isTabbed = false});

  final EdenDispatchPage parent;
  final bool isTabbed;

  @override
  Widget build(BuildContext context) {
    final queue = parent.data.queue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Row(
            children: [
              Text('Open Work', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${queue.items.length}',
                    style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
        ),
        if (queue.headerSlot != null) queue.headerSlot!,
        Expanded(
          child: queue.items.isEmpty
              ? const EdenEmptyState(title: 'No open work')
              : ListView.builder(
                  itemCount: queue.items.length,
                  itemBuilder: (ctx, i) {
                    final item = queue.items[i];
                    final card = _WorkItemCard(
                      item: item,
                      onTap: () {
                        if (isTabbed) {
                          _showAssignMenu(context, item);
                        } else {
                          queue.onItemTap?.call(item.id);
                        }
                      },
                    );
                    if (isTabbed) return card;
                    return LongPressDraggable<EdenDispatchWorkItem>(
                      key: Key('work-item-drag-${item.id}'),
                      data: item,
                      feedback: Material(
                        elevation: 4,
                        child: SizedBox(
                          width: 320,
                          child: _WorkItemCard(item: item, onTap: () {}),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: 0.3, child: card),
                      child: card,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showAssignMenu(
      BuildContext context, EdenDispatchWorkItem item) async {
    final crews = parent.data.scheduler.crewResources;
    final selected = await showModalBottomSheet<EdenSchedulerResource>(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final crew in crews)
            if (EdenDispatchPage.defaultCrewCanHandle(crew, item))
              ListTile(
                title: Text(crew.name),
                subtitle: crew.crew != null && crew.crew!.isNotEmpty
                    ? Text(crew.crew!.join(', '))
                    : null,
                onTap: () => Navigator.of(context).pop(crew),
              ),
        ],
      ),
    );
    if (selected != null) {
      parent.onDispatchAssignment(EdenDispatchAssignment(
        workItemId: item.id,
        crewResourceId: selected.id,
        scheduledStart: parent.data.scheduler.controller.focusedDate,
        scheduledDuration: item.estimatedDuration,
      ));
    }
  }
}

class _WorkItemCard extends StatelessWidget {
  const _WorkItemCard({required this.item, required this.onTap});

  final EdenDispatchWorkItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3, vertical: 4),
      child: EdenCard.interactive(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  EdenUrgencyBadge(urgency: item.urgency),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.title,
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(item.customerName,
                  style: Theme.of(context).textTheme.bodySmall),
              Text(
                item.address,
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(item.estimatedDuration),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const Spacer(),
                  EdenStatusBadge(status: item.status.name),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ─────────────────────────── Map Zone ─────────────────────────────────────

class _MapZone extends StatelessWidget {
  const _MapZone({required this.parent});

  final EdenDispatchPage parent;

  @override
  Widget build(BuildContext context) {
    if (parent.data.mapSlot == null) {
      return const EdenEmptyState(
        title: 'Map provider not configured',
        description: 'Wire EdenDispatchMapSlot.builder to enable the map.',
      );
    }
    return parent.data.mapSlot!.builder(context, parent.data);
  }
}

// ─────────────────────────── AI Zone ──────────────────────────────────────

class _AiZone extends StatelessWidget {
  const _AiZone({required this.parent});

  final EdenDispatchPage parent;

  @override
  Widget build(BuildContext context) {
    if (parent.data.aiSlot == null) {
      return const EdenEmptyState(title: 'AI assistant not configured');
    }
    return parent.data.aiSlot!.builder(context, parent.data);
  }
}

// Ensure unused import warning suppression — re-exports below
// ignore: unused_element
typedef _UnusedPaletteRef = EdenStatusPalette;
