import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Supported OAuth providers.
enum EdenOAuthProvider { google, github, microsoft, apple }

class _OAuthProviderInfo {
  const _OAuthProviderInfo(this.label, this.icon, this.brandColor);
  final String label;
  final IconData icon;
  final Color brandColor;
}

final Map<EdenOAuthProvider, _OAuthProviderInfo> _providerInfo = {
  EdenOAuthProvider.google: const _OAuthProviderInfo(
    'Google',
    Icons.g_mobiledata,
    Color(0xFF4285F4),
  ),
  EdenOAuthProvider.github: const _OAuthProviderInfo(
    'GitHub',
    Icons.code,
    Color(0xFF24292E),
  ),
  EdenOAuthProvider.microsoft: const _OAuthProviderInfo(
    'Microsoft',
    Icons.window,
    Color(0xFF00A4EF),
  ),
  EdenOAuthProvider.apple: const _OAuthProviderInfo(
    'Apple',
    Icons.apple,
    Color(0xFF000000),
  ),
};

/// Single social login button with provider icon and label.
class EdenOAuthButton extends StatelessWidget {
  const EdenOAuthButton({
    super.key,
    required this.provider,
    this.onPressed,
    this.loading = false,
    this.fullWidth = true,
  });

  final EdenOAuthProvider provider;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final info = _providerInfo[provider]!;
    final brandColor = isDark && provider == EdenOAuthProvider.apple
        ? Colors.white
        : info.brandColor;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? EdenColors.neutral[100] : EdenColors.neutral[900],
          side: BorderSide(
            color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space5,
            vertical: EdenSpacing.space3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: EdenRadii.borderRadiusLg,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
                ),
              ),
            ] else ...[
              Icon(info.icon, size: 20, color: brandColor),
            ],
            const SizedBox(width: EdenSpacing.space3),
            Text('Continue with ${info.label}'),
          ],
        ),
      ),
    );
  }
}

/// Column of OAuth buttons with optional divider.
class EdenOAuthButtonRow extends StatelessWidget {
  const EdenOAuthButtonRow({
    super.key,
    required this.providers,
    required this.onProviderTap,
    this.loadingProvider,
    this.dividerText,
  });

  final List<EdenOAuthProvider> providers;
  final ValueChanged<EdenOAuthProvider> onProviderTap;
  final EdenOAuthProvider? loadingProvider;
  final String? dividerText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < providers.length; i++) ...[
          if (i > 0) const SizedBox(height: EdenSpacing.space3),
          EdenOAuthButton(
            provider: providers[i],
            onPressed: () => onProviderTap(providers[i]),
            loading: loadingProvider == providers[i],
          ),
        ],
        if (dividerText != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space4),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark
                        ? EdenColors.neutral[700]
                        : EdenColors.neutral[300],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
                  child: Text(
                    dividerText!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? EdenColors.neutral[500]
                          : EdenColors.neutral[400],
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark
                        ? EdenColors.neutral[700]
                        : EdenColors.neutral[300],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
