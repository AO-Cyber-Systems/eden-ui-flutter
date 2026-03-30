import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_spinner.dart';

/// A splash/loading page with branding, optional app name, tagline, spinner,
/// and version text.
///
/// The logo fades in with a 300ms animation on first build.
class EdenSplashPage extends StatefulWidget {
  const EdenSplashPage({
    super.key,
    required this.logo,
    this.appName,
    this.tagline,
    this.version,
    this.showSpinner = true,
    this.backgroundColor,
  });

  /// Primary branding widget displayed at center (e.g. an Image or Icon).
  final Widget logo;

  /// App name displayed below the logo.
  final String? appName;

  /// Tagline displayed below the app name.
  final String? tagline;

  /// Version string displayed at the bottom of the screen.
  final String? version;

  /// Whether to show a loading spinner below the branding. Defaults to true.
  final bool showSpinner;

  /// Custom background color. Defaults to the theme surface color.
  final Color? backgroundColor;

  @override
  State<EdenSplashPage> createState() => _EdenSplashPageState();
}

class _EdenSplashPageState extends State<EdenSplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? theme.colorScheme.surface,
      body: Stack(
        children: [
          // --- Centered branding ---
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.logo,
                  if (widget.appName != null) ...[
                    const SizedBox(height: EdenSpacing.space4),
                    Text(
                      widget.appName!,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (widget.tagline != null) ...[
                    const SizedBox(height: EdenSpacing.space2),
                    Text(
                      widget.tagline!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (widget.showSpinner) ...[
                    const SizedBox(height: EdenSpacing.space8),
                    EdenSpinner(
                      size: EdenSpinnerSize.sm,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // --- Version at bottom ---
          if (widget.version != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: EdenSpacing.space8,
              child: Text(
                widget.version!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
