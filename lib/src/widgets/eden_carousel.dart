import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Mirrors the eden_carousel Rails component.
///
/// A horizontal carousel with prev/next buttons and dot indicators.
class EdenCarousel extends StatefulWidget {
  const EdenCarousel({
    super.key,
    required this.children,
    this.height = 200,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.showDots = true,
    this.showArrows = true,
  });

  final List<Widget> children;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool showDots;
  final bool showArrows;

  @override
  State<EdenCarousel> createState() => _EdenCarouselState();
}

class _EdenCarouselState extends State<EdenCarousel> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    if (widget.autoPlay && widget.children.length > 1) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    Future.delayed(widget.autoPlayInterval, () {
      if (!mounted) return;
      final next = (_currentPage + 1) % widget.children.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      _startAutoPlay();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.children.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: widget.children,
              ),
              if (widget.showArrows && count > 1) ...[
                Positioned(
                  left: EdenSpacing.space2,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(
                      icon: Icons.chevron_left,
                      onTap: _currentPage > 0
                          ? () => _controller.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: EdenSpacing.space2,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(
                      icon: Icons.chevron_right,
                      onTap: _currentPage < count - 1
                          ? () => _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.showDots && count > 1) ...[
          const SizedBox(height: EdenSpacing.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (i) {
              final isActive = i == _currentPage;
              return GestureDetector(
                onTap: () => _controller.animateToPage(i,
                    duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: EdenRadii.borderRadiusFull,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white : Colors.white38,
          size: 24,
        ),
      ),
    );
  }
}
