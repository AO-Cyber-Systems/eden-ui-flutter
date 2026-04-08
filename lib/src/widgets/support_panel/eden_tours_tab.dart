import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../tokens/durations.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../widgets/eden_button.dart';
import '../../widgets/eden_empty_state.dart';
import 'eden_support_panel_config.dart';
import 'support_panel_models.dart';

/// Tours tab — displays available product tours with launch capability.
///
/// Consumers provide tours via [EdenSupportPanelConfig.tours]. Each tour
/// shows its title, description, step count, and completion state. Tapping
/// "Start" closes the panel and launches the showcaseview walkthrough.
class EdenToursTab extends StatefulWidget {
  const EdenToursTab({
    super.key,
    required this.config,
    required this.onClosePanel,
  });

  final EdenSupportPanelConfig config;

  /// Called before launching a tour so the panel overlay is cleared first.
  final VoidCallback onClosePanel;

  @override
  State<EdenToursTab> createState() => _EdenToursTabState();
}

class _EdenToursTabState extends State<EdenToursTab> {
  void _launchTour(EdenTourDefinition tour) {
    // 1. Close the panel so the showcase overlay is fully visible.
    widget.onClosePanel();
    // 2. Brief delay for the panel close animation to complete.
    Future.delayed(EdenDurations.normal, () {
      try {
        ShowcaseView.get().startShowCase(tour.steps);
      } catch (e) {
        // ShowcaseView not registered in this context.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tour system not initialized. Wrap your app with ShowcaseView.register() in initState.',
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tours = widget.config.tours;

    if (tours.isEmpty) {
      return const EdenEmptyState(
        icon: Icons.map_outlined,
        title: 'No tours available',
        description: 'Guided walkthroughs will appear here when configured.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      itemCount: tours.length,
      itemBuilder: (context, index) {
        final tour = tours[index];
        final hasSteps = tour.steps.isNotEmpty;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < tours.length - 1 ? EdenSpacing.space3 : 0,
          ),
          child: Container(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: EdenRadii.borderRadiusMd,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tour icon
                Padding(
                  padding: const EdgeInsets.only(
                    top: 2,
                    right: EdenSpacing.space3,
                  ),
                  child: Icon(
                    tour.icon ?? Icons.explore,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                // Tour info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (tour.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tour.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: EdenSpacing.space2),
                      Text(
                        hasSteps
                            ? '${tour.steps.length} step${tour.steps.length == 1 ? '' : 's'}'
                            : 'No steps defined',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: EdenSpacing.space3),
                      // Launch / completed indicator
                      if (tour.isCompleted)
                        Semantics(
                          label: 'Tour completed',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Completed',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Semantics(
                          button: true,
                          label: 'Start tour: ${tour.title}',
                          child: EdenButton(
                            label: 'Start',
                            size: EdenButtonSize.sm,
                            disabled: !hasSteps,
                            onPressed: hasSteps ? () => _launchTour(tour) : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
