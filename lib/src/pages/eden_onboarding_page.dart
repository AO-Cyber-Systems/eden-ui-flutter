import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_button.dart';

/// Data class representing a single onboarding step.
class EdenOnboardingStep {
  const EdenOnboardingStep({
    required this.title,
    this.description,
    this.icon,
    this.image,
    this.content,
  });

  /// Step title.
  final String title;

  /// Step description text.
  final String? description;

  /// Icon shown when [image] is null.
  final IconData? icon;

  /// Custom illustration widget (takes priority over [icon]).
  final Widget? image;

  /// Custom content rendered below the description.
  final Widget? content;
}

/// A multi-step onboarding flow with horizontal page swiping, dot indicators,
/// skip button, and a "Get Started" action on the final page.
class EdenOnboardingPage extends StatefulWidget {
  const EdenOnboardingPage({
    super.key,
    required this.steps,
    required this.onComplete,
    this.showSkip = true,
    this.completeLabel = 'Get Started',
  });

  /// The list of onboarding steps to display.
  final List<EdenOnboardingStep> steps;

  /// Called when the user taps "Get Started" on the last page or "Skip".
  final VoidCallback onComplete;

  /// Whether to show the "Skip" button in the top-right corner.
  final bool showSkip;

  /// Label for the final page action button. Defaults to "Get Started".
  final String completeLabel;

  @override
  State<EdenOnboardingPage> createState() => _EdenOnboardingPageState();
}

class _EdenOnboardingPageState extends State<EdenOnboardingPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_isLastPage) {
      widget.onComplete();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Top bar with skip ---
            if (widget.showSkip)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: EdenSpacing.space3,
                    right: EdenSpacing.space4,
                  ),
                  child: EdenButton(
                    label: 'Skip',
                    variant: EdenButtonVariant.ghost,
                    size: EdenButtonSize.sm,
                    onPressed: widget.onComplete,
                  ),
                ),
              )
            else
              const SizedBox(height: EdenSpacing.space10),

            // --- Page content ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.steps.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _StepPage(step: widget.steps[index], theme: theme);
                },
              ),
            ),

            // --- Bottom: dots + navigation ---
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EdenSpacing.space6,
                EdenSpacing.space4,
                EdenSpacing.space6,
                EdenSpacing.space8,
              ),
              child: Row(
                children: [
                  // Dot indicators
                  Expanded(
                    child: Row(
                      children: List.generate(widget.steps.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Next / Get Started button
                  EdenButton(
                    label: _isLastPage ? widget.completeLabel : 'Next',
                    onPressed: _nextPage,
                    trailingIcon:
                        _isLastPage ? null : Icons.arrow_forward_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({required this.step, required this.theme});

  final EdenOnboardingStep step;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image or icon
          if (step.image != null)
            step.image!
          else if (step.icon != null)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.icon,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),

          const SizedBox(height: EdenSpacing.space8),

          // Title
          Text(
            step.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          // Description
          if (step.description != null) ...[
            const SizedBox(height: EdenSpacing.space3),
            Text(
              step.description!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Custom content
          if (step.content != null) ...[
            const SizedBox(height: EdenSpacing.space6),
            step.content!,
          ],
        ],
      ),
    );
  }
}
